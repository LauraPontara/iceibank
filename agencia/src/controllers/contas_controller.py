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

TIPOS_SINCRONIZAVEIS = ("DEPOSITO", "SAQUE", "TRANSFERENCIA")


class CriarContaBody(BaseModel):
    id: int
    nomeAluno: str
    senha: str
    saldoInicial: float = Field(default=0, ge=0)


class ValorBody(BaseModel):
    valor: float = Field(gt=0)
    idempotencyKey: str | None = None


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
    # Saldo e vetor lidos juntos: o app usa esse par para detectar conflitos depois
    with request.app.state.relogio.exclusivo():
        conta = request.app.state.contas.obter(id)
        if conta is None:
            raise HTTPException(status_code=404, detail="Conta não encontrada nesta agência.")
        return {**conta_publica(conta), "vetorAtual": request.app.state.relogio.atual()}


def _com_idempotencia(request: Request, chave: str | None, operacao):
    """O app reenvia pela sincronizacao o que nao teve resposta. Com a mesma chave,
    uma operacao ja aplicada devolve o resultado em vez de ser aplicada de novo."""
    if chave is None:
        return operacao()

    idempotencia = request.app.state.idempotencia
    estado, resultado_anterior = idempotencia.reservar(chave)
    if estado == "concluida":
        return resultado_anterior
    if estado == "em_andamento":
        raise HTTPException(status_code=423, detail="Esta operação já está em andamento.")

    try:
        resultado = operacao()
    except BaseException:
        idempotencia.liberar(chave)
        raise
    idempotencia.registrar(chave, resultado)
    return resultado


@router.post("/contas/{id}/depositar")
def depositar(id: int, body: ValorBody, request: Request, token: dict = Depends(exigir_usuario_ou_admin)):
    exigir_dono_ou_admin(token, id)
    return _com_idempotencia(request, body.idempotencyKey, lambda: _aplicar_deposito(id, body, request))


def _aplicar_deposito(id: int, body: ValorBody, request: Request) -> dict:
    contas = request.app.state.contas
    relogio = request.app.state.relogio
    registro = request.app.state.registro

    if not contas.existe(id):
        raise HTTPException(status_code=404, detail="Conta não encontrada nesta agência.")

    with relogio.exclusivo():
        ts = relogio.evento_local()
        conta = contas.creditar(id, body.valor)
    registro.registrar("DEPOSITO", ts, {"id": id, "valor": body.valor, "novoSaldo": conta["saldo"]})

    return conta_publica(conta)


@router.post("/contas/{id}/sacar")
def sacar(id: int, body: ValorBody, request: Request, token: dict = Depends(exigir_usuario_ou_admin)):
    exigir_dono_ou_admin(token, id)
    return _com_idempotencia(request, body.idempotencyKey, lambda: _aplicar_saque(id, body, request))


def _aplicar_saque(id: int, body: ValorBody, request: Request) -> dict:
    contas = request.app.state.contas
    relogio = request.app.state.relogio
    registro = request.app.state.registro

    if not contas.existe(id):
        raise HTTPException(status_code=404, detail="Conta não encontrada nesta agência.")

    with relogio.exclusivo():
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
    if body.tipo not in TIPOS_SINCRONIZAVEIS:
        raise HTTPException(status_code=400, detail="Tipo de operação pendente não suportado.")
    if body.tipo == "TRANSFERENCIA" and body.idDestino is None:
        raise HTTPException(status_code=400, detail="Transferência pendente sem conta de destino.")

    # Se a resposta de uma sincronizacao se perder na rede, o reenvio devolve o mesmo
    # resultado em vez de virar um conflito falso (o vetor ja avancou com a propria operacao).
    if body.idempotencyKey is not None:
        estado, resultado_anterior = idempotencia.reservar(body.idempotencyKey)
        if estado == "concluida":
            return resultado_anterior
        if estado == "em_andamento":
            # 423 e nao 409: na sincronizacao, 409 significa sempre conflito de vetor
            raise HTTPException(status_code=423, detail="Esta operação já está sendo sincronizada.")

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

            if body.tipo == "DEPOSITO":
                contas.creditar(id, body.valor)
            elif body.tipo == "SAQUE":
                try:
                    contas.debitar(id, body.valor)
                except SaldoInsuficiente:
                    raise HTTPException(status_code=400, detail="Saldo insuficiente.")
            ts = relogio.evento_local()
            registro.registrar("SINCRONIZACAO_OFFLINE", ts, {"id": id, "tipo": body.tipo, "valor": body.valor})
            resultado = {**conta_publica(contas.obter(id)), "vetorAtual": ts}

        # A transferencia pode publicar no broker, entao roda fora do lock: uma rede
        # lenta nao pode segurar as mensagens do Bully, que tem timeout de 1s.
        if body.tipo == "TRANSFERENCIA":
            executar_transferencia(
                TransferenciaBody(
                    idOrigem=id, idDestino=body.idDestino, valor=body.valor, idempotencyKey=body.idempotencyKey or str(uuid4())
                ),
                request,
            )
            with relogio.exclusivo():
                resultado = {**conta_publica(contas.obter(id)), "vetorAtual": relogio.atual()}
    except BaseException:
        if body.idempotencyKey is not None:
            idempotencia.liberar(body.idempotencyKey)
        raise

    if body.idempotencyKey is not None:
        idempotencia.registrar(body.idempotencyKey, resultado)
    return resultado
