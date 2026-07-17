from pathlib import Path

import yaml


def test_agent_contract_is_openapi_31_and_complete() -> None:
    root = Path(__file__).resolve().parents[2]
    contract = yaml.safe_load(
        (root / "contracts" / "panenin-agent-api.openapi.yaml").read_text(
            encoding="utf-8"
        )
    )

    assert contract["openapi"].startswith("3.1")
    assert contract["info"]["version"] == "0.1.0"
    assert contract["x-panenin-contract-version"] == "0.1.0"
    expected_paths = {
        "/api/v1/internal/agent/identity/resolve",
        "/api/v1/internal/agent/identity/link",
        "/api/v1/internal/agent/context",
        "/api/v1/internal/agent/inventory",
        "/api/v1/internal/agent/demands",
        "/api/v1/internal/agent/orders",
        "/api/v1/internal/agent/control/overview",
        "/api/v1/internal/agent/catalog/search",
        "/api/v1/internal/agent/sell/preview",
        "/api/v1/internal/agent/buy/preview",
        "/api/v1/internal/agent/orders/preview",
        "/api/v1/internal/agent/control/preview",
        "/api/v1/internal/agent/actions/{action_id}/confirm",
        "/api/v1/internal/agent/actions/{action_id}/cancel",
    }
    assert set(contract["paths"]) == expected_paths
    for path_item in contract["paths"].values():
        for method, operation in path_item.items():
            if method in {"get", "post", "put", "patch", "delete"}:
                assert operation["security"] == [{"AgentBearer": []}]
                assert "401" in operation["responses"]


def test_agent_migration_is_additive_and_redacts_channel_identity() -> None:
    root = Path(__file__).resolve().parents[2]
    sql = (
        root
        / "supabase"
        / "migrations"
        / "20260717170000_whatsapp_agent_core.sql"
    ).read_text(encoding="utf-8").lower()

    assert "create table public.whatsapp_link_codes" in sql
    assert "create table public.organization_commodities" in sql
    assert "alter table public.bot_actions" in sql
    assert "drop table" not in sql
    assert "truncate" not in sql
    assert "wa:v1:" in sql
