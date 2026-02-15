# TASK 02 — Database Schema & Models

## Obiettivo
Creare lo schema completo del database PostgreSQL con SQLAlchemy models e migrazioni Alembic.

## Dipendenze
- Task 01 completato (Docker + PostgreSQL running)

## Schema Database

### Diagramma Entità

```
┌─────────────┐     ┌──────────────┐     ┌─────────────────┐
│    users     │────<│ fantasy_teams │>────│  fantasy_leagues │
└─────────────┘     └──────────────┘     └─────────────────┘
                           │
                    ┌──────┴──────┐
                    │             │
              ┌─────┴─────┐ ┌────┴──────────┐
              │  lineups  │ │ auction_bids   │
              └─────┬─────┘ └───────────────┘
                    │
              ┌─────┴─────┐
              │  players   │>───── real_teams
              └─────┬─────┘
                    │
        ┌───────────┼───────────┐
        │           │           │
  ┌─────┴─────┐ ┌──┴────────┐ ┌┴────────────┐
  │player_stats│ │match_events│ │fantasy_scores│
  └───────────┘ └───────────┘ └──────────────┘
                      │
                ┌─────┴─────┐
                │  matches   │
                └───────────┘
```

### Tabelle

#### 1. users
```sql
CREATE TABLE users (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email           VARCHAR(255) UNIQUE NOT NULL,
    username        VARCHAR(50) UNIQUE NOT NULL,
    hashed_password VARCHAR(255) NOT NULL,
    full_name       VARCHAR(100),
    avatar_url      VARCHAR(500),
    is_active       BOOLEAN DEFAULT TRUE,
    is_admin        BOOLEAN DEFAULT FALSE,
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW()
);
```

#### 2. real_teams (Squadre Serie A reali)
```sql
CREATE TABLE real_teams (
    id              SERIAL PRIMARY KEY,
    external_id     INTEGER UNIQUE,           -- ID da Football-Data.org
    name            VARCHAR(100) NOT NULL,
    short_name      VARCHAR(10),              -- Es: "INT", "JUV", "MIL"
    tla             VARCHAR(5),               -- Three Letter Abbreviation
    crest_url       VARCHAR(500),             -- URL stemma originale
    crest_local     VARCHAR(255),             -- Path locale stemma scaricato
    jersey_url      VARCHAR(500),             -- URL divisa
    primary_color   VARCHAR(7),               -- Es: "#003DA5"
    secondary_color VARCHAR(7),
    stadium         VARCHAR(100),
    city            VARCHAR(50),
    founded_year    INTEGER,
    thesportsdb_id  VARCHAR(20),              -- ID su TheSportsDB
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW()
);
```

#### 3. players (Giocatori reali)
```sql
CREATE TABLE players (
    id              SERIAL PRIMARY KEY,
    external_id     INTEGER UNIQUE,           -- ID da Football-Data.org
    real_team_id    INTEGER REFERENCES real_teams(id),
    name            VARCHAR(100) NOT NULL,
    first_name      VARCHAR(50),
    last_name       VARCHAR(50),
    position        VARCHAR(3) NOT NULL,      -- POR, DIF, CEN, ATT
    date_of_birth   DATE,
    nationality     VARCHAR(50),
    shirt_number    INTEGER,
    photo_url       VARCHAR(500),             -- URL foto originale
    photo_local     VARCHAR(255),             -- Path locale foto scaricata
    cutout_url      VARCHAR(500),             -- URL cutout TheSportsDB
    cutout_local    VARCHAR(255),             -- Path locale cutout
    thesportsdb_id  VARCHAR(20),
    bzzoiro_id      VARCHAR(20),
    initial_price   DECIMAL(10,2) DEFAULT 1,  -- Prezzo base per asta
    is_active       BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_players_team ON players(real_team_id);
CREATE INDEX idx_players_position ON players(position);
```

#### 4. matches (Partite Serie A)
```sql
CREATE TABLE matches (
    id              SERIAL PRIMARY KEY,
    external_id     INTEGER UNIQUE,           -- ID da Football-Data.org
    matchday        INTEGER NOT NULL,          -- Giornata di campionato
    home_team_id    INTEGER REFERENCES real_teams(id),
    away_team_id    INTEGER REFERENCES real_teams(id),
    home_score      INTEGER,
    away_score      INTEGER,
    status          VARCHAR(20) DEFAULT 'SCHEDULED',  
                    -- SCHEDULED, TIMED, IN_PLAY, PAUSED, FINISHED, 
                    -- POSTPONED, CANCELLED, SUSPENDED
    kick_off        TIMESTAMP,
    minute          INTEGER,                  -- Minuto corrente (se live)
    season          VARCHAR(10) DEFAULT '2025',
    last_synced     TIMESTAMP,
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_matches_matchday ON matches(matchday);
CREATE INDEX idx_matches_status ON matches(status);
CREATE INDEX idx_matches_kick_off ON matches(kick_off);
```

#### 5. match_events (Eventi partita: gol, cartellini, sostituzioni)
```sql
CREATE TABLE match_events (
    id              SERIAL PRIMARY KEY,
    match_id        INTEGER REFERENCES matches(id) ON DELETE CASCADE,
    player_id       INTEGER REFERENCES players(id),
    assist_player_id INTEGER REFERENCES players(id),  -- Chi ha fatto assist
    team_id         INTEGER REFERENCES real_teams(id),
    event_type      VARCHAR(30) NOT NULL,
                    -- GOAL, OWN_GOAL, PENALTY_SCORED, PENALTY_MISSED,
                    -- YELLOW_CARD, RED_CARD, SECOND_YELLOW,
                    -- SUBSTITUTION_IN, SUBSTITUTION_OUT,
                    -- PENALTY_SAVED, VAR_DECISION
    minute          INTEGER NOT NULL,
    extra_minute    INTEGER,                  -- Per tempi supplementari
    detail          VARCHAR(100),             -- Dettagli aggiuntivi
    created_at      TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_match_events_match ON match_events(match_id);
CREATE INDEX idx_match_events_player ON match_events(player_id);
CREATE INDEX idx_match_events_type ON match_events(event_type);
```

#### 6. player_stats (Statistiche avanzate per partita — da BZZoiro)
```sql
CREATE TABLE player_stats (
    id              SERIAL PRIMARY KEY,
    player_id       INTEGER REFERENCES players(id),
    match_id        INTEGER REFERENCES matches(id),
    minutes_played  INTEGER DEFAULT 0,
    rating          DECIMAL(3,1),             -- Rating 0-10
    goals           INTEGER DEFAULT 0,
    assists         INTEGER DEFAULT 0,
    expected_goals  DECIMAL(4,2),             -- xG
    expected_assists DECIMAL(4,2),            -- xA
    total_shots     INTEGER DEFAULT 0,
    shots_on_target INTEGER DEFAULT 0,
    total_passes    INTEGER DEFAULT 0,
    accurate_passes INTEGER DEFAULT 0,
    key_passes      INTEGER DEFAULT 0,
    total_crosses   INTEGER DEFAULT 0,
    accurate_crosses INTEGER DEFAULT 0,
    total_long_balls INTEGER DEFAULT 0,
    accurate_long_balls INTEGER DEFAULT 0,
    total_tackles   INTEGER DEFAULT 0,
    tackles_won     INTEGER DEFAULT 0,
    interceptions   INTEGER DEFAULT 0,
    clearances      INTEGER DEFAULT 0,
    saves           INTEGER DEFAULT 0,        -- Solo portieri
    clean_sheet     BOOLEAN DEFAULT FALSE,
    source          VARCHAR(20) DEFAULT 'bzzoiro',  -- Fonte dati
    created_at      TIMESTAMP DEFAULT NOW()
);

CREATE UNIQUE INDEX idx_player_stats_unique ON player_stats(player_id, match_id);
CREATE INDEX idx_player_stats_match ON player_stats(match_id);
```

#### 7. fantasy_leagues (Leghe fantacalcio)
```sql
CREATE TABLE fantasy_leagues (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(100) NOT NULL,
    admin_user_id   UUID REFERENCES users(id),
    invite_code     VARCHAR(20) UNIQUE,
    max_teams       INTEGER DEFAULT 10,
    budget          DECIMAL(10,2) DEFAULT 500,
    scoring_type    VARCHAR(20) DEFAULT 'EVENT_BASED',  -- EVENT_BASED o CLASSIC
    status          VARCHAR(20) DEFAULT 'DRAFT',
                    -- DRAFT, AUCTION, ACTIVE, COMPLETED
    season          VARCHAR(10) DEFAULT '2025',
    goal_threshold  DECIMAL(5,1) DEFAULT 66,    -- Soglia primo gol fantasy
    goal_step       DECIMAL(5,1) DEFAULT 8,     -- Punti per gol aggiuntivo
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW()
);
```

#### 8. fantasy_teams (Squadre fantasy)
```sql
CREATE TABLE fantasy_teams (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    league_id       UUID REFERENCES fantasy_leagues(id) ON DELETE CASCADE,
    user_id         UUID REFERENCES users(id),
    name            VARCHAR(100) NOT NULL,
    logo_url        VARCHAR(500),
    budget_remaining DECIMAL(10,2) DEFAULT 500,
    total_points    INTEGER DEFAULT 0,
    wins            INTEGER DEFAULT 0,
    draws           INTEGER DEFAULT 0,
    losses          INTEGER DEFAULT 0,
    goals_for       INTEGER DEFAULT 0,
    goals_against   INTEGER DEFAULT 0,
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(league_id, user_id)
);
```

#### 9. fantasy_rosters (Rosa giocatori di ogni fantasquadra)
```sql
CREATE TABLE fantasy_rosters (
    id              SERIAL PRIMARY KEY,
    fantasy_team_id UUID REFERENCES fantasy_teams(id) ON DELETE CASCADE,
    player_id       INTEGER REFERENCES players(id),
    purchase_price  DECIMAL(10,2),
    purchased_at    TIMESTAMP DEFAULT NOW(),
    is_active       BOOLEAN DEFAULT TRUE,     -- FALSE se venduto/scambiato
    
    UNIQUE(fantasy_team_id, player_id)
);

CREATE INDEX idx_roster_team ON fantasy_rosters(fantasy_team_id);
```

#### 10. fantasy_lineups (Formazione schierata per giornata)
```sql
CREATE TABLE fantasy_lineups (
    id              SERIAL PRIMARY KEY,
    fantasy_team_id UUID REFERENCES fantasy_teams(id) ON DELETE CASCADE,
    matchday        INTEGER NOT NULL,
    player_id       INTEGER REFERENCES players(id),
    position_slot   VARCHAR(10) NOT NULL,     -- POR, DIF1, DIF2, CEN1, ATT1...
    is_starter      BOOLEAN DEFAULT TRUE,     -- Titolare o panchina
    bench_order     INTEGER,                  -- Ordine subentro panchina (1, 2, 3...)
    formation       VARCHAR(10),              -- Es: "3-4-3", "4-3-3"
    created_at      TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(fantasy_team_id, matchday, player_id)
);

CREATE INDEX idx_lineup_team_matchday ON fantasy_lineups(fantasy_team_id, matchday);
```

#### 11. fantasy_scores (Punteggi fantasy per giornata)
```sql
CREATE TABLE fantasy_scores (
    id              SERIAL PRIMARY KEY,
    fantasy_team_id UUID REFERENCES fantasy_teams(id) ON DELETE CASCADE,
    matchday        INTEGER NOT NULL,
    total_score     DECIMAL(6,2) DEFAULT 0,   -- Punteggio totale formazione
    fantasy_goals   INTEGER DEFAULT 0,         -- Gol fantasy calcolati
    opponent_id     UUID REFERENCES fantasy_teams(id),
    opponent_score  DECIMAL(6,2),
    opponent_goals  INTEGER,
    result          VARCHAR(1),                -- W, D, L
    points_earned   INTEGER,                   -- 3, 1, 0
    detail_json     JSONB,                     -- Dettaglio punteggio per giocatore
    calculated_at   TIMESTAMP,
    
    UNIQUE(fantasy_team_id, matchday)
);

CREATE INDEX idx_scores_matchday ON fantasy_scores(matchday);
```

#### 12. fantasy_player_scores (Punteggio singolo giocatore per giornata)
```sql
CREATE TABLE fantasy_player_scores (
    id              SERIAL PRIMARY KEY,
    fantasy_team_id UUID REFERENCES fantasy_teams(id) ON DELETE CASCADE,
    player_id       INTEGER REFERENCES players(id),
    match_id        INTEGER REFERENCES matches(id),
    matchday        INTEGER NOT NULL,
    base_score      DECIMAL(5,2) DEFAULT 0,    -- Punteggio da eventi base
    advanced_score  DECIMAL(5,2) DEFAULT 0,    -- Punteggio da stat avanzate
    total_score     DECIMAL(5,2) DEFAULT 0,    -- Totale
    is_starter      BOOLEAN DEFAULT TRUE,
    was_subbed_in   BOOLEAN DEFAULT FALSE,     -- Subentrato da panchina
    events_json     JSONB,                     -- Dettaglio eventi che hanno generato punti
    calculated_at   TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(fantasy_team_id, player_id, matchday)
);
```

#### 13. auction_bids (Offerte asta)
```sql
CREATE TABLE auction_bids (
    id              SERIAL PRIMARY KEY,
    league_id       UUID REFERENCES fantasy_leagues(id) ON DELETE CASCADE,
    fantasy_team_id UUID REFERENCES fantasy_teams(id),
    player_id       INTEGER REFERENCES players(id),
    amount          DECIMAL(10,2) NOT NULL,
    status          VARCHAR(20) DEFAULT 'PENDING',
                    -- PENDING, WON, OUTBID, CANCELLED
    round_number    INTEGER,
    created_at      TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_bids_league ON auction_bids(league_id);
CREATE INDEX idx_bids_player ON auction_bids(player_id);
```

#### 14. transfers (Scambi e mercato riparazione)
```sql
CREATE TABLE transfers (
    id              SERIAL PRIMARY KEY,
    league_id       UUID REFERENCES fantasy_leagues(id),
    from_team_id    UUID REFERENCES fantasy_teams(id),
    to_team_id      UUID REFERENCES fantasy_teams(id),
    player_id       INTEGER REFERENCES players(id),
    transfer_type   VARCHAR(20) NOT NULL,      -- TRADE, FREE_AGENT, RELEASE
    price           DECIMAL(10,2),
    status          VARCHAR(20) DEFAULT 'PENDING',
                    -- PENDING, ACCEPTED, REJECTED, COMPLETED
    created_at      TIMESTAMP DEFAULT NOW()
);
```

#### 15. fantasy_calendar (Calendario partite fantasy)
```sql
CREATE TABLE fantasy_calendar (
    id              SERIAL PRIMARY KEY,
    league_id       UUID REFERENCES fantasy_leagues(id) ON DELETE CASCADE,
    matchday        INTEGER NOT NULL,
    home_team_id    UUID REFERENCES fantasy_teams(id),
    away_team_id    UUID REFERENCES fantasy_teams(id),
    
    UNIQUE(league_id, matchday, home_team_id)
);
```

#### 16. news_articles (Cache news RSS)
```sql
CREATE TABLE news_articles (
    id              SERIAL PRIMARY KEY,
    title           VARCHAR(500) NOT NULL,
    summary         TEXT,
    url             VARCHAR(1000) UNIQUE,
    source          VARCHAR(100),              -- "Football Italia", "GIFN" etc
    image_url       VARCHAR(1000),
    published_at    TIMESTAMP,
    fetched_at      TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_news_published ON news_articles(published_at DESC);
CREATE INDEX idx_news_source ON news_articles(source);
```

## Istruzioni per Cursor

### Step 1: Crea tutti i SQLAlchemy models in `backend/app/models/`
Un file per tabella, più un `__init__.py` che importa tutto.

### Step 2: Crea `backend/app/database.py`
```python
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker, declarative_base
from app.config import settings

# Converti URL per async
ASYNC_DATABASE_URL = settings.DATABASE_URL.replace("postgresql://", "postgresql+asyncpg://")

engine = create_async_engine(ASYNC_DATABASE_URL, echo=settings.DEBUG)
AsyncSessionLocal = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
Base = declarative_base()

async def get_db():
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()
```

### Step 3: Configura Alembic
```bash
cd backend
alembic init alembic
```
Modifica `alembic/env.py` per usare i models e il database URL dal config.

### Step 4: Genera e applica la prima migrazione
```bash
alembic revision --autogenerate -m "initial_schema"
alembic upgrade head
```

### Step 5: Crea script `scripts/seed_database.py`
Che popola le 20 squadre di Serie A con dati base (nomi, abbreviazioni, colori).

### Verifica
```bash
docker-compose exec db psql -U fantastar -c "\dt"
# Deve mostrare tutte le 16 tabelle
```

## Report
Genera `/reports/TASK_02_REPORT.md` con schema creato, models, e conferma migrazione.
