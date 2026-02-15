"""
Schema Pydantic per Auth e User.
"""
import re
from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, Field, field_validator


class UserRegister(BaseModel):
    email: str = Field(..., min_length=3, max_length=255)
    username: str = Field(..., min_length=2, max_length=50)
    password: str = Field(..., min_length=6, max_length=100)
    phone_number: Optional[str] = Field(None, max_length=20)

    @field_validator("email")
    @classmethod
    def email_format(cls, v: str) -> str:
        if "@" not in v or "." not in v.split("@")[-1]:
            raise ValueError("Invalid email format")
        return v.lower()

    @field_validator("phone_number")
    @classmethod
    def validate_phone(cls, v: Optional[str]) -> Optional[str]:
        if v is None or v == "":
            return None
        if not re.match(r"^\+[1-9]\d{8,14}$", v):
            raise ValueError("Numero non valido. Usa formato internazionale: +393331234567")
        return v


class UserLogin(BaseModel):
    email: str = Field(..., min_length=1)
    password: str = Field(..., min_length=1)


class UserUpdate(BaseModel):
    full_name: Optional[str] = Field(None, max_length=100)
    avatar_url: Optional[str] = Field(None, max_length=500)


class UserResponse(BaseModel):
    id: UUID
    email: str
    username: str
    full_name: Optional[str] = None
    avatar_url: Optional[str] = None
    phone_number: Optional[str] = None
    is_active: bool
    is_admin: bool
    created_at: datetime

    class Config:
        from_attributes = True


class Token(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class TokenRefresh(BaseModel):
    refresh_token: str


# --- Recupero password OTP ---


class PasswordForgotRequest(BaseModel):
    """Step 1: utente inserisce email."""
    email: str = Field(..., min_length=1)


class PasswordForgotResponse(BaseModel):
    """Risposta: conferma invio OTP (telefono mascherato). In DEBUG può includere otp_code_debug. phone per Firebase flow (client invia SMS)."""
    message: str
    phone_masked: str
    otp_code_debug: Optional[str] = None  # Solo se DEBUG per test senza SMS
    phone: Optional[str] = None  # Per Firebase Phone Auth (client invia SMS)


class OTPVerifyRequest(BaseModel):
    """Step 2: utente inserisce codice OTP da SMS."""
    email: str = Field(..., min_length=1)
    otp_code: str = Field(..., min_length=6, max_length=6)


class OTPVerifyResponse(BaseModel):
    """Risposta: token temporaneo per reset."""
    message: str
    reset_token: str


class PasswordResetRequest(BaseModel):
    """Step 3: nuova password (doppia conferma)."""
    reset_token: str
    new_password: str = Field(..., min_length=6)
    confirm_password: str = Field(..., min_length=6)

    @field_validator("confirm_password")
    @classmethod
    def passwords_match(cls, v: str, info) -> str:
        if "new_password" in info.data and v != info.data["new_password"]:
            raise ValueError("Le password non coincidono")
        return v


class PasswordResetResponse(BaseModel):
    """Risposta finale reset."""
    message: str


class FcmTokenRequest(BaseModel):
    fcm_token: str = Field(..., min_length=1, max_length=500)


class VerifyPhoneResetRequest(BaseModel):
    """Verifica recupero password tramite Firebase Phone Auth id_token."""
    id_token: str = Field(..., min_length=1)
