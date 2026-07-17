import hashlib
import secrets


def main() -> None:
    token = secrets.token_urlsafe(32)
    pepper = secrets.token_urlsafe(32)
    token_hash = hashlib.sha256(token.encode("utf-8")).hexdigest()
    print("Simpan token plaintext hanya pada secret manager WhatsApp AI Service:")
    print(token)
    print("\nTambahkan nilai berikut ke backend .env/secret manager:")
    print(f"PANENIN_AI_SERVICE_TOKEN_HASH={token_hash}")
    print(f"CONFIRMATION_CODE_PEPPER={pepper}")


if __name__ == "__main__":
    main()
