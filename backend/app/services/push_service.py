"""
Push notification via Firebase Cloud Messaging.
Verifica id_token Firebase (Phone Auth) e invio messaggi ai device registrati.
"""
from typing import List

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.fcm_token import FCMToken
from app.services.firebase_otp_service import init_firebase


def verify_firebase_id_token(id_token: str) -> str | None:
    """
    Verifica id_token Firebase (es. da Phone Auth) e ritorna il numero di telefono (claim 'phone_number').
    Ritorna None se token non valido.
    """
    init_firebase()
    try:
        import firebase_admin.auth
        decoded = firebase_admin.auth.verify_id_token(id_token)
        return decoded.get("phone_number")
    except Exception:
        return None


async def get_fcm_tokens_for_user(db: AsyncSession, user_id) -> List[str]:
    """Ritorna la lista di token FCM registrati per l'utente."""
    r = await db.execute(select(FCMToken.token).where(FCMToken.user_id == user_id))
    return [row[0] for row in r.all()]


async def send_push_to_users(
    db: AsyncSession,
    user_ids: List,
    title: str,
    body: str,
    data: dict | None = None,
) -> int:
    """
    Invia push notification a tutti i device degli utenti indicati.
    Ritorna il numero di messaggi inviati con successo.
    """
    if not user_ids:
        return 0
    tokens = []
    for uid in user_ids:
        r = await db.execute(select(FCMToken.token).where(FCMToken.user_id == uid))
        tokens.extend([row[0] for row in r.all()])
    if not tokens:
        return 0
    return send_push_to_tokens(tokens, title=title, body=body, data=data)


def send_push_to_tokens(
    tokens: List[str],
    title: str,
    body: str,
    data: dict | None = None,
) -> int:
    """Invia push a una lista di token FCM. Ritorna numero invii riusciti."""
    init_firebase()
    if not tokens:
        return 0
    try:
        import firebase_admin.messaging
        message = firebase_admin.messaging.MulticastMessage(
            notification=firebase_admin.messaging.Notification(title=title, body=body),
            data=data or {},
            tokens=tokens,
        )
        response = firebase_admin.messaging.send_multicast(message)
        return response.success_count
    except Exception:
        return 0
