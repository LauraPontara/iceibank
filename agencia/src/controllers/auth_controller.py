import hmac

from fastapi import APIRouter, HTTPException, Request
from pydantic import BaseModel

import config
from auth.security import gerar_token, gerar_token_admin, verificar_senha

router = APIRouter()


class LoginBody(BaseModel):
    id: int
    senha: str


class AdminLoginBody(BaseModel):
    usuario: str
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


@router.post("/auth/admin/login")
def login_admin(body: AdminLoginBody):
    if not config.ADMIN_USUARIO or not config.ADMIN_SENHA:
        raise HTTPException(status_code=503, detail="Login de administrador não configurado nesta agência.")

    usuario_ok = hmac.compare_digest(body.usuario.encode(), config.ADMIN_USUARIO.encode())
    senha_ok = hmac.compare_digest(body.senha.encode(), config.ADMIN_SENHA.encode())
    if not (usuario_ok and senha_ok):
        raise HTTPException(status_code=401, detail="Credenciais inválidas.")

    return {"accessToken": gerar_token_admin(), "tokenType": "bearer", "expiraEmMinutos": config.JWT_EXPIRA_MINUTOS}
