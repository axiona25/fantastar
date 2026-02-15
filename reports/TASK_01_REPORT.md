# TASK 01 — Report Setup Progetto & Struttura

**Data completamento:** 13 Febbraio 2026  
**Percorso progetto:** `/Users/r.amoroso/Documents/Cursor/Fantastar`

---

## 1. Obiettivo del task

Creare la struttura del progetto FANTASTAR, configurare Docker (PostgreSQL, Redis, backend), ambiente di sviluppo e dipendenze base.

---

## 2. Cosa è stato fatto

- **Step 1:** Creata la struttura completa delle cartelle (backend con api/v1, models, schemas, services, data_providers, tasks, utils; alembic/versions, tests, scripts; frontend_mobile con screens; frontend_web con src; docs; media con sottocartelle; reports).
- **Step 2:** Creato `docker-compose.yml` con servizi db (PostgreSQL 16), redis (Redis 7-alpine), backend (FastAPI con build da ./backend), healthcheck su db, volumi e dipendenze.
- **Step 3:** Creato `backend/requirements.txt` con FastAPI, uvicorn, SQLAlchemy, Alembic, asyncpg, psycopg2-binary, redis, python-jose, passlib, bcrypt, httpx, aiohttp, APScheduler, pydantic, pydantic-settings, feedparser, Pillow, python-dotenv, websockets, pytest, pytest-asyncio (pytest impostato a >=7,<8 per compatibilità con pytest-asyncio 0.23.4).
- **Step 4:** Creato `backend/Dockerfile` (Python 3.12-slim, install dipendenze, CMD uvicorn).
- **Step 5:** Creato `backend/app/main.py` con FastAPI, CORS, route `/` e `/health`.
- **Step 6:** Creato `backend/app/config.py` con Settings (Pydantic) per APP_NAME, DEBUG, DATABASE_URL, REDIS_URL, JWT_*, API keys, SERIE_A_SEASON; caricamento da `.env`.
- **Step 7:** Creati `.env.example` e `.env` nella root con tutte le variabili (database, Redis, API keys, JWT, app).
- **Step 8:** Creato `.gitignore` (pycache, .env, venv, node_modules, media, flutter).
- **Step 9:** Creato `README.md` nella root con Quick Start e stack.
- **Step 10:** Verifica: `docker-compose up -d --build` eseguito con successo; `curl http://localhost:8000/health` risponde `{"status":"healthy"}`; `curl http://localhost:8000/` risponde con app/status/version.
- Aggiunto `backend/app/__init__.py` per package Python.
- Rimosso attributo obsoleto `version` da `docker-compose.yml`.

---

## 3. File creati/modificati (percorsi completi)

| File | Azione |
|------|--------|
| `/Users/r.amoroso/Documents/Cursor/Fantastar/docker-compose.yml` | Creato |
| `/Users/r.amoroso/Documents/Cursor/Fantastar/backend/requirements.txt` | Creato (pytest 7.x per compatibilità) |
| `/Users/r.amoroso/Documents/Cursor/Fantastar/backend/Dockerfile` | Creato |
| `/Users/r.amoroso/Documents/Cursor/Fantastar/backend/app/__init__.py` | Creato |
| `/Users/r.amoroso/Documents/Cursor/Fantastar/backend/app/main.py` | Creato |
| `/Users/r.amoroso/Documents/Cursor/Fantastar/backend/app/config.py` | Creato |
| `/Users/r.amoroso/Documents/Cursor/Fantastar/.env.example` | Creato |
| `/Users/r.amoroso/Documents/Cursor/Fantastar/.env` | Creato |
| `/Users/r.amoroso/Documents/Cursor/Fantastar/.gitignore` | Creato |
| `/Users/r.amoroso/Documents/Cursor/Fantastar/README.md` | Creato |
| `/Users/r.amoroso/Documents/Cursor/Fantastar/reports/TASK_01_REPORT.md` | Creato |
| Struttura cartelle (backend/app/..., frontend_mobile/..., frontend_web/..., docs, media/..., reports) | Creata |

---

## 4. Come testare

Esegui un comando per volta (evita di incollare commenti insieme ai comandi):

```bash
cd /Users/r.amoroso/Documents/Cursor/Fantastar
docker-compose up -d
curl http://localhost:8000/health
curl http://localhost:8000/
```

Risposte attese: primo `curl` → `{"status":"healthy"}`; secondo `curl` → `{"app":"FANTASTAR","status":"running","version":"0.1.0"}` (vedi sezione 5).

---

## 5. Output verifica

```
{"status":"healthy"}
{"app":"FANTASTAR","status":"running","version":"0.1.0"}
```

Docker: container `fantastar_db`, `fantastar_redis`, `fantastar_backend` avviati correttamente.

---

## 6. Problemi noti / TODO

- **pytest:** Nel task era indicato `pytest==8.0.0`; è stato usato `pytest>=7.0.0,<8` per compatibilità con `pytest-asyncio==0.23.4` (richiede pytest<8). In futuro si può aggiornare a pytest-asyncio che supporti pytest 8.
- CORS è impostato su `allow_origins=["*"]`; da restringere in produzione.
- Percorso effettivo del progetto usato: `Fantastar` (come da workspace); nei file di istruzioni è indicato `FANTASTAR`.

---

## 7. Prossimo task

**TASK 02 — Database Schema & Models** (`TASK_02_DATABASE_SCHEMA.md`): schema PostgreSQL, modelli SQLAlchemy, migrazioni Alembic.
