# TASK 10 — Flutter: Setup & Navigation

## Obiettivo
Creare la struttura dell'app Flutter con navigazione, tema, modelli e servizi API.

## Dipendenze
- Task 05 (Auth API funzionante)

## Istruzioni

### Step 1: Crea progetto Flutter
```bash
cd /Users/r.amoroso/Documents/Cursor/FANTASTAR
flutter create --org com.fantastar frontend_mobile
```

### Step 2: pubspec.yaml — Dipendenze
```yaml
dependencies:
  flutter:
    sdk: flutter
  # State management
  provider: ^6.1.1
  # HTTP
  dio: ^5.4.0
  # Storage locale
  shared_preferences: ^2.2.2
  # WebSocket
  web_socket_channel: ^2.4.0
  # Navigation
  go_router: ^13.0.0
  # UI
  cached_network_image: ^3.3.1
  shimmer: ^3.0.0
  pull_to_refresh: ^2.0.0
  # Charts
  fl_chart: ^0.66.0
  # Utils
  intl: ^0.19.0
  timeago: ^3.6.1
  json_annotation: ^4.8.1
  freezed_annotation: ^2.4.1

dev_dependencies:
  build_runner: ^2.4.8
  json_serializable: ^6.7.1
  freezed: ^2.4.6
```

### Step 3: Struttura cartelle
```
lib/
├── main.dart
├── app/
│   ├── routes.dart          # GoRouter config
│   ├── theme.dart           # Tema FANTASTAR
│   └── constants.dart       # Colori, URL API
├── models/                  # Data classes (freezed)
│   ├── user.dart
│   ├── player.dart
│   ├── real_team.dart
│   ├── match.dart
│   ├── fantasy_league.dart
│   ├── fantasy_team.dart
│   ├── lineup.dart
│   └── news.dart
├── services/                # API client
│   ├── api_client.dart      # Dio HTTP client con JWT
│   ├── auth_service.dart
│   ├── league_service.dart
│   ├── player_service.dart
│   ├── match_service.dart
│   └── websocket_service.dart
├── providers/               # State management
│   ├── auth_provider.dart
│   ├── league_provider.dart
│   ├── live_provider.dart
│   └── theme_provider.dart
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── home/
│   │   └── home_screen.dart
│   ├── league/
│   ├── team/
│   ├── auction/
│   ├── lineup/
│   ├── live/
│   ├── standings/
│   ├── player/
│   └── news/
└── widgets/                 # Widget riutilizzabili
    ├── player_card.dart
    ├── match_card.dart
    ├── standing_row.dart
    ├── score_badge.dart
    └── loading_shimmer.dart
```

### Step 4: Tema (da raffinare con UI design)
```dart
// Colori base FANTASTAR
// Primary: Verde campo (#1B5E20)
// Secondary: Oro (#FFD700)  
// Background: Dark (#121212) o Light (#FAFAFA)
// Accent: Blu (#1565C0)
```

### Step 5: API Client con JWT
```dart
// Dio interceptor che:
// - Aggiunge JWT header a ogni richiesta
// - Gestisce 401 → redirect a login
// - Gestisce errori di rete
// - Base URL: http://localhost:8000/api/v1
```

### Step 6: Schermate base
- Login / Register (funzionanti con backend)
- Home con bottom navigation (5 tab):
  1. 🏠 Home (dashboard)
  2. ⚽ Live (partite)
  3. 👥 Squadra (la mia)
  4. 🏆 Classifica
  5. 📰 News

### Verifica
- L'app si avvia senza errori
- Login/Register funzionano con il backend
- Navigazione tra i 5 tab funziona

## Report
Genera `/reports/TASK_10_REPORT.md`

---

# TASK 11 — Flutter: Home & Classifiche

## Obiettivo
Dashboard home e schermate classifiche (Serie A reale + fantasy).

## Dipendenze
- Task 10

## Schermate

### Home Screen
- Header con nome utente e avatar
- Card "Prossima giornata" con countdown
- Card "La mia squadra" con punteggio ultimo turno
- Card "Classifica fantasy" (top 3)
- Sezione "Ultime news" (3 articoli)
- Sezione "Partite live" (se ci sono)

### Classifica Serie A
- Lista 20 squadre con posizione, stemma, punti, W/D/L
- Pull to refresh
- Tap su squadra → dettaglio con rosa

### Classifica Fantasy
- Lista squadre fantasy della lega con punti, W/D/L, differenza gol
- Evidenzia la tua squadra
- Tap → dettaglio punteggi per giornata

### Classifica Marcatori
- Top scorers Serie A con foto, gol, assist
- Filtro per ruolo

## Report
Genera `/reports/TASK_11_REPORT.md`

---

# TASK 12 — Flutter: Gestione Squadra

## Obiettivo
Schermate per gestire la rosa e impostare la formazione.

## Dipendenze
- Task 10

## Schermate

### La mia rosa
- Lista giocatori acquistati divisi per ruolo (POR, DIF, CEN, ATT)
- Per ogni giocatore: foto cutout, nome, squadra reale, prezzo acquisto
- Tap → scheda giocatore

### Scheda Giocatore
- Foto grande + stemma squadra
- Info: nome, ruolo, nazionalità, numero maglia
- Statistiche stagione: gol, assist, cartellini, presenze
- Statistiche avanzate: xG, xA, passaggi chiave (da BZZoiro)
- Storico punteggi fantasy per giornata (grafico)
- Media punteggio

### Imposta Formazione
- Selezione modulo (dropdown: 3-4-3, 4-3-3, ecc.)
- Campo da calcio visuale con posizioni
- Drag & drop giocatori nelle posizioni
- Selezione ordine panchina per subentri
- Pulsante "Conferma formazione"
- Deadline: 1 ora prima della prima partita della giornata

## Report
Genera `/reports/TASK_12_REPORT.md`

---

# TASK 13 — Flutter: Asta & Mercato

## Obiettivo
Interfaccia per l'asta live e il mercato di riparazione.

## Dipendenze
- Task 08 (Auction API), Task 10

## Schermate

### Asta Live
- Giocatore corrente all'asta: foto grande, nome, ruolo, squadra
- Timer countdown
- Budget rimasto di ogni partecipante
- Pulsanti offerta: +1, +5, +10, custom
- Lista offerte in tempo reale (WebSocket)
- Suono/vibrazione quando qualcuno offre
- Storico acquisti della sessione

### Lista Giocatori (per scegliere chi mettere all'asta)
- Filtri: ruolo, squadra, prezzo suggerito
- Cerca per nome
- Ordinamento: prezzo, gol, rating

### Mercato Riparazione
- Giocatori svincolati (non acquistati da nessuno)
- Proponi scambio ad altra squadra
- Rilascia giocatore

## Report
Genera `/reports/TASK_13_REPORT.md`

---

# TASK 14 — Flutter: Live Match

## Obiettivo
Schermata partita live con punteggi fantasy aggiornati in tempo reale.

## Dipendenze
- Task 09 (WebSocket), Task 10

## Schermate

### Live Overview
- Lista partite in corso con score e minuto
- Per ogni partita: stemmi squadre, risultato, minuto
- Indicatore "LIVE" che pulsa

### Dettaglio Partita Live
- Score grande al centro
- Timeline eventi (gol ⚽, cartellini 🟨🟥, sostituzioni 🔄)
- Formazioni delle due squadre
- Se la partita coinvolge giocatori della mia fantasquadra:
  → Mostra punteggio fantasy in tempo reale
  → Evidenzia i miei giocatori nella formazione

### Fantasy Matchday Live
- La mia formazione con punteggio aggiornato in tempo reale
- Per ogni giocatore: punteggio + dettaglio bonus/malus
- Totale squadra + gol fantasy
- VS avversario fantasy (se sta giocando anche lui)
- Animazione quando arriva un nuovo evento

### WebSocket
- Connessione automatica quando si apre la schermata live
- Riconnessione automatica se cade la connessione
- Notifica push quando un mio giocatore segna/prende cartellino

## Report
Genera `/reports/TASK_14_REPORT.md`

---

# TASK 15 — React Web: Setup & Core

## Obiettivo
Setup del frontend web React con componenti core e API client.

## Dipendenze
- Task 05-09 (Backend completo)

## Istruzioni

### Setup
```bash
cd /Users/r.amoroso/Documents/Cursor/FANTASTAR
npx create-next-app@latest frontend_web --typescript --tailwind --app
```

### Struttura
```
src/
├── app/
│   ├── layout.tsx
│   ├── page.tsx              # Dashboard
│   ├── login/
│   ├── register/
│   ├── league/[id]/
│   ├── team/[id]/
│   ├── live/
│   ├── standings/
│   └── player/[id]/
├── components/
│   ├── ui/                   # Componenti base (shadcn/ui)
│   ├── PlayerCard.tsx
│   ├── MatchCard.tsx
│   ├── StandingsTable.tsx
│   ├── FormationField.tsx
│   └── LiveScoreBar.tsx
├── hooks/
│   ├── useAuth.ts
│   ├── useWebSocket.ts
│   └── useApi.ts
├── services/
│   ├── apiClient.ts
│   └── wsClient.ts
├── store/
│   └── authStore.ts          # Zustand
└── types/
    └── index.ts
```

### Librerie
- Tailwind CSS + shadcn/ui per UI
- Zustand per state management
- SWR o React Query per data fetching
- Recharts per grafici

## Report
Genera `/reports/TASK_15_REPORT.md`

---

# TASK 16 — React Web: Dashboard & Live

## Obiettivo
Pagine principali del sito web: dashboard, live scoring, classifiche.

## Dipendenze
- Task 15

## Pagine
- Dashboard con overview
- Classifica Serie A (tabella interattiva)
- Classifica Fantasy
- Live match center
- Dettaglio giocatore
- Gestione squadra e formazione

## Report
Genera `/reports/TASK_16_REPORT.md`

---

# TASK 17 — News Feed & Notifiche

## Obiettivo
Sezione news nell'app e sistema di notifiche push.

## Dipendenze
- Task 04, Task 14

## Funzionalità
- Feed news da RSS (con immagini quando disponibili)
- Filtro per fonte
- Push notification:
  - Gol del mio giocatore
  - Cartellino rosso
  - Inizio partita dei miei giocatori
  - Risultato finale giornata fantasy
- Impostazioni notifiche personalizzabili

## Report
Genera `/reports/TASK_17_REPORT.md`
