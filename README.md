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

## Pubblicare su GitHub (push)

Se `git push origin main` fallisce con **401 Unauthorized**:
1. Il **Personal Access Token (PAT)** è scaduto, revocato o senza permesso `repo`.
2. Crea un nuovo token: GitHub → Settings → Developer settings → Personal access tokens → Generate new token (classic), spunta **repo**.
3. Push con token (sostituisci `TUO_TOKEN`):
   ```bash
   git push https://TUO_TOKEN@github.com/axiona25/Fantastar.git main
   ```
   Oppure configura il credential helper e usa `git push origin main` (Git chiederà user + token come password).

**Nota:** Il repo è ~360 MB (molte foto in `backend/static/photos/`). Il primo push può richiedere diversi minuti; in caso di timeout considera di escludere quelle cartelle dal repo (es. con `.gitignore`) e metterle su storage esterno.
