# 🎯 ISTRUZIONI PER CURSOR — FANTASTAR

## LEGGI QUESTO PRIMA DI TUTTO

Questo progetto è diviso in **17 task sequenziali**. Devi completarli **uno alla volta, in ordine**.

## Percorso progetto
```
/Users/r.amoroso/Documents/Cursor/FANTASTAR
```

## File da leggere per ogni task

| Fase | File | Task |
|------|------|------|
| **Master Plan** | `00_FANTASTAR_MASTER_PLAN.md` | Overview completo, schema, regole, stack |
| **Task 01** | `TASK_01_SETUP_PROGETTO.md` | Setup progetto, Docker, struttura |
| **Task 02** | `TASK_02_DATABASE_SCHEMA.md` | Database PostgreSQL, Models, Migrations |
| **Task 03** | `TASK_03_DATA_PROVIDERS.md` | Connettori API esterne |
| **Task 04-09** | `TASK_04_TO_09_BACKEND.md` | Sync, Auth, Leagues, Scoring, Auction, WebSocket |
| **Task 10-17** | `TASK_10_TO_17_FRONTEND.md` | Flutter Mobile, React Web, News |

## Regole fondamentali

### 1. Un task alla volta
- Completa un task PRIMA di passare al successivo
- Rispetta le dipendenze indicate in ogni task

### 2. Report obbligatorio
Alla fine di OGNI task, crea un file report in:
```
/Users/r.amoroso/Documents/Cursor/FANTASTAR/reports/TASK_XX_REPORT.md
```

Il report DEVE contenere:
1. Titolo e data completamento
2. Obiettivo del task
3. Cosa è stato fatto (elenco dettagliato)
4. File creati/modificati (con percorsi completi)
5. Come testare (comandi esatti)
6. Problemi noti / TODO
7. Prossimo task

### 3. Variabili d'ambiente
Le API keys sono già pronte (metti nel .env):
```
FOOTBALL_DATA_ORG_KEY=82561b77e24f4bf3aa421051b0173864
THESPORTSDB_KEY=3
BZZOIRO_KEY=28c78de965b7d0e0fdfb80b4782c10f5d0ab3434
```

### 4. Docker
Usa Docker Compose per PostgreSQL e Redis:
```bash
docker-compose up -d
```

### 5. Test
Ogni componente deve avere test. Lancia con:
```bash
cd backend && pytest tests/ -v
```

## Come iniziare

1. Leggi `00_FANTASTAR_MASTER_PLAN.md` per capire il progetto
2. Apri `TASK_01_SETUP_PROGETTO.md`
3. Segui le istruzioni step by step
4. Al termine crea il report
5. Passa al task successivo

## Ordine esecuzione

```
FASE 1 - FONDAMENTA:
  ✅ Task 01: Setup Progetto
  ✅ Task 02: Database
  ✅ Task 03: Data Providers
  ✅ Task 04: Sync Engine

FASE 2 - BACKEND API:
  ✅ Task 05: Auth
  ✅ Task 06: Leagues & Teams
  ✅ Task 07: Scoring Engine ⭐
  ✅ Task 08: Auction
  ✅ Task 09: WebSocket

FASE 3 - FRONTEND MOBILE:
  ✅ Task 10: Flutter Setup
  ✅ Task 11: Home & Classifiche
  ✅ Task 12: Gestione Squadra
  ✅ Task 13: Asta
  ✅ Task 14: Live Match

FASE 4 - WEB & POLISH:
  ✅ Task 15: React Setup
  ✅ Task 16: Dashboard Web
  ✅ Task 17: News & Notifiche
```

Buon lavoro! ⚽🏆
