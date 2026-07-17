from typing import Any

from fastapi import Request


def success_envelope(request: Request, data: Any) -> dict[str, Any]:
    return {
        "data": data,
        "error": None,
        "requestId": request.state.request_id,
    }


def error_envelope(
    request: Request,
    *,
    code: str,
    message: str,
) -> dict[str, Any]:
    return {
        "data": None,
        "error": {"code": code, "message": message},
        "requestId": request.state.request_id,
    }
