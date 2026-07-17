from collections.abc import Awaitable, Callable
from uuid import uuid4

from fastapi import FastAPI, HTTPException, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, Response

from app.api.router import api_router
from app.core.config import get_settings
from app.core.database import check_database_connection
from app.core.errors import DomainError
from app.core.schemas import error_envelope

settings = get_settings()

app = FastAPI(
    title=settings.app_name,
    version="0.1.0",
    debug=settings.app_debug,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=[settings.frontend_origin],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.middleware("http")
async def add_request_id(
    request: Request,
    call_next: Callable[[Request], Awaitable[Response]],
) -> Response:
    request_id = request.headers.get("X-Request-ID", str(uuid4()))
    request.state.request_id = request_id
    response = await call_next(request)
    response.headers["X-Request-ID"] = request_id
    return response


@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException) -> JSONResponse:
    detail = exc.detail if isinstance(exc.detail, dict) else {}
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "data": None,
            "error": {
                "code": detail.get("code", "HTTP_ERROR"),
                "message": detail.get("message", str(exc.detail)),
            },
            "requestId": getattr(request.state, "request_id", str(uuid4())),
        },
        headers=exc.headers,
    )


@app.exception_handler(DomainError)
async def domain_error_handler(request: Request, exc: DomainError) -> JSONResponse:
    return JSONResponse(
        status_code=exc.status_code,
        content=error_envelope(
            request,
            code=exc.code,
            message=exc.message,
        ),
    )


@app.exception_handler(RequestValidationError)
async def validation_error_handler(
    request: Request,
    exc: RequestValidationError,
) -> JSONResponse:
    del exc
    return JSONResponse(
        status_code=422,
        content=error_envelope(
            request,
            code="VALIDATION_ERROR",
            message="Data permintaan tidak valid.",
        ),
    )


app.include_router(api_router, prefix=settings.api_v1_prefix)


@app.get("/api/v1/health")
async def health_check() -> dict[str, str]:
    return {
        "status": "ok",
        "service": "panenin-api",
    }


@app.get("/api/v1/health/database")
async def database_health_check() -> dict[str, str]:
    await check_database_connection()
    return {
        "status": "ok",
        "service": "panenin-database",
    }
