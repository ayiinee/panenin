from dataclasses import dataclass
from uuid import UUID


@dataclass(frozen=True, slots=True)
class OwnedOrganization:
    id: UUID
    type: str
    name: str
    owner_user_id: UUID
    address_text: str | None = None
    latitude: float | None = None
    longitude: float | None = None
