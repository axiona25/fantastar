"""
Servizio OTP per recupero password (SMS / Firebase).

FLUSSO:
1. request_otp(email) → trova utente, genera OTP, salva in DB (invio SMS opzionale via Firebase)
2. verify_otp(email, code) → verifica codice, ritorna reset_token
3. reset_password(reset_token, new_password) → cambia password

SICUREZZA:
- OTP scade dopo 5 minuti
- Max 3 tentativi per OTP
- Max 3 richieste OTP per utente ogni 15 minuti
- Reset token JWT type=reset, scadenza 5 minuti
"""
import random
import string
from datetime import datetime, timedelta
from pathlib import Path
from uuid import UUID

from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.models.user import User
from app.models.password_reset import PasswordResetOTP
from app.core.security import hash_password, create_reset_token, decode_token

_firebase_initialized = False


def init_firebase() -> bool:
    """Inizializza Firebase Admin (una sola volta). Ritorna True se ok."""
    global _firebase_initialized
    if _firebase_initialized:
        return True
    path = getattr(settings, "FIREBASE_CREDENTIALS_PATH", None) or "firebase-credentials.json"
    if not path or not Path(path).exists():
        return False
    try:
        import firebase_admin
        from firebase_admin import credentials
        if not firebase_admin._apps:
            cred = credentials.Certificate(path)
            firebase_admin.initialize_app(cred)
        _firebase_initialized = True
        return True
    except Exception:
        return False


def generate_otp() -> str:
    """Genera codice OTP a 6 cifre."""
    return "".join(random.choices(string.digits, k=6))


def mask_phone(phone: str) -> str:
    """Maschera numero: +39333****567."""
    if not phone or len(phone) <= 6:
        return "***"
    return phone[:5] + "*" * min(len(phone) - 8, 6) + phone[-3:]


async def request_otp(email: str, db: AsyncSession) -> dict:
    """
    Step 1: utente chiede reset.
    Verifica email e telefono, rate limiting, genera OTP e salva in DB.
    In DEBUG il codice può essere restituito per test senza SMS.
    """
    result = await db.execute(select(User).where(User.email == email))
    user = result.scalar_one_or_none()

    if not user:
        raise ValueError("Se l'email è registrata, riceverai un SMS")

    if not user.phone_number:
        raise ValueError("Nessun numero di telefono associato a questo account")

    fifteen_min_ago = datetime.utcnow() - timedelta(minutes=15)
    count_result = await db.execute(
        select(func.count(PasswordResetOTP.id)).where(
            PasswordResetOTP.user_id == user.id,
            PasswordResetOTP.created_at > fifteen_min_ago,
        )
    )
    recent_count = count_result.scalar() or 0
    if recent_count >= 3:
        raise ValueError("Troppi tentativi. Riprova tra 15 minuti")

    otp_code = generate_otp()
    init_firebase()

    otp_record = PasswordResetOTP(
        user_id=user.id,
        otp_code=otp_code,
        expires_at=datetime.utcnow() + timedelta(minutes=5),
    )
    db.add(otp_record)
    await db.commit()

    out = {
        "message": "Codice OTP inviato via SMS",
        "phone_masked": mask_phone(user.phone_number),
        "phone": user.phone_number,  # Per Firebase Phone Auth (client invia SMS)
    }
    if getattr(settings, "DEBUG", False):
        out["otp_code_debug"] = otp_code
    return out


async def verify_otp(email: str, otp_code: str, db: AsyncSession) -> dict:
    """
    Step 2: utente inserisce codice OTP.
    Verifica codice e scadenza, max 3 tentativi, ritorna reset_token JWT.
    """
    result = await db.execute(select(User).where(User.email == email))
    user = result.scalar_one_or_none()
    if not user:
        raise ValueError("Email non trovata")

    otp_result = await db.execute(
        select(PasswordResetOTP)
        .where(
            PasswordResetOTP.user_id == user.id,
            PasswordResetOTP.is_used == False,
            PasswordResetOTP.is_verified == False,
        )
        .order_by(PasswordResetOTP.created_at.desc())
        .limit(1)
    )
    otp_record = otp_result.scalar_one_or_none()

    if not otp_record:
        raise ValueError("Nessun codice OTP attivo. Richiedi un nuovo codice")

    if datetime.utcnow() > otp_record.expires_at:
        raise ValueError("Codice OTP scaduto. Richiedi un nuovo codice")

    if otp_record.attempts >= 3:
        raise ValueError("Troppi tentativi errati. Richiedi un nuovo codice")

    if otp_record.otp_code != otp_code:
        otp_record.attempts += 1
        await db.commit()
        remaining = 3 - otp_record.attempts
        raise ValueError(f"Codice errato. {remaining} tentativi rimasti")

    otp_record.is_verified = True
    await db.commit()

    reset_token = create_reset_token(str(user.id))
    return {
        "message": "Codice verificato. Inserisci la nuova password",
        "reset_token": reset_token,
    }


async def reset_password(reset_token: str, new_password: str, db: AsyncSession) -> dict:
    """
    Step 3: utente inserisce nuova password.
    Verifica reset_token (JWT type=reset), cambia password, invalida OTP.
    """
    payload = decode_token(reset_token)
    if not payload or payload.get("type") != "reset":
        raise ValueError("Token scaduto o non valido. Richiedi un nuovo codice OTP")

    sub = payload.get("sub")
    if not sub:
        raise ValueError("Token non valido")

    try:
        user_id = UUID(sub)
    except ValueError:
        raise ValueError("Token non valido")

    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise ValueError("Utente non trovato")

    otp_result = await db.execute(
        select(PasswordResetOTP)
        .where(
            PasswordResetOTP.user_id == user.id,
            PasswordResetOTP.is_verified == True,
            PasswordResetOTP.is_used == False,
        )
        .order_by(PasswordResetOTP.created_at.desc())
        .limit(1)
    )
    otp_record = otp_result.scalar_one_or_none()
    if not otp_record:
        raise ValueError("Nessun OTP verificato trovato. Richiedi un nuovo codice")

    user.hashed_password = hash_password(new_password)
    otp_record.is_used = True
    await db.commit()

    return {"message": "Password aggiornata con successo! Puoi effettuare il login"}
