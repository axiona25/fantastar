# TASK 15 — Report React Web: Setup & Core

**Data completamento:** 13 Febbraio 2026  
**Percorso progetto:** `/Users/r.amoroso/Documents/Cursor/Fantastar`

---

## 1. Obiettivo del task

Setup del frontend web **React** (Next.js) con componenti core, **API client**, auth, state management e data fetching. UI minima e placeholder, nessun design definitivo.

---

## 2. Dipendenze

- Task 05–09 (Backend completo)
- Node.js, npm

---

## 3. Cosa è stato fatto

### 3.1 Setup progetto

- **Next.js 16** con **TypeScript**, **Tailwind CSS 4**, **App Router**, **ESLint**.
- Progetto creato con `npx create-next-app@latest frontend_web --ts --tailwind --eslint --app --yes`.
- Struttura con **src/**: `app` spostato in `src/app`, path alias `@/*` → `./src/*` in `tsconfig.json`.

### 3.2 Struttura cartelle

```
src/
├── app/
│   ├── layout.tsx              # Root layout (metadata FANTASTAR)
│   ├── globals.css
│   ├── (dashboard)/
│   │   ├── layout.tsx          # Nav + auth check, redirect /login
│   │   ├── page.tsx            # Dashboard (placeholder)
│   │   ├── login/              # (no: login è fuori dal group)
│   │   ├── league/[id]/page.tsx
│   │   ├── team/[id]/page.tsx
│   │   ├── live/page.tsx
│   │   ├── standings/page.tsx
│   │   └── player/[id]/page.tsx
│   ├── login/page.tsx
│   └── register/page.tsx
├── components/
│   ├── ui/
│   │   ├── button.tsx
│   │   └── card.tsx
│   ├── PlayerCard.tsx
│   ├── MatchCard.tsx
│   ├── StandingsTable.tsx
│   ├── FormationField.tsx
│   └── LiveScoreBar.tsx
├── hooks/
│   ├── useAuth.ts
│   ├── useApi.ts
│   └── useWebSocket.ts
├── services/
│   ├── apiClient.ts
│   └── wsClient.ts
├── store/
│   └── authStore.ts
└── types/
    └── index.ts
```

### 3.3 Librerie installate

- **Zustand** (state management, auth store con persist).
- **SWR** (data fetching in useApi).
- **Recharts** (installato; grafici da usare nei task successivi).
- **shadcn/ui**: componenti base riprodotti in modo minimo (Button, Card in `components/ui/`) con Tailwind; nessuna CLI shadcn (UI minima richiesta).

### 3.4 Tipi (`src/types/index.ts`)

- **User**, **Token** (allineati a auth backend).
- **StandingRow**, **FantasyLeague**, **MatchListItem**, **PlayerListItem** (per classifiche, leghe, partite, giocatori).

### 3.5 API client (`src/services/apiClient.ts`)

- **BASE_URL** da `NEXT_PUBLIC_API_BASE_URL` (default `http://localhost:8000/api/v1`).
- **apiFetch(path, options)**: fetch con Bearer token da localStorage, Content-Type/Accept JSON; su **401** tenta **refresh** (POST `/auth/refresh`), aggiorna token e ritenta; se fallisce chiama **onUnauthorized** e clear token.
- **setOnUnauthorized(fn | null)**, **setStoredTokens**, **clearStoredTokens**, **refreshToken** esportati per uso da store/layout.

### 3.6 WebSocket client (`src/services/wsClient.ts`)

- Base URL WS derivata da host/port dell’API (ws/wss).
- **getAuctionWsUrl(leagueId)**, **getLiveWsUrl(leagueId)**, **getMatchWsUrl(matchId)**.
- **createWebSocket(url, onMessage, onClose?, onError?)**: crea `WebSocket`, parse JSON su `onmessage`.

### 3.7 Auth store (`src/store/authStore.ts`)

- **Zustand** con **persist** (chiave `fantastar-auth`, solo `user`).
- Stato: `user`, `isLoading`, `error`.
- **login(email, password)**: POST `/auth/login`, salva token, `fetchMe()`.
- **register(email, username, password)**: POST `/auth/register`, poi login.
- **logout()**: clear token e user.
- **fetchMe()**: GET `/auth/me`, aggiorna user.
- **clearError()**.

### 3.8 Hooks

- **useAuth(syncOnMount?)**: espone auth store; se `syncOnMount` e c’è token ma non user, chiama `fetchMe()` al mount.
- **useApi&lt;T&gt;(path, config?)**: **SWR** con fetcher = `apiFetch`; ritorna `data`, `error`, `mutate`, `isLoading`, `isValidating`, `isError`.
- **useWebSocket(url, { onMessage?, reconnect?, reconnectIntervalMs? })**: connessione WS, stato `lastMessage` e `connected`; opzionale riconnessione.

### 3.9 Layout e navigazione

- **Root layout**: metadata title "FANTASTAR", font e globals.css.
- **Dashboard layout** `(dashboard)/layout.tsx`: client component; nav con link a FANTASTAR, Live, Classifiche; se loggato mostra username e “Esci”, altrimenti “Accedi”; **setOnUnauthorized** → redirect `/login`; effect che, se non auth page e nessun token/user, redirect a `/login`.

### 3.10 Pagine

- **/ (dashboard)**: titolo “Dashboard”, card “Prossima giornata” e “Partite” (placeholder), link a Live e Classifiche.
- **/login**: form email/password, submit → login store, redirect `/`; link Registrati.
- **/register**: form email/username/password, submit → register store, redirect `/`; link Accedi.
- **/league/[id]**, **/team/[id]**, **/player/[id]**: placeholder con ID in pagina.
- **/live**: titolo Live, **LiveScoreBar** (placeholder), testo “Partite in corso (placeholder)”.
- **/standings**: titolo Classifiche, **StandingsTable** in modalità placeholder.

### 3.11 Componenti placeholder

- **PlayerCard**: con `player` mostra nome, ruolo, squadra, quotazione; altrimenti testo “Player card (placeholder)”.
- **MatchCard**: con `match` mostra squadre, giornata, score e minuto; altrimenti “Match card (placeholder)”.
- **StandingsTable**: con `rows` tabella (rank, squadra, Pt, V, P); altrimenti “Tabella classifica (placeholder)”.
- **FormationField**: solo testo “Formazione / campo (placeholder)”.
- **LiveScoreBar**: indicatore “Live” con pallino rosso pulsante e testo placeholder.

---

## 4. File creati/modificati

| File | Azione |
|------|--------|
| `frontend_web/package.json` | Creato (Next.js + zustand, swr, recharts) |
| `frontend_web/tsconfig.json` | Modificato (paths @/* → ./src/*) |
| `frontend_web/.env.example` | Creato (NEXT_PUBLIC_API_BASE_URL) |
| `frontend_web/src/app/layout.tsx` | Modificato (metadata FANTASTAR) |
| `frontend_web/src/app/(dashboard)/layout.tsx` | Creato |
| `frontend_web/src/app/(dashboard)/page.tsx` | Creato (dashboard) |
| `frontend_web/src/app/login/page.tsx` | Creato |
| `frontend_web/src/app/register/page.tsx` | Creato |
| `frontend_web/src/app/league/[id]/page.tsx` | Creato |
| `frontend_web/src/app/team/[id]/page.tsx` | Creato |
| `frontend_web/src/app/live/page.tsx` | Creato |
| `frontend_web/src/app/standings/page.tsx` | Creato |
| `frontend_web/src/app/player/[id]/page.tsx` | Creato |
| `frontend_web/src/types/index.ts` | Creato |
| `frontend_web/src/services/apiClient.ts` | Creato |
| `frontend_web/src/services/wsClient.ts` | Creato |
| `frontend_web/src/store/authStore.ts` | Creato |
| `frontend_web/src/hooks/useAuth.ts` | Creato |
| `frontend_web/src/hooks/useApi.ts` | Creato |
| `frontend_web/src/hooks/useWebSocket.ts` | Creato |
| `frontend_web/src/components/ui/button.tsx` | Creato |
| `frontend_web/src/components/ui/card.tsx` | Creato |
| `frontend_web/src/components/PlayerCard.tsx` | Creato |
| `frontend_web/src/components/MatchCard.tsx` | Creato |
| `frontend_web/src/components/StandingsTable.tsx` | Creato |
| `frontend_web/src/components/FormationField.tsx` | Creato |
| `frontend_web/src/components/LiveScoreBar.tsx` | Creato |
| `reports/TASK_15_REPORT.md` | Creato |

---

## 5. Verifica

- **Build:** `cd frontend_web && npm run build` completa senza errori.
- **Avvio:** `npm run dev`; aprire `http://localhost:3000`; senza login si viene reindirizzati a `/login` dalle pagine sotto (dashboard).
- **Login/Register:** compilare form e inviare; con backend avviato su `localhost:8000` e utente esistente, il login salva token e reindirizza a `/`; la nav mostra username e “Esci”.
- **Pagine:** Dashboard, Live, Classifiche, league/team/player con ID sono raggiungibili e mostrano placeholder.

---

## 6. Note

- **shadcn/ui:** non usata la CLI; componenti base (Button, Card) realizzati a mano con Tailwind in `components/ui/` per coerenza con “UI minima”.
- **Protezione route:** il redirect a `/login` avviene nel layout client (useEffect + token/user); per protezione più robusta si può aggiungere middleware Next.js.
- **Recharts:** installato e pronto per grafici nei task successivi (Dashboard & Live, ecc.).
- **API base URL:** in produzione impostare `NEXT_PUBLIC_API_BASE_URL` (e eventualmente WS) nelle variabili d’ambiente.
