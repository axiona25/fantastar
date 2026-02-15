# TASK 05B — Report Recupero Password (OTP / Firebase)

**Data completamento:** 13 Febbraio 2026  
**Percorso progetto:** `/Users/r.amoroso/Documents/Cursor/Fantastar`

---

## 1. Obiettivo del task

Aggiungere il recupero password tramite OTP (codice a 6 cifre), con invio SMS opzionale via Firebase. Flusso in 3 step: richiesta OTP per email → verifica codice OTP → reset password con token temporaneo.

---

## 2. Cosa è stato implementato

### 2.1 Config e ambiente
- **`app/config.py`**: aggiunto `FIREBASE_CREDENTIALS_PATH` (default `"firebase-credentials.json"`).
- **`.env`**: da aggiungere a mano `FIREBASE_CREDENTIALS_PATH=firebase-credentials.json` (o percorso scelto).
- **`.gitignore`**: aggiunti `firebase-credentials.json` e `backend/firebase-credentials.json`.
- **`backend/requirements.txt`**: aggiunto `firebase-admin==6.4.0`.

### 2.2 Modelli
- **`app/models/user.py`**: campo opzionale `phone_number` (`String(20)`, nullable).
- **`app/models/password_reset.py`** (nuovo): tabella `password_reset_otp` con id, user_id (FK users.id), otp_code (6 caratteri), firebase_session (nullable), is_verified, is_used, attempts, expires_at, created_at (SQLAlchemy 2.0 style).
- **`app/models/__init__.py`**: esportato `PasswordResetOTP`.

### 2.3 Migrazione Alembic
- **`alembic/versions/b2c8e7f1a0d0_add_phone_number_and_password_reset_otp.py`**: aggiunge colonna `phone_number` a `users` e crea tabella `password_reset_otp`.  
- Eseguire da backend (o da container):  
  `alembic upgrade head`

### 2.4 Schemi Pydantic (`app/schemas/user.py`)
- **UserRegister**: aggiunto `phone_number` opzionale con validatore formato internazionale (`^\+[1-9]\d{8,14}$`).
- **UserResponse**: aggiunto `phone_number` opzionale.
- **PasswordForgotRequest**: email.
- **PasswordForgotResponse**: message, phone_masked, otp_code_debug (opzionale, solo in DEBUG).
- **OTPVerifyRequest**: email, otp_code (6 caratteri).
- **OTPVerifyResponse**: message, reset_token.
- **PasswordResetRequest**: reset_token, new_password (min 6), confirm_password con validatore “coincidenza” e lunghezza.
- **PasswordResetResponse**: message.

### 2.5 Security (`app/core/security.py`)
- **create_reset_token(subject)**: JWT con `type: "reset"` e scadenza 5 minuti (stesso secret/algoritmo degli altri token). Usato solo per il reset password; un access token normale non può essere usato per resettare la password.

### 2.6 Servizio OTP (`app/services/firebase_otp_service.py`)
- **init_firebase()**: inizializza Firebase Admin una sola volta se esiste il file credentials; altrimenti l’OTP viene solo salvato/verificato in DB (flusso “custom OTP” senza SMS reale).
- **request_otp(email, db)**:
  - Cerca utente per email; se non esiste o non ha `phone_number` o rate limit (max 3 OTP in 15 min per utente) → solleva `ValueError` (l’endpoint restituisce sempre 200 con messaggio generico).
  - Genera OTP 6 cifre, salva in `PasswordResetOTP` (expires_at = ora + 5 min).
  - Ritorna message, phone_masked e, se DEBUG, otp_code_debug.
- **verify_otp(email, otp_code, db)**:
  - Ultimo OTP non usato/non verificato per l’utente; controlla scadenza e tentativi (max 3); se codice corretto imposta is_verified=True e ritorna message + reset_token (create_reset_token(user.id)).
- **reset_password(reset_token, new_password, db)**:
  - Decodifica token, verifica `type == "reset"`, estrae user_id (UUID da `sub`); trova OTP verificato e non usato per quell’utente; aggiorna hashed_password, imposta OTP a is_used=True; ritorna messaggio di successo.

### 2.7 API Auth (`app/api/v1/auth.py`)
- **Registrazione**: in creazione `User` viene salvato `phone_number=getattr(body, "phone_number", None)`.
- **POST /forgot-password**: body `PasswordForgotRequest`; chiama `request_otp`; in caso di eccezione restituisce comunque 200 con messaggio generico e `phone_masked="***"` (nessuna rivelazione sull’esistenza dell’email).
- **POST /verify-otp**: body `OTPVerifyRequest`; chiama `verify_otp`; risposta `OTPVerifyResponse` o 400 con dettaglio errore.
- **POST /reset-password**: body `PasswordResetRequest`; chiama `reset_password`; risposta `PasswordResetResponse` o 400.

---

## 3. Endpoint aggiunti

| Metodo | Endpoint | Descrizione |
|--------|----------|-------------|
| POST | `/api/v1/auth/forgot-password` | Step 1: richiesta OTP (sempre 200, messaggio generico in caso errore) |
| POST | `/api/v1/auth/verify-otp` | Step 2: verifica codice OTP → reset_token |
| POST | `/api/v1/auth/reset-password` | Step 3: nuova password con reset_token |

---

## 4. Sicurezza

| Aspetto | Implementazione |
|--------|------------------|
| OTP | Scadenza 5 minuti |
| Tentativi OTP | Max 3 per codice; poi richiedere nuovo OTP |
| Rate limiting | Max 3 richieste OTP per utente ogni 15 minuti |
| Reset token | JWT type `"reset"`, scadenza 5 minuti (non riutilizzabile come access token) |
| Non rivelare email | POST /forgot-password ritorna sempre 200 con messaggio generico e phone_masked (anche se email assente / nessun telefono / rate limit) |
| Password | Doppia conferma (new_password + confirm_password), minimo 6 caratteri |

---

## 5. Come testare

Eseguire la migrazione (da container o da backend con venv attivo):

```bash
# In Docker (dalla root del progetto)
docker-compose exec backend alembic upgrade head
```

Creare un utente di test con telefono (o aggiornare un utente esistente con `phone_number`):

```bash
# Registrazione con telefono
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","username":"testuser","password":"pass1234","phone_number":"+393331234567"}'
```

Flusso recupero password (con DEBUG=true il codice OTP è in `otp_code_debug`):

```bash
# Step 1: Richiedi OTP
curl -X POST http://localhost:8000/api/v1/auth/forgot-password \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com"}'

# Step 2: Verifica OTP (usare il codice dalla risposta di Step 1 se DEBUG, altrimenti quello ricevuto via SMS)
curl -X POST http://localhost:8000/api/v1/auth/verify-otp \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","otp_code":"123456"}'

# Step 3: Reset password (sostituire TOKEN_DAL_STEP2 con reset_token ricevuto)
curl -X POST http://localhost:8000/api/v1/auth/reset-password \
  -H "Content-Type: application/json" \
  -d '{"reset_token":"TOKEN_DAL_STEP2","new_password":"nuovapass123","confirm_password":"nuovapass123"}'
```

Login con la nuova password:

```bash
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"nuovapass123"}'
```

---

## 6. File creati/modificati

| File | Azione |
|------|--------|
| `backend/app/config.py` | Modificato (FIREBASE_CREDENTIALS_PATH) |
| `.gitignore` | Modificato (firebase-credentials.json) |
| `backend/requirements.txt` | Modificato (firebase-admin) |
| `backend/app/models/user.py` | Modificato (phone_number) |
| `backend/app/models/password_reset.py` | Creato |
| `backend/app/models/__init__.py` | Modificato (export PasswordResetOTP) |
| `backend/alembic/versions/b2c8e7f1a0d0_add_phone_number_and_password_reset_otp.py` | Creato |
| `backend/app/schemas/user.py` | Modificato (phone_number, schemi recupero password) |
| `backend/app/core/security.py` | Modificato (create_reset_token) |
| `backend/app/services/firebase_otp_service.py` | Creato |
| `backend/app/api/v1/auth.py` | Modificato (register phone_number, forgot-password, verify-otp, reset-password) |
| `reports/TASK_05B_REPORT.md` | Creato |

---

## 7. Note

- **Firebase**: Se `FIREBASE_CREDENTIALS_PATH` punta a un file esistente, `init_firebase()` viene chiamato; l’invio SMS reale può essere integrato in seguito (es. Cloud Functions o provider esterno). Senza credentials il backend gestisce solo generazione/verifica OTP in DB; in DEBUG il codice è restituito in `otp_code_debug`.
- **phone_number**: Opzionale in registrazione per compatibilità con client esistenti; per il recupero password l’utente deve avere un numero associato.
- **Reset token**: Utilizzato solo per il reset; il controllo `payload.get("type") == "reset"` evita l’uso di access/refresh token per cambiare la password.
