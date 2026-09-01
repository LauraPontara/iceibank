import hashlib
import os
from datetime import datetime, timedelta, timezone

import jwt
from fastapi import Header, HTTPException

import config


def hash_senha(senha: str) -> str:
    sal = os.urandom(16)
    derivado = hashlib.pbkdf2_hmac("sha256", senha.encode("utf-8"), sal, 100_000)
    return sal.hex() + ":" + derivado.hex()


def verificar_senha(senha: str, senha_hash: str) -> bool:
    sal_hex, derivado_hex = senha_hash.split(":")
    sal = bytes.fromhex(sal_hex)
    derivado_calculado = hashlib.pbkdf2_hmac("sha256", senha.encode("utf-8"), sal, 100_000)
    return derivado_calculado.hex() == derivado_hex


def gerar_token(id_conta: int, id_agencia: int) -> str:
    agora = datetime.now(timezone.utc)
    payload = {
        "sub": str(id_conta),
        "agencia": id_agencia,
        "tipo": "usuario",
        "iat": agora,
        "exp": agora + timedelta(minutes=config.JWT_EXPIRA_MINUTOS),
    }
    return jwt.encode(payload, config.JWT_SECRET, algorithm=config.JWT_ALGORITMO)


def gerar_token_servico(id_agencia_origem: int) -> str:
    agora = datetime.now(timezone.utc)
    payload = {
        "sub": f"agencia:{id_agencia_origem}",
        "agenciaOrigem": id_agencia_origem,
        "tipo": "inter-agencia",
        "iat": agora,
        "exp": agora + timedelta(minutes=5),
    }
    return jwt.encode(payload, config.JWT_SECRET, algorithm=config.JWT_ALGORITMO)


def _decodificar(authorization: str | None) -> dict:
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Token ausente. Use o cabeçalho Authorization: Bearer <token>.")
    token = authorization[len("Bearer "):]
    try:
        return jwt.decode(token, config.JWT_SECRET, algorithms=[config.JWT_ALGORITMO])
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token expirado.")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Token inválido.")


def exigir_token(authorization: str | None = Header(default=None)) -> dict:
    payload = _decodificar(authorization)
    if payload.get("tipo") != "usuario":
        raise HTTPException(status_code=401, detail="Token não é de um usuário autenticado.")
    return payload


def exigir_token_servico(authorization: str | None = Header(default=None)) -> dict:
    payload = _decodificar(authorization)
    if payload.get("tipo") != "inter-agencia":
        raise HTTPException(status_code=401, detail="Token não é um token de serviço entre agências.")
    return payload
