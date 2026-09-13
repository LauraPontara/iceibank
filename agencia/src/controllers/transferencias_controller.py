import requests
from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel

import config
from auth.security import exigir_token, exigir_token_servico, gerar_token_servico

router = APIRouter()


class TransferenciaBody(BaseModel):
    idOrigem: int
    idDestino: int
    valor: float
    idempotencyKey: str


class CreditoRemotoBody(BaseModel):
    valor: float
    timestampLamport: int
    origemAgencia: int


@router.post("/transferencias")
def transferir(body: TransferenciaBody, request: Request, _token: dict = Depends(exigir_token)):
    contas = request.app.state.contas
    relogio = request.app.state.relogio
    registro = request.app.state.registro
    id_agencia = request.app.state.id_agencia
    idempotencia = request.app.state.idempotencia

    # Idempotencia: se essa chave ja foi usada numa transferencia CONCLUIDA
    # com sucesso, devolve o mesmo resultado sem debitar de novo. Isso protege
    # contra o caso classico de retry de rede (cliente reenvia a mesma
    # requisicao porque a resposta se perdeu, achando que a primeira falhou).
    # Chaves de tentativas que falharam (404/400/502) nao ficam gravadas aqui
    # de proposito - a limitacao conhecida da Parte D (debito sem rollback em
    # falha remota) continua sendo um problema em aberto, e nao e o que essa
    # funcionalidade se propoe a resolver (isso e assunto do Sprint 4).
    if body.idempotencyKey in idempotencia:
        return idempotencia[body.idempotencyKey]

    conta_origem = contas.get(body.idOrigem)
    if conta_origem is None:
        raise HTTPException(status_code=404, detail="Conta de origem não encontrada nesta agência.")
    if conta_origem["saldo"] < body.valor:
        raise HTTPException(status_code=400, detail="Saldo insuficiente.")

    agencia_destino = config.agencia_responsavel(body.idDestino)

    # O debito e sempre local, pois esta agencia e a dona da conta de origem
    ts_debito = relogio.evento_local()
    conta_origem["saldo"] -= body.valor
    registro.registrar("TRANSFERENCIA_DEBITO", ts_debito, {
        "idOrigem": body.idOrigem, "idDestino": body.idDestino, "valor": body.valor,
        "idempotencyKey": body.idempotencyKey,
    })

    if agencia_destino == id_agencia:
        conta_destino = contas.get(body.idDestino)
        if conta_destino is None:
            conta_origem["saldo"] += body.valor
            raise HTTPException(status_code=404, detail="Conta de destino não encontrada.")
        ts_credito = relogio.evento_local()
        conta_destino["saldo"] += body.valor
        registro.registrar("TRANSFERENCIA_CREDITO", ts_credito, {
            "idOrigem": body.idOrigem, "idDestino": body.idDestino, "valor": body.valor,
        })
        resultado = {"mensagem": "Transferência concluída (mesma agência)."}
        idempotencia[body.idempotencyKey] = resultado
        return resultado

    # Caso entre agencias: chama a agencia de destino diretamente via REST
    ts_envio = relogio.ao_enviar()
    registro.registrar("TRANSFERENCIA_ENVIO_REMOTO", ts_envio, {
        "idOrigem": body.idOrigem, "idDestino": body.idDestino, "valor": body.valor,
        "agenciaDestino": agencia_destino,
    })
    url_destino = next(a["url"] for a in config.AGENCIAS if a["id"] == agencia_destino)

    token_servico = gerar_token_servico(id_agencia)

    try:
        resposta = requests.post(
            f"{url_destino}/contas/{body.idDestino}/creditar-remoto",
            json={"valor": body.valor, "timestampLamport": ts_envio, "origemAgencia": id_agencia},
            headers={"Authorization": f"Bearer {token_servico}"},
            timeout=5,
        )
        resposta.raise_for_status()
        resultado = {"mensagem": "Transferência concluída (entre agências)."}
        idempotencia[body.idempotencyKey] = resultado
        return resultado
    except requests.RequestException as erro:
        # LIMITACAO CONHECIDA: se esta chamada falhar, o debito ja aplicado acima
        # NAO e revertido - o dinheiro "desaparece" temporariamente. Resolver isso
        # de forma correta e o assunto do Sprint 4, com uma transacao distribuida
        # de verdade (2PC/Saga). Por enquanto, so registramos a inconsistencia no log.
        registro.registrar("TRANSFERENCIA_FALHOU", relogio.evento_local(), {
            "idOrigem": body.idOrigem, "idDestino": body.idDestino, "valor": body.valor, "erro": str(erro),
        })
        raise HTTPException(
            status_code=502,
            detail="Falha ao contatar agência de destino. Débito já aplicado - inconsistência conhecida (ver Sprint 4).",
        )


@router.post("/contas/{id}/creditar-remoto")
def creditar_remoto(id: int, body: CreditoRemotoBody, request: Request, _token: dict = Depends(exigir_token_servico)):
    contas = request.app.state.contas
    relogio = request.app.state.relogio
    registro = request.app.state.registro

    # Ao RECEBER uma mensagem de outra agencia, o relogio de Lamport e
    # atualizado com base no timestamp recebido - e a regra 3 do algoritmo.
    ts = relogio.ao_receber(body.timestampLamport)

    conta = contas.get(id)
    if conta is None:
        raise HTTPException(status_code=404, detail="Conta não encontrada nesta agência.")

    conta["saldo"] += body.valor
    registro.registrar("TRANSFERENCIA_CREDITO_REMOTO", ts, {
        "idConta": id, "valor": body.valor, "origemAgencia": body.origemAgencia,
    })

    return {"mensagem": "Crédito remoto aplicado.", "saldoAtual": conta["saldo"]}
