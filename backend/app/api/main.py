from fastapi import APIRouter

from app.api.routes import (
    items,
    login,
    pipeline_route,
    private,
    rag_route,
    users,
    utils,
)
from app.core.config import settings

api_router = APIRouter()
api_router.include_router(login.router)
api_router.include_router(users.router)
api_router.include_router(utils.router)
api_router.include_router(items.router)
api_router.include_router(pipeline_route.router)
api_router.include_router(rag_route.router)


if settings.ENVIRONMENT == "local":
    api_router.include_router(private.router)
