from fastapi import APIRouter, Depends, Request

from auth.security import exigir_admin

router = APIRouter(prefix="/admin")


@router.get("/contas")
def listar_contas(request: Request, _token: dict = Depends(exigir_admin)):
    return [
        {"id": c["id"], "nomeAluno": c["nomeAluno"], "saldo": c["saldo"]}
        for c in request.app.state.contas.listar()
    ]


@router.get("/status")
def status_agencia(request: Request, _token: dict = Depends(exigir_admin)):
    return {
        "idAgencia": request.app.state.id_agencia,
        "relogioLamport": request.app.state.relogio.contador,
        "totalContas": request.app.state.contas.contar(),
    }
