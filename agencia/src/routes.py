from fastapi import APIRouter

from controllers import auth_controller, contas_controller, transferencias_controller

router = APIRouter()
router.include_router(auth_controller.router)
router.include_router(contas_controller.router)
router.include_router(transferencias_controller.router)
