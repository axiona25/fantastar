# TASK 05 — Report Auth & Users API

**Data completamento:** 13 Febbraio 2026  
**Percorso progetto:** `/Users/r.amoroso/Documents/Cursor/Fantastar`

---

## 1. Obiettivo del task

Creare il sistema di autenticazione JWT e le API utenti: registrazione, login, profilo (GET/PUT), refresh token, con dependency `get_current_user` per proteggere le route.

---

## 2. Cosa è stato fatto

### 2.1 Security (`app/core/security.py`)
- **Password**: `hash_password(password)` e `verify_password(plain, hashed)` con `passlib` (bcrypt).
- **JWT**: `create_access_token(subject, expires_delta)` (default da `JWT_EXPIRE_MINUTES`), `create_refresh_token(subject)` (7 giorni), `decode_token(token)` con `python-jose` (HS256).
- Payload: `exp`, `sub` (user id), `type` ("access" o "refresh").

### 2.2 Schemi Pydantic (`app/schemas/user.py`)
- **UserRegister**: email, username (2–50), password (min 6); validazione formato email.
- **UserLogin**: email, password.
- **UserUpdate**: full_name, avatar_url opzionali.
- **UserResponse**: id, email, username, full_name, avatar_url, is_active, is_admin, created_at (from_attributes=True).
- **Token**: access_token, refresh_token, token_type="bearer".
- **TokenRefresh**: refresh_token.

### 2.3 Dependencies (`app/dependencies.py`)
- **get_current_user**: estrae Bearer token, decodifica JWT (type=access), carica utente da DB per `sub` (UUID), verifica is_active; altrimenti 401/403.
- **get_current_user_optional**: stessa logica ma ritorna None se assente o invalido (per route opzionalmente protette).
- Uso di `HTTPBearer` per Authorization header.

### 2.4 Router Auth (`app/api/v1/auth.py`)
- **POST /api/v1/auth/register**: crea utente (email e username unici), ritorna UserResponse.
- **POST /api/v1/auth/login**: verifica credenziali, ritorna Token (access + refresh).
- **GET /api/v1/auth/me**: profilo utente corrente (protetto con get_current_user).
- **PUT /api/v1/auth/me**: aggiorna full_name e/o avatar_url (protetto).
- **POST /api/v1/auth/refresh**: body con refresh_token, ritorna nuovo Token.

### 2.5 Integrazione
- Router incluso in `main.py` con prefisso `/api/v1`.
- Nessuna modifica al modello User (già presente).

---

## 3. Endpoint creati

| Metodo | Endpoint | Descrizione |
|--------|----------|-------------|
| POST | `/api/v1/auth/register` | Registrazione utente |
| POST | `/api/v1/auth/login` | Login → JWT (access + refresh) |
| GET | `/api/v1/auth/me` | Profilo utente corrente |
| PUT | `/api/v1/auth/me` | Modifica profilo |
| POST | `/api/v1/auth/refresh` | Refresh token → nuovi token |

---

## 4. File creati/modificati (percorsi completi)

| File | Azione |
|------|--------|
| `backend/app/core/__init__.py` | Creato |
| `backend/app/core/security.py` | Creato |
| `backend/app/schemas/__init__.py` | Creato |
| `backend/app/schemas/user.py` | Creato |
| `backend/app/dependencies.py` | Creato |
| `backend/app/api/__init__.py` | Creato |
| `backend/app/api/v1/__init__.py` | Creato |
| `backend/app/api/v1/auth.py` | Creato |
| `backend/app/main.py` | Modificato (include_router auth) |
| `reports/TASK_05_REPORT.md` | Creato |

---

## 5. Come testare

```bash
# Registrazione
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email": "test@test.com", "username": "testuser", "password": "test1234"}'

# Login
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "test@test.com", "password": "test1234"}'

# Profilo (sostituire TOKEN con access_token ricevuto)
curl http://localhost:8000/api/v1/auth/me -H "Authorization: Bearer TOKEN"

# Modifica profilo
curl -X PUT http://localhost:8000/api/v1/auth/me \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"full_name": "Test User"}'

# Refresh
curl -X POST http://localhost:8000/api/v1/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{"refresh_token": "REFRESH_TOKEN"}'
```

---

## 6. Verifica eseguita

- **Register**: 201 con UserResponse; 400 se email/username già usati.
- **Login**: 200 con access_token, refresh_token, token_type.
- **GET /me**: 200 con profilo (id, email, username, full_name, …); 401 senza token.
- **PUT /me**: 200 con profilo aggiornato (es. full_name).
- **Refresh**: 200 con nuovi access_token e refresh_token; 401 con token non valido.

---

## 7. Note implementative

- Email validata in UserRegister con `@` e `.` nel dominio (senza dipendenza email-validator).
- JWT secret e scadenza letti da `app.config.settings` (JWT_SECRET, JWT_EXPIRE_MINUTES).
- Per route protette usare `Depends(get_current_user)` e tipizzare con `User`.

---

## 8. Prossimo task

**TASK 06 — Leagues & Fantasy Teams API**: creazione leghe, squadre, join con invite_code, calendario, classifiche, formazioni.
