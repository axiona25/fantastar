# TASK 17 — Report News Feed & Notifiche

**Data completamento:** 13 Febbraio 2026  
**Percorso progetto:** `/Users/r.amoroso/Documents/Cursor/Fantastar`

---

## 1. Obiettivo del task

Sezione **news** nell’app e sistema di **notifiche push**: feed da RSS con filtro per fonte, preferenze notifiche (UI). UI minima e placeholder, nessun design definitivo.

---

## 2. Dipendenze

- Task 04, Task 14 (backend: sync news da RSS, modelli; notifiche push da integrare a livello backend in seguito).

---

## 3. Funzionalità realizzate

### 3.1 Feed news da RSS

- **Backend:** Nuovo modulo API `GET /api/v1/news` che legge dalla tabella `news_articles` (popolata dal task `sync_news`).
  - Query: `source` (opzionale, filtro per fonte), `limit` (default 50, max 100).
  - Risposta: lista di articoli con `id`, `title`, `summary`, `url`, `source`, `image_url`, `published_at`.
  - Endpoint `GET /api/v1/news/sources`: elenco fonti distinte per il filtro.
- **Frontend:** Pagina **News** (`/news`):
  - `useApi("/news")` e `useApi("/news/sources")`.
  - Filtro per **fonte** (select con “Tutte” + fonti restituite da `/news/sources`).
  - Lista articoli in card: titolo (link esterno), fonte, anteprima testo (summary senza HTML, troncata), **immagine** quando presente (`image_url`).

### 3.2 Push notification (placeholder)

- **Frontend:** Pagina **Impostazioni notifiche** (`/settings/notifications`):
  - Toggle (placeholder) per:
    - Gol del mio giocatore
    - Cartellino rosso
    - Inizio partita dei miei giocatori
    - Risultato finale giornata fantasy
  - Stato salvato solo in memoria (nessun backend per preferenze o invio push in questo task).

---

## 4. File toccati / creati

### Backend

- `backend/app/schemas/news.py` — Schema Pydantic `NewsItemResponse`.
- `backend/app/api/v1/news.py` — Router `GET /news` (lista con filtro `source`, `limit`) e `GET /news/sources`.
- `backend/app/main.py` — Registrazione router `news_router`.

### Frontend

- `frontend_web/src/types/index.ts` — Tipo `NewsItem`.
- `frontend_web/src/app/(dashboard)/news/NewsContent.tsx` — Client: feed + select fonte, card con titolo/link, fonte, immagine (se presente), summary.
- `frontend_web/src/app/(dashboard)/news/page.tsx` — Pagina News.
- `frontend_web/src/app/(dashboard)/settings/notifications/NotificationsContent.tsx` — Client: toggle per le 4 tipologie di notifica (placeholder).
- `frontend_web/src/app/(dashboard)/settings/notifications/page.tsx` — Pagina impostazioni notifiche.
- `frontend_web/src/app/(dashboard)/layout.tsx` — Link **News** in nav; link **Notifiche** in area utente.

---

## 5. Come verificare

1. **Backend:** Avviare API e (opzionale) eseguire almeno una volta il job `sync_news` (scheduler o manuale) per popolare `news_articles`. Se la tabella è vuota, il frontend mostrerà “Nessun articolo”.
2. **Fonti:** `GET /api/v1/news/sources` restituisce le fonti presenti in DB; `GET /api/v1/news?source=Football%20Italia` filtra per quella fonte.
3. **Frontend:** Login, poi:
   - **News:** da nav “News” → `/news`; verificare lista articoli e filtro per fonte; click su titolo apre l’URL esterno; immagini mostrate se `image_url` presente.
   - **Notifiche:** da nav “Notifiche” → `/settings/notifications`; verificare che i toggle si aggiornino (stato solo in memoria).
4. **Build:** `npm run build` in `frontend_web` completa senza errori.

---

## 6. Note

- **UI minima:** layout essenziale, nessun design definitivo.
- **News:** I dati provengono da `news_articles`; il sync RSS è gestito dal backend (task esistenti). Le fonti disponibili dipendono dai feed configurati in `rss_news.py` (es. Football Italia, Get Football News Italy, Cult of Calcio, FIGC).
- **Push notification:** Nessun endpoint backend per preferenze utente né per l’invio push; l’integrazione con un servizio di push (es. Task 14) e il salvataggio delle preferenze sono da realizzare in un passo successivo.
- **Impostazioni notifiche:** Le opzioni (gol, cartellino rosso, inizio partita, risultato giornata) sono allineate alla spec; i toggle sono solo UI placeholder.

---

**Fine report TASK 17**
