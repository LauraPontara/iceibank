from fastapi import APIRouter, HTTPException, Request
from pydantic import BaseModel

import config
from auth.security import gerar_token, verificar_senha

router = APIRouter()


class LoginBody(BaseModel):
    id: int
    senha: str


@router.post("/auth/login")
def login(body: LoginBody, request: Request):
    contas = request.app.state.contas
    id_agencia = request.app.state.id_agencia

    conta = contas.get(body.id)
    if conta is None or not verificar_senha(body.senha, conta["senhaHash"]):
        raise HTTPException(status_code=401, detail="Credenciais inválidas.")

    token = gerar_token(body.id, id_agencia)
    return {"accessToken": token, "tokenType": "bearer", "expiraEmMinutos": config.JWT_EXPIRA_MINUTOS}
