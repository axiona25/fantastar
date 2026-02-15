"""
Auth API: register, login, me (GET/PUT), refresh.
"""
from uuid import UUID
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.user import User
from app.models.fcm_token import FCMToken
from app.schemas.user import (
    UserRegister,
    UserLogin,
    UserUpdate,
    UserResponse,
    Token,
    TokenRefresh,
    PasswordForgotRequest,
    PasswordForgotResponse,
    OTPVerifyRequest,
    OTPVerifyResponse,
    PasswordResetRequest,
    PasswordResetResponse,
    FcmTokenRequest,
    VerifyPhoneResetRequest,
)
from app.core.security import (
    hash_password,
    verify_password,
    create_access_token,
    create_refresh_token,
    create_reset_token,
    decode_token,
)
from app.dependencies import get_current_user
from app.services.firebase_otp_service import request_otp, verify_otp, reset_password as do_reset_password, init_firebase
from app.services.push_service import verify_firebase_id_token

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=UserResponse)
async def register(
    body: UserRegister,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Registrazione nuovo utente."""
    r = await db.execute(select(User).where(User.email == body.email))
    if r.scalar_one_or_none():
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Email already registered")
    r = await db.execute(select(User).where(User.username == body.username))
    if r.scalar_one_or_none():
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Username already taken")
    user = User(
        email=body.email,
        username=body.username,
        hashed_password=hash_password(body.password),
        phone_number=getattr(body, "phone_number", None),
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return user


@router.post("/login", response_model=Token)
async def login(
    body: UserLogin,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Login: ritorna access_token e refresh_token."""
    r = await db.execute(select(User).where(User.email == body.email))
    user = r.scalar_one_or_none()
    if not user or not verify_password(body.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
        )
    if not user.is_active:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="User inactive")
    return Token(
        access_token=create_access_token(str(user.id)),
        refresh_token=create_refresh_token(str(user.id)),
    )


@router.get("/me", response_model=UserResponse)
async def me(
    current_user: Annotated[User, Depends(get_current_user)],
):
    """Profilo utente corrente."""
    return current_user


@router.put("/me", response_model=UserResponse)
async def update_me(
    body: UserUpdate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Modifica profilo (full_name, avatar_url)."""
    if body.full_name is not None:
        current_user.full_name = body.full_name
    if body.avatar_url is not None:
        current_user.avatar_url = body.avatar_url
    await db.commit()
    await db.refresh(current_user)
    return current_user


@router.post("/refresh", response_model=Token)
async def refresh(
    body: TokenRefresh,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Refresh token: ritorna nuovo access_token e refresh_token."""
    payload = decode_token(body.refresh_token)
    if not payload or payload.get("type") != "refresh":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired refresh token",
        )
    sub = payload.get("sub")
    if not sub:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")
    try:
        user_id = UUID(sub)
    except ValueError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")
    r = await db.execute(select(User).where(User.id == user_id))
    user = r.scalar_one_or_none()
    if not user or not user.is_active:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found or inactive")
    return Token(
        access_token=create_access_token(str(user.id)),
        refresh_token=create_refresh_token(str(user.id)),
    )


@router.post("/forgot-password", response_model=PasswordForgotResponse)
async def forgot_password(
    body: PasswordForgotRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """
    Step 1 recupero password: invia OTP via SMS.
    Per sicurezza ritorna sempre 200 con messaggio generico e phone_masked
    (anche se email non esiste / nessun telefono / rate limit).
    """
    try:
        out = await request_otp(body.email, db)
        return PasswordForgotResponse(
            message=out["message"],
            phone_masked=out["phone_masked"],
            otp_code_debug=out.get("otp_code_debug"),
            phone=out.get("phone"),
        )
    except Exception:
        return PasswordForgotResponse(
            message="Se l'email è registrata e hai un numero associato, riceverai un SMS con il codice.",
            phone_masked="***",
        )


@router.post("/verify-otp", response_model=OTPVerifyResponse)
async def verify_otp_endpoint(
    body: OTPVerifyRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Step 2: verifica codice OTP e ritorna reset_token."""
    try:
        out = await verify_otp(body.email, body.otp_code, db)
        return OTPVerifyResponse(message=out["message"], reset_token=out["reset_token"])
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


@router.post("/reset-password", response_model=PasswordResetResponse)
async def reset_password_endpoint(
    body: PasswordResetRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Step 3: imposta nuova password con reset_token."""
    try:
        out = await do_reset_password(body.reset_token, body.new_password, db)
        return PasswordResetResponse(message=out["message"])
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


@router.post("/fcm-token")
async def register_fcm_token(
    body: FcmTokenRequest,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Registra il token FCM del device per invio push notification."""
    existing = await db.execute(
        select(FCMToken).where(
            FCMToken.user_id == current_user.id,
            FCMToken.token == body.fcm_token,
        )
    )
    if existing.scalar_one_or_none():
        return {"message": "Token già registrato"}
    db.add(FCMToken(user_id=current_user.id, token=body.fcm_token))
    await db.commit()
    return {"message": "Token registrato"}


@router.post("/verify-phone-reset", response_model=OTPVerifyResponse)
async def verify_phone_reset(
    body: VerifyPhoneResetRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Step 2 alternativo: verifica tramite Firebase Phone Auth id_token; ritorna reset_token."""
    init_firebase()
    phone = verify_firebase_id_token(body.id_token)
    if not phone:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Token non valido")
    r = await db.execute(select(User).where(User.phone_number == phone))
    user = r.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Nessun utente con questo numero")
    reset_token = create_reset_token(str(user.id))
    return OTPVerifyResponse(message="Codice verificato. Inserisci la nuova password", reset_token=reset_token)
