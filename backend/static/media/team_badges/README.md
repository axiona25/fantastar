# Stemmi squadra (team_badges)

## Generazione stemmi 3D

Metti le immagini sorgente in `source/`. Poi, dalla root del progetto:

**Con Docker:**
```bash
docker-compose exec backend python3 scripts/generate_team_badges_3d.py \
  --api-key "LA_TUA_OPENAI_API_KEY" \
  --input-dir static/media/team_badges/source/ \
  --output-dir static/media/team_badges/ \
  --all \
  --sleep 2
```

**Senza Docker (dalla cartella backend):**
```bash
cd backend
python3 scripts/generate_team_badges_3d.py \
  --api-key "LA_TUA_OPENAI_API_KEY" \
  --input-dir static/media/team_badges/source/ \
  --output-dir static/media/team_badges/ \
  --all \
  --sleep 2
```

Oppure usa i default (input=source/, output=questa cartella) e la chiave in `backend/secrets/openai_api_key.txt`:
```bash
python3 scripts/generate_team_badges_3d.py --all
```

## Nomi visivi (badges_names.json)

Lo script **aggiorna in automatico** `badges_names.json` dopo la generazione: per ogni nuovo PNG usa l'API Vision di OpenAI (gpt-4o-mini) per leggere il testo sullo stemma e usarlo come nome. Se Vision non riesce, viene usato un nome ricavato dal filename.

Puoi comunque **modificare a mano** `badges_names.json` per correggere o migliorare i nomi (es. "PARIS ST. GENNNAR" → "Paris St. Gennar").
