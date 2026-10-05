from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel, Field

import config
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
    contas = request.app.state.contas
    relogio = request.app.state.relogio
    registro = request.app.state.registro
    id_agencia = request.app.state.id_agencia
    idempotencia = request.app.state.idempotencia

    # Idempotencia: se essa chave ja foi usada numa transferencia CONCLUIDA
    # com sucesso, devolve o mesmo resultado sem debitar de novo. Isso protege
    # contra o caso classico de retry de rede (cliente reenvia a mesma
    # requisicao porque a resposta se perdeu, achando que a primeira falhou).
    # Chaves de tentativas que falharam (404/400/502) nao ficam gravadas aqui,
    # para que o cliente possa tentar de novo com a mesma chave.
    resultado_anterior = idempotencia.obter(body.idempotencyKey)
    if resultado_anterior is not None:
        return resultado_anterior

    conta_origem = contas.obter(body.idOrigem)
    if conta_origem is None:
        raise HTTPException(status_code=404, detail="Conta de origem não encontrada nesta agência.")
    if conta_origem["saldo"] < body.valor:
        raise HTTPException(status_code=400, detail="Saldo insuficiente.")

    agencia_destino = config.agencia_responsavel(body.idDestino)

    # O debito e sempre local, pois esta agencia e a dona da conta de origem
    ts_debito = relogio.evento_local()
    contas.debitar(body.idOrigem, body.valor)
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
        resultado = {"mensagem": "Transferência concluída (mesma agência)."}
        idempotencia.registrar(body.idempotencyKey, resultado)
        return resultado

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

    resultado = {"mensagem": "Transferência publicada para a agência de destino (entrega assíncrona)."}
    idempotencia.registrar(body.idempotencyKey, resultado)
    return resultado
