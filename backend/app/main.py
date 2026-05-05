import logging

import sentry_sdk
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.routing import APIRoute
from starlette.middleware.cors import CORSMiddleware

from app.api.main import api_router
from app.core.config import settings
from app.exceptions.pipeline import (
    ChunkingError,
    CleaningError,
    EmbeddingError,
    PipelineDataError,
    S3DownloadError,
    S3UploadError,
    ScraperError,
)
from app.exceptions.rag import RAGError, RAGValidationError

logger = logging.getLogger(__name__)


def custom_generate_unique_id(route: APIRoute) -> str:
    return f"{route.tags[0]}-{route.name}"


if settings.SENTRY_DSN and settings.ENVIRONMENT != "local":
    sentry_sdk.init(dsn=str(settings.SENTRY_DSN), enable_tracing=True)

app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    generate_unique_id_function=custom_generate_unique_id,
)

# Set all CORS enabled origins
if settings.all_cors_origins:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.all_cors_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )


# ─── Pipeline exception handlers ──────────────────────────────────────────


@app.exception_handler(PipelineDataError)
async def pipeline_data_error_handler(
    request: Request, exc: PipelineDataError
) -> JSONResponse:
    logger.warning("Pipeline data error on %s: %s", request.url.path, exc)
    return JSONResponse(status_code=422, content={"detail": str(exc)})


@app.exception_handler(S3DownloadError)
async def s3_download_error_handler(
    request: Request, exc: S3DownloadError
) -> JSONResponse:
    logger.error("S3 download error on %s: %s", request.url.path, exc)
    return JSONResponse(status_code=404, content={"detail": str(exc)})


@app.exception_handler(ScraperError)
async def scraper_error_handler(request: Request, exc: ScraperError) -> JSONResponse:
    logger.error("Scraper error on %s: %s", request.url.path, exc)
    return JSONResponse(status_code=500, content={"detail": str(exc)})


@app.exception_handler(S3UploadError)
async def s3_upload_error_handler(request: Request, exc: S3UploadError) -> JSONResponse:
    logger.error("S3 upload error on %s: %s", request.url.path, exc)
    return JSONResponse(status_code=500, content={"detail": str(exc)})


@app.exception_handler(CleaningError)
async def cleaning_error_handler(request: Request, exc: CleaningError) -> JSONResponse:
    logger.error("Cleaning error on %s: %s", request.url.path, exc)
    return JSONResponse(status_code=500, content={"detail": str(exc)})


@app.exception_handler(ChunkingError)
async def chunking_error_handler(request: Request, exc: ChunkingError) -> JSONResponse:
    logger.error("Chunking error on %s: %s", request.url.path, exc)
    return JSONResponse(status_code=500, content={"detail": str(exc)})


@app.exception_handler(EmbeddingError)
async def embedding_error_handler(
    request: Request, exc: EmbeddingError
) -> JSONResponse:
    logger.error("Embedding error on %s: %s", request.url.path, exc)
    return JSONResponse(status_code=500, content={"detail": str(exc)})


# ─── RAG exception handlers ───────────────────────────────────────────────


@app.exception_handler(RAGValidationError)
async def rag_validation_error_handler(
    request: Request, exc: RAGValidationError
) -> JSONResponse:
    logger.warning("RAG validation error on %s: %s", request.url.path, exc)
    return JSONResponse(status_code=422, content={"detail": str(exc)})


@app.exception_handler(RAGError)
async def rag_error_handler(request: Request, exc: RAGError) -> JSONResponse:
    logger.error("RAG error on %s: %s", request.url.path, exc)
    return JSONResponse(status_code=500, content={"detail": str(exc)})


app.include_router(api_router, prefix=settings.API_V1_STR)
