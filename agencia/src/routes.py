from fastapi import APIRouter

from controllers import contas_controller

router = APIRouter()
router.include_router(contas_controller.router)
