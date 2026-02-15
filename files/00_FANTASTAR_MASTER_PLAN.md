# ⚽ FANTASTAR — Master Plan Progetto

## Informazioni Progetto

| Campo | Valore |
|-------|--------|
| **Nome progetto** | FANTASTAR |
| **Percorso** | `/Users/r.amoroso/Documents/Cursor/FANTASTAR` |
| **Autore** | Raffaele Amoroso |
| **Data inizio** | 13 Febbraio 2026 |
| **Tipo** | App Fantacalcio Event-Based Serie A |

---

## Stack Tecnologico

| Componente | Tecnologia |
|------------|-----------|
| **Backend** | Python (FastAPI) |
| **Database** | PostgreSQL |
| **Frontend Mobile** | Flutter |
| **Frontend Web** | React (NextJS) oppure Flutter Web |
| **ORM** | SQLAlchemy + Alembic (migrations) |
| **Cache** | Redis |
| **Task Queue** | Celery / APScheduler |
| **WebSocket** | FastAPI WebSocket |
| **Containerizzazione** | Docker + Docker Compose |

---

## Fonti Dati (testate e validate il 13/02/2026)

| Fonte | Uso | Costo | Risultato Test |
|-------|-----|-------|----------------|
| **Football-Data.org** | Dati primari: classifica, rose, partite, marcatori | Gratis (10 req/min) | 🟢 100% — 20 squadre, 656 giocatori, 239 partite |
| **TheSportsDB** | Media: foto cutout, stemmi, divise | Gratis (key "3") | 🟢 100% — 100% foto cutout, stemmi OK |
| **BZZoiro Sports** | Statistiche avanzate: xG, xA, passaggi, tackle | Gratis (no rate limit) | 🟡 75% — 171k stat, predizioni ML |
| **RSS Feeds** | News calcio italiano | Gratis | 🟢 80% — Football Italia, GIFN, Cult of Calcio |

---

## Struttura Cartelle Progetto

```
/Users/r.amoroso/Documents/Cursor/FANTASTAR/
│
├── README.md                          # Panoramica progetto
├── docker-compose.yml                 # Orchestrazione servizi
├── .env.example                       # Template variabili ambiente
├── .gitignore
│
├── backend/                           # 🐍 Python FastAPI
│   ├── app/
│   │   ├── __init__.py
│   │   ├── main.py                    # Entry point FastAPI
│   │   ├── config.py                  # Configurazione e settings
│   │   ├── dependencies.py            # Dependency injection
│   │   │
│   │   ├── api/                       # Router API
│   │   │   ├── __init__.py
│   │   │   ├── v1/
│   │   │   │   ├── __init__.py
│   │   │   │   ├── auth.py            # Autenticazione
│   │   │   │   ├── leagues.py         # Leghe fantasy
│   │   │   │   ├── teams.py           # Squadre fantasy
│   │   │   │   ├── players.py         # Giocatori
│   │   │   │   ├── matches.py         # Partite e risultati
│   │   │   │   ├── scores.py          # Punteggi fantasy
│   │   │   │   ├── auctions.py        # Asta fantacalcio
│   │   │   │   ├── news.py            # News RSS
│   │   │   │   ├── standings.py       # Classifiche
│   │   │   │   └── live.py            # WebSocket live
│   │   │   └── websocket.py           # WebSocket handler
│   │   │
│   │   ├── models/                    # SQLAlchemy Models
│   │   │   ├── __init__.py
│   │   │   ├── user.py
│   │   │   ├── league.py
│   │   │   ├── fantasy_team.py
│   │   │   ├── player.py
│   │   │   ├── real_team.py
│   │   │   ├── match.py
│   │   │   ├── match_event.py
│   │   │   ├── player_stats.py
│   │   │   ├── fantasy_lineup.py
│   │   │   ├── fantasy_score.py
│   │   │   ├── auction.py
│   │   │   └── transfer.py
│   │   │
│   │   ├── schemas/                   # Pydantic Schemas
│   │   │   ├── __init__.py
│   │   │   ├── user.py
│   │   │   ├── league.py
│   │   │   ├── player.py
│   │   │   ├── match.py
│   │   │   ├── score.py
│   │   │   └── auction.py
│   │   │
│   │   ├── services/                  # Business Logic
│   │   │   ├── __init__.py
│   │   │   ├── scoring_engine.py      # ⭐ Motore punteggi event-based
│   │   │   ├── auction_service.py     # Gestione asta
│   │   │   ├── lineup_service.py      # Gestione formazioni
│   │   │   ├── league_service.py      # Gestione leghe fantasy
│   │   │   ├── transfer_service.py    # Mercato riparazione
│   │   │   └── notification_service.py
│   │   │
│   │   ├── data_providers/            # 📡 Connettori API esterne
│   │   │   ├── __init__.py
│   │   │   ├── base_provider.py       # Classe base astratta
│   │   │   ├── football_data_org.py   # Football-Data.org
│   │   │   ├── thesportsdb.py         # TheSportsDB (media)
│   │   │   ├── bzzoiro.py             # BZZoiro (stat avanzate)
│   │   │   ├── rss_news.py            # RSS feeds parser
│   │   │   └── sync_manager.py        # Orchestratore sync
│   │   │
│   │   ├── tasks/                     # Background Tasks
│   │   │   ├── __init__.py
│   │   │   ├── sync_matches.py        # Sync partite (polling)
│   │   │   ├── sync_standings.py      # Sync classifica
│   │   │   ├── sync_players.py        # Sync rose giocatori
│   │   │   ├── sync_media.py          # Download foto/stemmi
│   │   │   ├── sync_stats.py          # Sync statistiche avanzate
│   │   │   ├── calculate_scores.py    # Calcolo punteggi
│   │   │   └── sync_news.py           # Sync news RSS
│   │   │
│   │   └── utils/
│   │       ├── __init__.py
│   │       ├── cache.py               # Redis cache helper
│   │       ├── media.py               # Gestione immagini
│   │       └── avatar.py              # Generatore avatar
│   │
│   ├── alembic/                       # Database migrations
│   │   ├── alembic.ini
│   │   └── versions/
│   │
│   ├── tests/                         # Test
│   │   ├── test_scoring_engine.py
│   │   ├── test_data_providers.py
│   │   └── test_api.py
│   │
│   ├── scripts/                       # Script utility
│   │   ├── seed_database.py           # Popola DB iniziale
│   │   ├── download_media.py          # Bulk download media
│   │   └── init_season.py             # Setup inizio stagione
│   │
│   ├── requirements.txt
│   ├── Dockerfile
│   └── pyproject.toml
│
├── frontend_mobile/                   # 📱 Flutter Mobile
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app/
│   │   │   ├── routes.dart
│   │   │   └── theme.dart
│   │   ├── models/
│   │   ├── services/
│   │   ├── providers/
│   │   ├── screens/
│   │   │   ├── home/
│   │   │   ├── league/
│   │   │   ├── team/
│   │   │   ├── auction/
│   │   │   ├── lineup/
│   │   │   ├── live/
│   │   │   ├── standings/
│   │   │   ├── player/
│   │   │   └── news/
│   │   └── widgets/
│   ├── pubspec.yaml
│   └── README.md
│
├── frontend_web/                      # 🌐 React Web
│   ├── src/
│   │   ├── components/
│   │   ├── pages/
│   │   ├── hooks/
│   │   ├── services/
│   │   ├── store/
│   │   └── types/
│   ├── package.json
│   └── README.md
│
├── docs/                              # 📚 Documentazione
│   ├── API.md                         # Documentazione API
│   ├── DATABASE.md                    # Schema DB
│   ├── SCORING_RULES.md              # Regole punteggio
│   └── DEPLOYMENT.md                 # Guida deploy
│
├── media/                             # 🖼️ Asset statici
│   ├── team_badges/                   # Stemmi squadre
│   ├── player_photos/                 # Foto giocatori
│   ├── team_jerseys/                  # Divise
│   └── avatars/                       # Avatar generati
│
└── reports/                           # 📋 Report task completati
    ├── TASK_01_REPORT.md
    ├── TASK_02_REPORT.md
    └── ...
```

---

## Regole Punteggio Event-Based

### Punteggio Base (da eventi Football-Data.org)

| Evento | Punti | Ruolo |
|--------|-------|-------|
| Gol segnato | +3.0 | Tutti |
| Gol segnato (difensore) | +5.0 | DIF |
| Gol segnato (centrocampista) | +4.0 | CEN |
| Assist | +1.0 | Tutti |
| Rigore segnato | +3.0 | Tutti |
| Rigore sbagliato | -3.0 | Tutti |
| Cartellino giallo | -0.5 | Tutti |
| Cartellino rosso | -1.0 | Tutti |
| Autogol | -2.0 | Tutti |
| Gol subìto | -1.0 | POR |
| Clean sheet (imbattibilità) | +1.0 | POR, DIF |
| Rigore parato | +3.0 | POR |
| Presenza (entrato in campo) | +1.0 | Tutti |

### Punteggio Avanzato (da BZZoiro quando disponibile)

| Statistica | Punti | Note |
|-----------|-------|------|
| xG > 0.5 senza gol | -0.5 | Occasioni sprecate |
| xA > 0.3 senza assist | -0.25 | Passaggi chiave non concretizzati |
| 3+ passaggi chiave | +0.5 | Creatività |
| 5+ tackle vinti | +0.5 | Solo DIF/CEN |
| 90%+ precisione passaggi (min 30) | +0.5 | Regista |
| Rating SofaScore/BZZoiro >= 8.0 | +1.0 | MVP bonus |

### Conversione Punteggio → Gol Fantasy

- Soglia primo gol: **66 punti** totali formazione
- Gol aggiuntivo ogni: **8 punti** sopra la soglia
- Esempio: 82 punti = 66 + 8 + 8 = **3 gol fantasy**

---

## Piano Task (Ordine di Esecuzione)

### FASE 1: FONDAMENTA (Task 01-04)

| Task | Titolo | Descrizione | Dipendenze |
|------|--------|-------------|------------|
| **01** | Setup Progetto & Struttura | Crea cartella FANTASTAR, struttura, Docker, .env | Nessuna |
| **02** | Database Schema & Models | PostgreSQL schema, SQLAlchemy models, Alembic migrations | Task 01 |
| **03** | Data Providers | Connettori API esterne (Football-Data.org, TheSportsDB, BZZoiro, RSS) | Task 01 |
| **04** | Sync Engine & Background Tasks | Scheduler sync dati, download media, polling partite | Task 02, 03 |

### FASE 2: BACKEND API (Task 05-09)

| Task | Titolo | Descrizione | Dipendenze |
|------|--------|-------------|------------|
| **05** | Auth & Users API | Registrazione, login JWT, profilo utente | Task 02 |
| **06** | Leagues & Fantasy Teams API | CRUD leghe fantasy, squadre, inviti | Task 05 |
| **07** | Scoring Engine | ⭐ Motore calcolo punteggi event-based | Task 02, 04 |
| **08** | Auction System | Sistema asta con budget, offerte, assegnazioni | Task 06 |
| **09** | Live WebSocket | Real-time score updates via WebSocket | Task 07 |

### FASE 3: FRONTEND (Task 10-14)

| Task | Titolo | Descrizione | Dipendenze |
|------|--------|-------------|------------|
| **10** | Flutter: Setup & Navigation | Struttura app, routing, tema, modelli | Task 05 |
| **11** | Flutter: Home & Classifiche | Dashboard, classifica Serie A, classifica fantasy | Task 10 |
| **12** | Flutter: Gestione Squadra | Rosa, formazione, scheda giocatore | Task 10 |
| **13** | Flutter: Asta & Mercato | Interfaccia asta live, scambi | Task 08, 10 |
| **14** | Flutter: Live Match | Schermata partita live con punteggi real-time | Task 09, 10 |

### FASE 4: WEB & POLISH (Task 15-17)

| Task | Titolo | Descrizione | Dipendenze |
|------|--------|-------------|------------|
| **15** | React Web: Setup & Core | Setup React/Next, componenti core, API client | Task 05-09 |
| **16** | React Web: Dashboard & Live | Dashboard web, live scoring, classifiche | Task 15 |
| **17** | News Feed & Notifiche | Sezione news, push notification | Task 04, 14 |

---

## Variabili d'Ambiente (.env)

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

---

## Regola Report

**Alla fine di ogni Task, Cursor DEVE generare un file:**

```
/reports/TASK_XX_REPORT.md
```

Il report DEVE contenere:
1. **Titolo e data completamento**
2. **Obiettivo del task**
3. **Cosa è stato fatto** (elenco dettagliato)
4. **File creati/modificati** (con percorsi)
5. **Schema DB** (se modificato)
6. **Endpoint API** (se creati)
7. **Come testare** (comandi per verificare)
8. **Problemi noti / TODO**
9. **Screenshot/Output** (se rilevante)
10. **Prossimo task** (cosa fare dopo)
