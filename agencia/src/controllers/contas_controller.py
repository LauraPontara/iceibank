from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel

import config
from auth.security import exigir_usuario_ou_admin, hash_senha

router = APIRouter()


class CriarContaBody(BaseModel):
    id: int
    nomeAluno: str
    senha: str
    saldoInicial: float = 0


class ValorBody(BaseModel):
    valor: float


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
    if body.id in contas:
        raise HTTPException(status_code=409, detail="Conta já existe.")

    ts = relogio.evento_local()
    contas[body.id] = {
        "id": body.id,
        "nomeAluno": body.nomeAluno,
        "senhaHash": hash_senha(body.senha),
        "saldo": body.saldoInicial,
    }
    registro.registrar("CRIAR_CONTA", ts, {
        "id": body.id, "nomeAluno": body.nomeAluno, "saldoInicial": body.saldoInicial,
    })

    return conta_publica(contas[body.id])


@router.get("/contas/{id}")
def consultar_saldo(id: int, request: Request, _token: dict = Depends(exigir_usuario_ou_admin)):
    contas = request.app.state.contas
    conta = contas.get(id)
    if conta is None:
        raise HTTPException(status_code=404, detail="Conta não encontrada nesta agência.")
    return conta_publica(conta)


@router.post("/contas/{id}/depositar")
def depositar(id: int, body: ValorBody, request: Request, _token: dict = Depends(exigir_usuario_ou_admin)):
    contas = request.app.state.contas
    relogio = request.app.state.relogio
    registro = request.app.state.registro

    conta = contas.get(id)
    if conta is None:
        raise HTTPException(status_code=404, detail="Conta não encontrada nesta agência.")

    ts = relogio.evento_local()
    conta["saldo"] += body.valor
    registro.registrar("DEPOSITO", ts, {"id": id, "valor": body.valor, "novoSaldo": conta["saldo"]})

    return conta_publica(conta)


@router.post("/contas/{id}/sacar")
def sacar(id: int, body: ValorBody, request: Request, _token: dict = Depends(exigir_usuario_ou_admin)):
    contas = request.app.state.contas
    relogio = request.app.state.relogio
    registro = request.app.state.registro

    conta = contas.get(id)
    if conta is None:
        raise HTTPException(status_code=404, detail="Conta não encontrada nesta agência.")
    if conta["saldo"] < body.valor:
        raise HTTPException(status_code=400, detail="Saldo insuficiente.")

    ts = relogio.evento_local()
    conta["saldo"] -= body.valor
    registro.registrar("SAQUE", ts, {"id": id, "valor": body.valor, "novoSaldo": conta["saldo"]})

    return conta_publica(conta)
