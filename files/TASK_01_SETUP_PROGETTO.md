# TASK 01 — Setup Progetto & Struttura

## Obiettivo
Creare la struttura del progetto FANTASTAR, configurare Docker, ambiente di sviluppo e dipendenze base.

## Percorso Progetto
```
/Users/r.amoroso/Documents/Cursor/FANTASTAR
```

## Istruzioni per Cursor

### Step 1: Crea la struttura cartelle

```bash
mkdir -p /Users/r.amoroso/Documents/Cursor/FANTASTAR/{backend/app/{api/v1,models,schemas,services,data_providers,tasks,utils},backend/{alembic/versions,tests,scripts},frontend_mobile/lib/{app,models,services,providers,screens/{home,league,team,auction,lineup,live,standings,player,news},widgets},frontend_web/src/{components,pages,hooks,services,store,types},docs,media/{team_badges,player_photos,team_jerseys,avatars},reports}
```

### Step 2: Crea i file Docker

**docker-compose.yml** nella root del progetto:
```yaml
version: '3.8'

services:
  db:
    image: postgres:16
    container_name: fantastar_db
    environment:
      POSTGRES_USER: fantastar
      POSTGRES_PASSWORD: fantastar
      POSTGRES_DB: fantastar
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U fantastar"]
      interval: 5s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: fantastar_redis
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

  backend:
    build: ./backend
    container_name: fantastar_backend
    ports:
      - "8000:8000"
    env_file:
      - .env
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_started
    volumes:
      - ./backend:/app
      - ./media:/app/media
    command: uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

volumes:
  postgres_data:
  redis_data:
```

### Step 3: Backend — Crea requirements.txt

```
# Web Framework
fastapi==0.109.2
uvicorn[standard]==0.27.1
python-multipart==0.0.9

# Database
sqlalchemy==2.0.25
alembic==1.13.1
asyncpg==0.29.0
psycopg2-binary==2.9.9

# Cache
redis==5.0.1

# Auth
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
bcrypt==4.1.2

# HTTP Client
httpx==0.27.0
aiohttp==3.9.3

# Scheduler
apscheduler==3.10.4

# Data
pydantic==2.6.1
pydantic-settings==2.1.0
python-dateutil==2.8.2

# RSS
feedparser==6.0.11

# Images
Pillow==10.2.0

# Utils
python-dotenv==1.0.1

# WebSocket
websockets==12.0

# Test
pytest==8.0.0
pytest-asyncio==0.23.4
httpx==0.27.0
```

### Step 4: Backend — Crea Dockerfile

```dockerfile
FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
```

### Step 5: Backend — Crea app/main.py

```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.config import settings

app = FastAPI(
    title="FANTASTAR API",
    description="API per il fantacalcio event-based Serie A",
    version="0.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # TODO: restringere in produzione
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    return {"app": "FANTASTAR", "status": "running", "version": "0.1.0"}

@app.get("/health")
async def health():
    return {"status": "healthy"}
```

### Step 6: Backend — Crea app/config.py

```python
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    # App
    APP_NAME: str = "FANTASTAR"
    DEBUG: bool = True
    
    # Database
    DATABASE_URL: str = "postgresql://fantastar:fantastar@localhost:5432/fantastar"
    
    # Redis
    REDIS_URL: str = "redis://localhost:6379/0"
    
    # JWT
    JWT_SECRET: str = "cambiami-in-produzione"
    JWT_ALGORITHM: str = "HS256"
    JWT_EXPIRE_MINUTES: int = 1440
    
    # API Keys
    FOOTBALL_DATA_ORG_KEY: str = ""
    THESPORTSDB_KEY: str = "3"
    BZZOIRO_KEY: str = ""
    
    # Serie A
    SERIE_A_SEASON: str = "2025"
    
    class Config:
        env_file = ".env"

settings = Settings()
```

### Step 7: Crea .env.example e .env nella root

```env
# Database
DATABASE_URL=postgresql://fantastar:fantastar@localhost:5432/fantastar

# Redis
REDIS_URL=redis://localhost:6379/0

# API Keys
FOOTBALL_DATA_ORG_KEY=82561b77e24f4bf3aa421051b0173864
THESPORTSDB_KEY=3
BZZOIRO_KEY=28c78de965b7d0e0fdfb80b4782c10f5d0ab3434

# JWT
JWT_SECRET=cambiami-in-produzione
JWT_ALGORITHM=HS256
JWT_EXPIRE_MINUTES=1440

# App
APP_NAME=FANTASTAR
SERIE_A_SEASON=2025
DEBUG=true
```

### Step 8: Crea .gitignore

```
__pycache__/
*.pyc
.env
*.egg-info/
dist/
build/
.venv/
node_modules/
.next/
*.sqlite3
media/player_photos/
media/team_badges/
media/team_jerseys/
media/avatars/
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
```

### Step 9: Crea README.md nella root

```markdown
# ⚽ FANTASTAR

Fantacalcio Event-Based per la Serie A italiana.

## Quick Start

```bash
# Avvia i servizi
docker-compose up -d

# Verifica
curl http://localhost:8000/health
```

## Stack
- **Backend**: Python FastAPI
- **Database**: PostgreSQL
- **Cache**: Redis  
- **Mobile**: Flutter
- **Web**: React
```

### Step 10: Verifica

```bash
cd /Users/r.amoroso/Documents/Cursor/FANTASTAR
docker-compose up -d
curl http://localhost:8000/health
# Deve rispondere: {"status": "healthy"}
```

## Come generare il report

Alla fine, crea il file `/reports/TASK_01_REPORT.md` con:
- Elenco completo file creati
- Conferma che Docker funziona
- Conferma che l'endpoint /health risponde
- Screenshot o output dei test
