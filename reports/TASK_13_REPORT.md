# TASK 13 — Report Flutter: Asta & Mercato

**Data completamento:** 13 Febbraio 2026  
**Percorso progetto:** `/Users/r.amoroso/Documents/Cursor/Fantastar`

---

## 1. Obiettivo del task

Interfaccia per **asta live** e **mercato di riparazione**: schermata asta (giocatore corrente, timer, offerte, storico), lista giocatori con filtri e azione “metti all’asta” (admin), mercato (svincolati, rilascia, scambi). UI minima e placeholder, nessun design definitivo.

---

## 2. Dipendenze

- Task 08 (Auction API), Task 10 (Setup Flutter, auth, servizi)
- Backend: `GET/POST .../leagues/{id}/auction/current|bid|start|assign|history`, WebSocket `ws/auction/{league_id}`; mercato: `GET .../market/free-agents`, `POST .../buy`, `POST .../release`, `POST .../trade-propose`, `GET .../trades`, `POST .../trade-respond`

---

## 3. Cosa è stato fatto

### 3.1 Costanti

- **`lib/app/constants.dart`**: getter **`kWsBaseUrl`** (stesso host di `kApiBaseUrl`, schema ws/wss) per connessioni WebSocket.

### 3.2 Modelli

- **AuctionCurrentModel**, **AuctionHistoryItemModel** (`lib/models/auction.dart`): asta corrente (playerId, playerName, position, realTeamName, currentBid, leadingUserId, leadingUserName, endsAt, roundNumber) e voce storico (playerId, playerName, winningUserId, amount); `fromJson` allineati al backend.
- **PlayerListItemModel**, **PlayerListPaginatedResult** (`lib/models/player_list_item.dart`): elemento listone (id, name, position, realTeamName, initialPrice, …) e risultato paginato (players, total, page, pageSize, totalPages).
- **FantasyLeagueModel** (`lib/models/fantasy_league.dart`): aggiunti **adminUserId** e **isAdminFor(userId)** per verificare se l’utente è admin della lega.

### 3.3 Servizi

- **AuctionService** (`lib/services/auction_service.dart`):  
  `getCurrent(leagueId)`, `placeBid(leagueId, amount)`, `getHistory(leagueId)`, `startAuction(leagueId, playerId, {roundNumber?})`, `assignCurrent(leagueId)`, **auctionWsUrl(leagueId)** (URL WebSocket).
- **MarketService** (`lib/services/market_service.dart`):  
  `getFreeAgents(leagueId, …)`, `buy(leagueId, playerId)`, `release(leagueId, playerId)`, `tradePropose(leagueId, …)`, `getTrades(leagueId)`, `tradeRespond(leagueId, tradeId, accept)`; usa `PlayerListPaginatedResult`.
- **PlayerService** (`lib/services/player_service.dart`): **getPlayers(leagueId?, position?, search?, sortBy, sortOrder, page)** → `PlayerListPaginatedResult` (listone per asta/filtri).

### 3.4 Schermata Asta

- **AuctionScreen** (`lib/screens/auction/auction_screen.dart`), route `/league/:leagueId/auction`:
  - Mostra asta corrente: nome, ruolo, squadra, offerta max, leader, countdown; pulsanti +1 / +5 / +10; messaggi da WebSocket (new_bid, auction_start, auction_end, auction_no_sale); lista “Ultime offerte”, “Storico acquisti”.
  - Se admin lega: pulsante “Assegna” e link “Scegli giocatore per asta” → push a `/league/:leagueId/players?mode=auction`.
  - Usa **WebSocketService** e **Timer** per il countdown.

### 3.5 Lista Giocatori (per asta)

- **PlayerListScreen** (`lib/screens/players/player_list_screen.dart`), route `/league/:leagueId/players` (query `mode=auction`):
  - Filtri: campo di ricerca, ruolo (dropdown), ordinamento (nome / prezzo). Lista giocatori da `PlayerService.getPlayers`.
  - Se **forAuction && isAdmin**: tap → `startAuction(leagueId, playerId)` e pop; altrimenti tap → push a `/player/:id`.

### 3.6 Schermata Mercato

- **MarketScreen** (`lib/screens/market/market_screen.dart`), route `/league/:leagueId/market`:
  - **TabBar** (3 tab):  
    (1) **Svincolati**: lista da `getFreeAgents`, pulsante “Acquista” per ogni giocatore;  
    (2) **Rilascia**: rosa della mia squadra (team da `HomeProvider.myStandingFor(userId)?.fantasyTeamId` + `TeamService.getTeam`), pulsante “Rilascia” per ogni giocatore;  
    (3) **Scambi**: liste “Inviate” e “Ricevute” da `getTrades`; per le ricevute in PENDING pulsanti “Accetta” / “Rifiuta” che chiamano `tradeRespond`.  
  - Proposta scambio lasciata come **testo placeholder** (nessun form definitivo).

### 3.7 Route e ingresso

- **Route** (`lib/app/routes.dart`):  
  `/league/:leagueId/auction` → AuctionScreen,  
  `/league/:leagueId/players` → PlayerListScreen (forAuction da query `mode=auction`),  
  `/league/:leagueId/market` → MarketScreen.
- **Home tab** (`lib/screens/home/tabs/home_tab.dart`): card con due ListTile “Asta” e “Mercato” che fanno push a `/league/{firstLeague.id}/auction` e `/league/{firstLeague.id}/market` (visibili solo se `home.firstLeague != null`).

### 3.8 Provider / main

- In `main.dart` registrati **AuctionService** e **MarketService**.

---

## 4. File creati/modificati

| File | Azione |
|------|--------|
| `lib/app/constants.dart` | Modificato (kWsBaseUrl) |
| `lib/models/auction.dart` | Creato |
| `lib/models/player_list_item.dart` | Creato |
| `lib/models/fantasy_league.dart` | Modificato (adminUserId, isAdminFor) |
| `lib/services/auction_service.dart` | Creato |
| `lib/services/market_service.dart` | Creato |
| `lib/services/player_service.dart` | Modificato (getPlayers, PlayerListPaginatedResult) |
| `lib/main.dart` | Modificato (AuctionService, MarketService) |
| `lib/screens/auction/auction_screen.dart` | Creato |
| `lib/screens/players/player_list_screen.dart` | Creato |
| `lib/screens/market/market_screen.dart` | Creato |
| `lib/app/routes.dart` | Modificato (auction, players, market) |
| `lib/screens/home/tabs/home_tab.dart` | Modificato (card Asta & Mercato) |
| `reports/TASK_13_REPORT.md` | Creato |

---

## 5. Verifica

- **Home:** con almeno una lega caricata, compaiono le voci “Asta” e “Mercato”; tap apre le rispettive schermate.
- **Asta:** mostra asta corrente (o messaggio “Nessuna asta”); pulsanti offerta e lista offerte/storico; se admin, “Assegna” e “Scegli giocatore per asta” → lista giocatori in modalità asta.
- **Lista giocatori:** filtri e ordinamento; in modalità asta (admin) tap avvia asta per quel giocatore.
- **Mercato:** tab Svincolati (acquista), Rilascia (rosa + rilascia), Scambi (inviate/ricevute, accetta/rifiuta).
- Eseguire `flutter analyze` e, se possibile, `flutter build apk --debug` per conferma.

---

## 6. Note

- **Proposta scambio:** solo placeholder testuale; form completo (selezione giocatori in uscita/entrata) non implementato.
- **Suono/vibrazione** su nuova offerta in asta: non implementato.
- **Budget rimanente per partecipante** in asta: non mostrato (UI minima).
- **Foto grande** giocatore in asta: non inserita (placeholder).
- Connessione WebSocket asta: aperta alla schermata asta; messaggi new_bid, auction_start, auction_end, auction_no_sale gestiti per aggiornare UI.
