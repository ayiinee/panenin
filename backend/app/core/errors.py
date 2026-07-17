from dataclasses import dataclass


@dataclass(slots=True)
class DomainError(Exception):
    code: str
    message: str
    status_code: int = 400

    def __str__(self) -> str:
        return self.message


class AuthenticationError(DomainError):
    def __init__(self, message: str = "Kredensial tidak valid.") -> None:
        super().__init__("UNAUTHORIZED", message, 401)


class AuthorizationError(DomainError):
    def __init__(self, message: str = "Anda tidak berhak melakukan tindakan ini.") -> None:
        super().__init__("FORBIDDEN", message, 403)


class NotFoundError(DomainError):
    def __init__(self, message: str = "Data tidak ditemukan.") -> None:
        super().__init__("NOT_FOUND", message, 404)


class ConflictError(DomainError):
    def __init__(self, code: str, message: str) -> None:
        super().__init__(code, message, 409)


class ConfigurationError(DomainError):
    def __init__(self, message: str = "Layanan belum dikonfigurasi.") -> None:
        super().__init__("SERVICE_UNAVAILABLE", message, 503)
