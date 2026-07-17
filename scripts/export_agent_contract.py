from pathlib import Path
import sys

import yaml

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "backend"))

from app.main import app  # noqa: E402


OUTPUT = ROOT / "contracts" / "panenin-agent-api.openapi.yaml"
PREFIX = "/api/v1/internal/agent"


def main() -> None:
    schema = app.openapi()
    schema["info"] = {
        "title": "Panenin Internal Agent API",
        "version": "0.1.0",
        "description": (
            "Narrow service-to-service contract used by the WhatsApp AI Service. "
            "Panenin Core remains the only business and database authority."
        ),
    }
    schema["servers"] = [{"url": "http://localhost:8000"}]
    schema["paths"] = {
        path: value for path, value in schema["paths"].items() if path.startswith(PREFIX)
    }
    components = schema.setdefault("components", {})
    security_schemes = components.setdefault("securitySchemes", {})
    security_schemes["AgentBearer"] = {
        "type": "http",
        "scheme": "bearer",
        "bearerFormat": "opaque service token",
        "description": "Compared in constant time against PANENIN_AI_SERVICE_TOKEN_HASH.",
    }
    component_schemas = components.setdefault("schemas", {})
    component_schemas["ErrorEnvelope"] = {
        "type": "object",
        "required": ["data", "error", "requestId"],
        "properties": {
            "data": {"type": "null"},
            "error": {
                "type": "object",
                "required": ["code", "message"],
                "properties": {
                    "code": {"type": "string", "example": "STABLE_CODE"},
                    "message": {"type": "string", "example": "Pesan aman."},
                },
            },
            "requestId": {"type": "string", "format": "uuid"},
        },
    }
    component_schemas["SuccessEnvelope"] = {
        "type": "object",
        "required": ["data", "error", "requestId"],
        "properties": {
            "data": {},
            "error": {"type": "null"},
            "requestId": {"type": "string", "format": "uuid"},
        },
    }
    for path_item in schema["paths"].values():
        for method, operation in path_item.items():
            if method not in {"get", "post", "put", "patch", "delete"}:
                continue
            operation["security"] = [{"AgentBearer": []}]
            responses = operation.setdefault("responses", {})
            success = "201" if "201" in responses else "200"
            responses[success] = {
                "description": "Successful Panenin Core response",
                "content": {
                    "application/json": {
                        "schema": {"$ref": "#/components/schemas/SuccessEnvelope"}
                    }
                },
            }
            for status, description in {
                "401": "Missing or invalid service credential",
                "403": "Resolved identity is not authorized",
                "409": "Business state or idempotency conflict",
                "422": "Request validation failed",
            }.items():
                responses[status] = {
                    "description": description,
                    "content": {
                        "application/json": {
                            "schema": {"$ref": "#/components/schemas/ErrorEnvelope"}
                        }
                    },
                }
    schema["x-panenin-contract-version"] = "0.1.0"
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(
        yaml.safe_dump(schema, sort_keys=False, allow_unicode=True, width=100),
        encoding="utf-8",
    )
    print(OUTPUT)


if __name__ == "__main__":
    main()
