# TASK 16 — Report React Web: Dashboard & Live

**Data completamento:** 13 Febbraio 2026  
**Percorso progetto:** `/Users/r.amoroso/Documents/Cursor/Fantastar`

---

## 1. Obiettivo del task

Implementare le pagine principali del sito web: **dashboard**, **live scoring** e **classifiche**, con **dettaglio giocatore**, **gestione squadra e formazione**. UI minima e placeholder, nessun design definitivo.

---

## 2. Dipendenze

- **Task 15** (Setup React Web: Next.js, apiClient, auth, SWR, Zustand, componenti base)

---

## 3. Pagine realizzate

| Pagina | Route | Descrizione |
|--------|--------|-------------|
| Dashboard | `/` | Overview: leghe (useApi `/leagues`), top 3 classifica Fantasy (prima lega), link Live / Classifiche / La mia squadra |
| Classifiche | `/standings` | Sezione **Serie A** (tabella placeholder); sezione **Classifica Fantasy** con selector lega e `useApi('/leagues/{id}/standings')` → `StandingsTable` |
| Live | `/live` | Lista partite in corso con `useApi('/matches?status=IN_PLAY')`, `MatchCard` per ogni partita, link a dettaglio partita |
| Dettaglio partita | `/match/[id]` | `useApi('/matches/{id}')`, `MatchCard` + elenco eventi (se presenti) |
| Dettaglio giocatore | `/player/[id]` | `useApi('/players/{id}')`, `PlayerCard` con dati giocatore |
| La mia squadra | `/team` | Ricava “mia” squadra da prima lega/standings (user_id), link a squadra e formazione o messaggio placeholder |
| Dettaglio squadra | `/team/[id]` | `useApi('/teams/{id}')`, nome, rosa (link a giocatori), link “Imposta formazione” |
| Formazione | `/team/[id]/lineup/[matchday]` | `useApi('/teams/{id}/lineup/{matchday}')`, `FormationField` placeholder, select modulo e pulsante “Salva (placeholder)” |

---

## 4. File toccati / creati

### Nuovi file
- `frontend_web/src/app/(dashboard)/DashboardContent.tsx` — Client: leagues, standings, top 3, link La mia squadra
- `frontend_web/src/app/(dashboard)/StandingsContent.tsx` — Client: Serie A placeholder + Fantasy con selector lega e API
- `frontend_web/src/app/(dashboard)/LiveContent.tsx` — Client: partite IN_PLAY, lista con link a `/match/[id]`
- `frontend_web/src/app/(dashboard)/player/[id]/PlayerDetailContent.tsx` — Client: dettaglio giocatore da API
- `frontend_web/src/app/(dashboard)/team/[id]/TeamDetailContent.tsx` — Client: dettaglio squadra e rosa
- `frontend_web/src/app/(dashboard)/team/MyTeamContent.tsx` — Client: “La mia squadra” (da standings)
- `frontend_web/src/app/(dashboard)/team/page.tsx` — Pagina “La mia squadra”
- `frontend_web/src/app/(dashboard)/team/[id]/lineup/[matchday]/page.tsx` — Pagina formazione (GET lineup + UI placeholder)
- `frontend_web/src/app/(dashboard)/match/[id]/page.tsx` — Dettaglio partita (GET match + eventi)

### Modificati
- `frontend_web/src/app/(dashboard)/page.tsx` — Usa `DashboardContent`
- `frontend_web/src/app/(dashboard)/standings/page.tsx` — Usa `StandingsContent`
- `frontend_web/src/app/(dashboard)/live/page.tsx` — Usa `LiveContent`
- `frontend_web/src/app/(dashboard)/player/[id]/page.tsx` — Usa `PlayerDetailContent` con API
- `frontend_web/src/app/(dashboard)/team/[id]/page.tsx` — Usa `TeamDetailContent` con API
- `frontend_web/src/app/(dashboard)/layout.tsx` — Aggiunto link **Squadra** in nav → `/team`
- `frontend_web/src/types/index.ts` — Aggiunti tipi: `PlayerDetail`, `TeamDetail`, `MatchDetail`, `LineupSlot`, `LineupResponse`

---

## 5. Come verificare

1. **Backend** avviato (es. `uvicorn` su porta 8000) e utente loggato.
2. **Frontend:** da `frontend_web`: `npm run dev`, aprire `http://localhost:3000`.
3. **Dashboard:** dopo login si vedono (se ci sono dati) lega, top 3 classifica, link a Live, Classifiche, La mia squadra.
4. **Classifiche:** tab “Serie A” con tabella placeholder; selector lega e tabella Fantasy da API.
5. **Live:** lista partite in corso (o “Nessuna partita in corso”); click su partita → `/match/[id]`.
6. **Giocatore:** da rosa squadra o (se esistente) da listone, aprire `/player/[id]` e verificare scheda.
7. **Squadra:** da dashboard “La mia squadra” o da nav “Squadra” → `/team`; da lì link a `/team/[id]` e a “Imposta formazione” → `/team/[id]/lineup/1`.
8. **Build:** `npm run build` in `frontend_web` completa senza errori.

---

## 6. Note

- **UI minima e placeholder:** nessun design definitivo; tabelle, card e form sono funzionali ma essenziali.
- **Classifica Serie A:** nessun endpoint backend dedicato; in standings è mostrata solo tabella placeholder.
- **Formazione:** pagina legge lineup da GET; select modulo e pulsante “Salva” sono placeholder (POST non invocato).
- **Nav:** voci FANTASTAR, Live, Classifiche, Squadra, user / Esci; “Squadra” punta a `/team` (la mia squadra).

---

**Fine report TASK 16**
