import argparse
import json
from pathlib import Path

from dotenv import dotenv_values


ROOT = Path(__file__).resolve().parents[1]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--api-base-url", default="http://127.0.0.1:8000")
    args = parser.parse_args()

    env = dotenv_values(ROOT / ".env")
    missing = [
        key
        for key in ("SUPABASE_URL", "SUPABASE_ANON_KEY")
        if not (env.get(key) or "").strip()
    ]
    if missing:
        raise SystemExit(f"Konfigurasi belum lengkap: {', '.join(missing)}")
    config = {
        "API_BASE_URL": args.api_base_url.rstrip("/"),
        "SUPABASE_URL": env["SUPABASE_URL"],
        "SUPABASE_ANON_KEY": env["SUPABASE_ANON_KEY"],
        "AUTH_REDIRECT_URL": "com.panenin.app://login-callback/",
        "PASSWORD_RESET_REDIRECT_URL": "com.panenin.app://reset-password/",
    }
    output = ROOT / "frontend" / "config.local.json"
    output.write_text(json.dumps(config, indent=2) + "\n", encoding="utf-8")
    print(f"Konfigurasi frontend lokal dibuat: {output}")


if __name__ == "__main__":
    main()
