from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel, Field

import config
from repositories.conta_repository import SaldoInsuficiente
from auth.security import exigir_dono_ou_admin, exigir_usuario_ou_admin
from services.mensageria import publicar_credito

router = APIRouter()


class TransferenciaBody(BaseModel):
    idOrigem: int
    idDestino: int
    valor: float = Field(gt=0)
    idempotencyKey: str


@router.post("/transferencias")
def transferir(body: TransferenciaBody, request: Request, token: dict = Depends(exigir_usuario_ou_admin)):
    exigir_dono_ou_admin(token, body.idOrigem)
    idempotencia = request.app.state.idempotencia

    # Idempotencia: uma chave ja concluida devolve o mesmo resultado sem debitar de novo
    # (protege retries de rede). A reserva e atomica, entao duas requisicoes simultaneas
    # com a mesma chave nao debitam duas vezes. Tentativas que falham liberam a chave.
    estado, resultado_anterior = idempotencia.reservar(body.idempotencyKey)
    if estado == "concluida":
        return resultado_anterior
    if estado == "em_andamento":
        raise HTTPException(status_code=409, detail="Já existe uma transferência em andamento com esta chave.")

    try:
        resultado = _executar_transferencia(body, request)
    except BaseException:
        idempotencia.liberar(body.idempotencyKey)
        raise
    idempotencia.registrar(body.idempotencyKey, resultado)
    return resultado


def _executar_transferencia(body: TransferenciaBody, request: Request) -> dict:
    contas = request.app.state.contas
    relogio = request.app.state.relogio
    registro = request.app.state.registro
    id_agencia = request.app.state.id_agencia

    if not contas.existe(body.idOrigem):
        raise HTTPException(status_code=404, detail="Conta de origem não encontrada nesta agência.")

    agencia_destino = config.agencia_responsavel(body.idDestino)

    # O debito e sempre local, pois esta agencia e a dona da conta de origem
    try:
        contas.debitar(body.idOrigem, body.valor)
    except SaldoInsuficiente:
        raise HTTPException(status_code=400, detail="Saldo insuficiente.")
    ts_debito = relogio.evento_local()
    registro.registrar("TRANSFERENCIA_DEBITO", ts_debito, {
        "idOrigem": body.idOrigem, "idDestino": body.idDestino, "valor": body.valor,
        "idempotencyKey": body.idempotencyKey,
    })

    if agencia_destino == id_agencia:
        if not contas.existe(body.idDestino):
            contas.creditar(body.idOrigem, body.valor)
            raise HTTPException(status_code=404, detail="Conta de destino não encontrada.")
        ts_credito = relogio.evento_local()
        contas.creditar(body.idDestino, body.valor)
        registro.registrar("TRANSFERENCIA_CREDITO", ts_credito, {
            "idOrigem": body.idOrigem, "idDestino": body.idDestino, "valor": body.valor,
        })
        return {"mensagem": "Transferência concluída (mesma agência)."}

    # Caso entre agencias: em vez de chamar a outra agencia por REST, publica um
    # evento no RabbitMQ. A agencia de destino consome quando estiver disponivel;
    # a mensagem fica retida na fila duravel enquanto ela estiver fora do ar.
    ts_envio = relogio.ao_enviar()
    registro.registrar("TRANSFERENCIA_ENVIO_REMOTO", ts_envio, {
        "idOrigem": body.idOrigem, "idDestino": body.idDestino, "valor": body.valor,
        "agenciaDestino": agencia_destino,
    })

    try:
        publicar_credito(agencia_destino, {
            "idConta": body.idDestino,
            "valor": body.valor,
            "vetorEnvio": ts_envio,
            "origemAgencia": id_agencia,
            "idTransferencia": body.idempotencyKey,
        })
    except Exception as erro:
        # Sem broker nao ha como entregar o credito: estorna o debito para nao perder dinheiro.
        contas.creditar(body.idOrigem, body.valor)
        registro.registrar("TRANSFERENCIA_FALHOU", relogio.evento_local(), {
            "idOrigem": body.idOrigem, "idDestino": body.idDestino, "valor": body.valor, "erro": str(erro),
        })
        raise HTTPException(status_code=502, detail="Não foi possível publicar a transferência no broker. Débito estornado.")

    return {"mensagem": "Transferência publicada para a agência de destino (entrega assíncrona)."}
