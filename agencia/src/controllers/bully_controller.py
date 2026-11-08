from fastapi import APIRouter, Request
from pydantic import BaseModel, Field

import config

router = APIRouter()


class EleicaoBody(BaseModel):
    origemId: int = Field(ge=0, lt=config.NUMERO_AGENCIAS)
    vetorEnvio: list[int] = Field(min_length=config.NUMERO_AGENCIAS, max_length=config.NUMERO_AGENCIAS)


class CoordenadorBody(BaseModel):
    liderId: int = Field(ge=0, lt=config.NUMERO_AGENCIAS)
    vetorEnvio: list[int] = Field(min_length=config.NUMERO_AGENCIAS, max_length=config.NUMERO_AGENCIAS)


@router.post("/bully/eleicao")
def receber_eleicao(body: EleicaoBody, request: Request):
    request.app.state.bully.receber_eleicao(body.origemId, body.vetorEnvio)
    return {"ok": True}


@router.post("/bully/coordenador")
def receber_coordenador(body: CoordenadorBody, request: Request):
    request.app.state.bully.receber_coordenador(body.liderId, body.vetorEnvio)
    return {"ok": True}


@router.get("/bully/lider")
def obter_lider(request: Request):
    return {"idAgencia": request.app.state.id_agencia, "liderAtual": request.app.state.bully.obter_lider_atual()}
