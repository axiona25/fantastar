# Chiavi e segreti (non in git)

In questa cartella puoi salvare chiavi API in modo locale.

## OpenAI (avatar Disney)

1. Crea il file `openai_api_key.txt`
2. Incolla la tua API key OpenAI (una sola riga, senza spazi)
3. Lo script `scripts/generate_disney_avatars.py` userà automaticamente questa chiave se non passi `--api-key` e non è impostata `OPENAI_API_KEY`

Il file `openai_api_key.txt` è in `.gitignore` e non viene mai committato.
