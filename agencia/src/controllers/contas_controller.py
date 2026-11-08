from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException, Request
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field

import config
from controllers.transferencias_controller import TransferenciaBody, executar_transferencia
from repositories.conta_repository import SaldoInsuficiente
from auth.security import exigir_dono_ou_admin, exigir_usuario_ou_admin, hash_senha
from services.relogio_vetorial import comparar_vetores

router = APIRouter()


class CriarContaBody(BaseModel):
    id: int
    nomeAluno: str
    senha: str
    saldoInicial: float = Field(default=0, ge=0)


class ValorBody(BaseModel):
    valor: float = Field(gt=0)


class SincronizarBody(BaseModel):
    tipo: str
    valor: float = Field(gt=0)
    vetorConhecido: list[int] = Field(min_length=config.NUMERO_AGENCIAS, max_length=config.NUMERO_AGENCIAS)
    idDestino: int | None = None
    idempotencyKey: str | None = None


def conta_publica(conta: dict) -> dict:
    return {"id": conta["id"], "nomeAluno": conta["nomeAluno"], "saldo": conta["saldo"]}


@router.post("/contas", status_code=201)
def criar_conta(body: CriarContaBody, request: Request):
    contas = request.app.state.contas
    relogio = request.app.state.relogio
    registro = request.app.state.registro
    id_agencia = request.app.state.id_agencia

    if config.agencia_responsavel(body.id) != id_agencia:
        raise HTTPException(status_code=400, detail=f"Conta {body.id} não pertence a esta agência.")
    if contas.existe(body.id):
        raise HTTPException(status_code=409, detail="Conta já existe.")

    ts = relogio.evento_local()
    conta = contas.criar(body.id, body.nomeAluno, hash_senha(body.senha), body.saldoInicial)
    registro.registrar("CRIAR_CONTA", ts, {
        "id": body.id, "nomeAluno": body.nomeAluno, "saldoInicial": body.saldoInicial,
    })

    return conta_publica(conta)


@router.get("/contas/{id}")
def consultar_saldo(id: int, request: Request, token: dict = Depends(exigir_usuario_ou_admin)):
    exigir_dono_ou_admin(token, id)
    conta = request.app.state.contas.obter(id)
    if conta is None:
        raise HTTPException(status_code=404, detail="Conta não encontrada nesta agência.")
    return {**conta_publica(conta), "vetorAtual": request.app.state.relogio.atual()}


@router.post("/contas/{id}/depositar")
def depositar(id: int, body: ValorBody, request: Request, token: dict = Depends(exigir_usuario_ou_admin)):
    exigir_dono_ou_admin(token, id)
    contas = request.app.state.contas
    relogio = request.app.state.relogio
    registro = request.app.state.registro

    if not contas.existe(id):
        raise HTTPException(status_code=404, detail="Conta não encontrada nesta agência.")

    ts = relogio.evento_local()
    conta = contas.creditar(id, body.valor)
    registro.registrar("DEPOSITO", ts, {"id": id, "valor": body.valor, "novoSaldo": conta["saldo"]})

    return conta_publica(conta)


@router.post("/contas/{id}/sacar")
def sacar(id: int, body: ValorBody, request: Request, token: dict = Depends(exigir_usuario_ou_admin)):
    exigir_dono_ou_admin(token, id)
    contas = request.app.state.contas
    relogio = request.app.state.relogio
    registro = request.app.state.registro

    if not contas.existe(id):
        raise HTTPException(status_code=404, detail="Conta não encontrada nesta agência.")

    try:
        conta = contas.debitar(id, body.valor)
    except SaldoInsuficiente:
        raise HTTPException(status_code=400, detail="Saldo insuficiente.")
    ts = relogio.evento_local()
    registro.registrar("SAQUE", ts, {"id": id, "valor": body.valor, "novoSaldo": conta["saldo"]})

    return conta_publica(conta)


@router.post("/contas/{id}/sincronizar")
def sincronizar_operacao_pendente(
    id: int, body: SincronizarBody, request: Request, token: dict = Depends(exigir_usuario_ou_admin)
):
    exigir_dono_ou_admin(token, id)
    contas = request.app.state.contas
    relogio = request.app.state.relogio
    registro = request.app.state.registro
    idempotencia = request.app.state.idempotencia

    if not contas.existe(id):
        raise HTTPException(status_code=404, detail="Conta não encontrada nesta agência.")

    # Se a resposta de uma sincronizacao se perder na rede, o reenvio devolve o mesmo
    # resultado em vez de virar um conflito falso (o vetor ja avancou com a propria operacao).
    if body.idempotencyKey is not None:
        estado, resultado_anterior = idempotencia.reservar(body.idempotencyKey)
        if estado == "concluida":
            return resultado_anterior
        if estado == "em_andamento":
            raise HTTPException(status_code=409, detail="Esta operação já está sendo sincronizada.")

    try:
        # Comparar e aplicar precisa ser atomico: um evento entre os dois passos
        # passaria despercebido pela deteccao de conflito.
        with relogio.exclusivo():
            vetor_atual = relogio.atual()
            if comparar_vetores(body.vetorConhecido, vetor_atual) != "IGUAIS":
                if body.idempotencyKey is not None:
                    idempotencia.liberar(body.idempotencyKey)
                return JSONResponse(
                    status_code=409,
                    media_type="application/json; charset=utf-8",
                    content={
                        "erro": "Conflito detectado: o estado da conta mudou desde a última sincronização do app.",
                        "vetorConhecido": body.vetorConhecido,
                        "vetorAtual": vetor_atual,
                        "contaAtual": conta_publica(contas.obter(id)),
                    },
                )

            _aplicar_operacao_pendente(id, body, request)
            ts = relogio.evento_local()
            registro.registrar("SINCRONIZACAO_OFFLINE", ts, {"id": id, "tipo": body.tipo, "valor": body.valor})
            resultado = {**conta_publica(contas.obter(id)), "vetorAtual": ts}
    except BaseException:
        if body.idempotencyKey is not None:
            idempotencia.liberar(body.idempotencyKey)
        raise

    if body.idempotencyKey is not None:
        idempotencia.registrar(body.idempotencyKey, resultado)
    return resultado


def _aplicar_operacao_pendente(id: int, body: SincronizarBody, request: Request) -> None:
    contas = request.app.state.contas

    if body.tipo == "DEPOSITO":
        contas.creditar(id, body.valor)
    elif body.tipo == "SAQUE":
        try:
            contas.debitar(id, body.valor)
        except SaldoInsuficiente:
            raise HTTPException(status_code=400, detail="Saldo insuficiente.")
    elif body.tipo == "TRANSFERENCIA":
        if body.idDestino is None:
            raise HTTPException(status_code=400, detail="Transferência pendente sem conta de destino.")
        executar_transferencia(
            TransferenciaBody(
                idOrigem=id, idDestino=body.idDestino, valor=body.valor, idempotencyKey=body.idempotencyKey or str(uuid4())
            ),
            request,
        )
    else:
        raise HTTPException(status_code=400, detail="Tipo de operação pendente não suportado.")
