# Analisi cartella backend/static/photos/

**Data analisi:** 2025-02-15

## Numero totale di file
- **1235** file

## Formato dei nomi file
- **Numeric ID**: `{numero}.png` (es. `1.png`, `100.png`, `11.png`) — foto principale
- **Cutout**: `{numero}_cutout.png` (es. `100_cutout.png`) — ritaglio giocatore
- I numeri corrispondono molto probabilmente all’ID TheSportsDB (`thesportsdb_id` nel DB) o a un `external_id`.

## File per estensione
| Estensione | Conteggio |
|------------|-----------|
| .png       | 1235      |

(Nessun .jpg o .jpeg.)

## Duplicati / file doppi per giocatore
- **Nessun duplicato** nel senso di due file identici per lo stesso giocatore.
- Per molti giocatori esistono **due file**: uno principale (`{id}.png`) e uno cutout (`{id}_cutout.png`).
- Conteggio: **626** foto principali (senza `_cutout`), **609** cutout.

## Primi 20 nomi file (esempio)
```
1.png
100.png
100_cutout.png
101.png
101_cutout.png
103.png
103_cutout.png
104.png
104_cutout.png
105.png
105_cutout.png
106.png
106_cutout.png
107.png
108.png
108_cutout.png
109.png
109_cutout.png
11.png
110.png
```

## Note per lo script di mapping
- Lo script può mappare i file **numerici** al giocatore tramite `thesportsdb_id` o `external_id`, poi rinominare in `{player.id}.png` e aggiornare `photo_local` / `cutout_local`.
- Se in futuro si aggiungono file con nome tipo `Nome_Cognome.png`, lo script può usare fuzzy matching sul nome (soglia 85%) e normalizzazione accenti.
