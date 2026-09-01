import os

from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse

import config
from routes import router
from services.event_log import RegistroEventos
from services.lamport_clock import RelogioLamport

id_agencia = int(os.environ.get("AGENCIA_ID", "0"))
agencia_config = next((a for a in config.AGENCIAS if a["id"] == id_agencia), None)

if agencia_config is None:
    raise SystemExit(f"Agência {id_agencia} não configurada em config.py")


class RespostaJsonUtf8(JSONResponse):
    # O Invoke-RestMethod do Windows PowerShell 5.1 le a resposta como
    # Latin-1 quando o Content-Type nao declara charset explicitamente,
    # corrompendo acentos. Declarar utf-8 aqui corrige isso.
    media_type = "application/json; charset=utf-8"


app = FastAPI(title=f"ICEIBank - Agência {id_agencia}", default_response_class=RespostaJsonUtf8)


@app.exception_handler(HTTPException)
async def tratar_http_exception(request, exc: HTTPException):
    return RespostaJsonUtf8(status_code=exc.status_code, content={"detail": exc.detail}, headers=exc.headers)

app.state.id_agencia = id_agencia
app.state.relogio = RelogioLamport()
app.state.registro = RegistroEventos(f"agencia-{id_agencia}")
app.state.contas = {}

app.include_router(router)

if __name__ == "__main__":
    import uvicorn

    porta = int(agencia_config["url"].rsplit(":", 1)[1])
    print(f"[Agência {id_agencia}] ouvindo na porta {porta}")
    uvicorn.run(app, host="0.0.0.0", port=porta)
