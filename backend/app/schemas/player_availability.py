"""Schema per impostazione manuale disponibilità giocatore (admin)."""
from datetime import date
from typing import Optional

from pydantic import BaseModel, Field, field_validator


VALID_AVAILABILITY_STATUSES = (
    "AVAILABLE",
    "INJURED",
    "SUSPENDED",
    "DOUBTFUL",
    "NOT_CALLED",
    "NATIONAL_TEAM",
)


class PlayerAvailabilitySet(BaseModel):
    """Body PUT /players/{id}/availability."""
    status: str = Field(..., min_length=1, max_length=20)
    detail: Optional[str] = Field(None, max_length=200)
    return_date: Optional[date] = None

    @field_validator("status")
    @classmethod
    def validate_status(cls, v: str) -> str:
        if v not in VALID_AVAILABILITY_STATUSES:
            raise ValueError(f"status must be one of: {VALID_AVAILABILITY_STATUSES}")
        return v
