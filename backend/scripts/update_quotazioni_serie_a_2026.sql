-- Aggiornamento quotazioni giocatori Serie A 2025/2026
-- Fonte: FantaMaster - Ultimo aggiornamento 17/02/2026
-- Totale: 577 giocatori
--
-- Esecuzione (da backend o con psql):
--   psql -U fantastar -d fantastar -f backend/scripts/update_quotazioni_serie_a_2026.sql
--   oppure: docker-compose exec db psql -U fantastar -d fantastar -f /path/to/this/file
--
-- Le UPDATE aggiornano giocatori esistenti: match per squadra + nome (anche solo cognome:
-- es. lista "Audero" aggiorna anche "Marco Audero" nel DB). Le INSERT aggiungono
-- squadre/giocatori mancanti. Per allineare la lista completa da CSV usa:
--   python scripts/align_players_from_csv.py path/to/lista.csv

BEGIN;

-- AGGIORNA QUOTAZIONI per giocatori esistenti
-- Match flessibile: nome lista (es. "Audero") trova anche "Marco Audero" nel DB (Football-Data usa nome completo)
UPDATE players SET initial_price = 17, position = 'POR' WHERE real_team_id = (SELECT id FROM real_teams WHERE LOWER(name) = LOWER('Cremonese') LIMIT 1) AND (LOWER(name) = LOWER('Audero') OR name ILIKE '% ' || LOWER('Audero') OR name ILIKE LOWER('Audero') || ' %');
UPDATE players SET initial_price = 4, position = 'POR' WHERE real_team_id = (SELECT id FROM real_teams WHERE LOWER(name) = LOWER('Genoa') LIMIT 1) AND (LOWER(name) = LOWER('Bijlow') OR name ILIKE '% ' || LOWER('Bijlow') OR name ILIKE LOWER('Bijlow') || ' %');
UPDATE players SET initial_price = 1, position = 'POR' WHERE real_team_id = (SELECT id FROM real_teams WHERE LOWER(name) = LOWER('Verona') LIMIT 1) AND (LOWER(name) = LOWER('Borghi') OR name ILIKE '% ' || LOWER('Borghi') OR name ILIKE LOWER('Borghi') || ' %');
UPDATE players SET initial_price = 24, position = 'POR' WHERE real_team_id = (SELECT id FROM real_teams WHERE LOWER(name) = LOWER('Como') LIMIT 1) AND (LOWER(name) = LOWER('Butez') OR name ILIKE '% ' || LOWER('Butez') OR name ILIKE LOWER('Butez') || ' %');
UPDATE players SET initial_price = 2, position = 'POR' WHERE real_team_id = (SELECT id FROM real_teams WHERE LOWER(name) = LOWER('Inter') LIMIT 1) AND (LOWER(name) = LOWER('Calligaris') OR name ILIKE '% ' || LOWER('Calligaris') OR name ILIKE LOWER('Calligaris') || ' %');
UPDATE players SET initial_price = 20, position = 'POR' WHERE real_team_id = (SELECT id FROM real_teams WHERE LOWER(name) = LOWER('Cagliari') LIMIT 1) AND (LOWER(name) = LOWER('Caprile') OR name ILIKE '% ' || LOWER('Caprile') OR name ILIKE LOWER('Caprile') || ' %');
UPDATE players SET initial_price = 25, position = 'POR' WHERE real_team_id = (SELECT id FROM real_teams WHERE LOWER(name) = LOWER('Atalanta') LIMIT 1) AND (LOWER(name) = LOWER('Carnesecchi') OR name ILIKE '% ' || LOWER('Carnesecchi') OR name ILIKE LOWER('Carnesecchi') || ' %');
UPDATE players SET initial_price = 3, position = 'POR' WHERE real_team_id = (SELECT id FROM real_teams WHERE LOWER(name) = LOWER('Como') LIMIT 1) AND (LOWER(name) = LOWER('Cavlina') OR name ILIKE '% ' || LOWER('Cavlina') OR name ILIKE LOWER('Cavlina') || ' %');
UPDATE players SET initial_price = 1, position = 'POR' WHERE real_team_id = (SELECT id FROM real_teams WHERE LOWER(name) = LOWER('Fiorentina') LIMIT 1) AND (LOWER(name) = LOWER('Christensen') OR name ILIKE '% ' || LOWER('Christensen') OR name ILIKE LOWER('Christensen') || ' %');
UPDATE players SET initial_price = 1, position = 'POR' WHERE real_team_id = (SELECT id FROM real_teams WHERE LOWER(name) = LOWER('Cagliari') LIMIT 1) AND (LOWER(name) = LOWER('Ciocci') OR name ILIKE '% ' || LOWER('Ciocci') OR name ILIKE LOWER('Ciocci') || ' %');
-- ... inserisci qui tutte le altre UPDATE (da Contini fino a Zapata D) dal tuo script originale ...

-- INSERISCI SQUADRE MANCANTI (compatibile con schema senza UNIQUE su real_teams.name)
INSERT INTO real_teams (name, short_name) SELECT 'Atalanta', 'ATA' WHERE NOT EXISTS (SELECT 1 FROM real_teams WHERE LOWER(name) = LOWER('Atalanta'));
INSERT INTO real_teams (name, short_name) SELECT 'Bologna', 'BOL' WHERE NOT EXISTS (SELECT 1 FROM real_teams WHERE LOWER(name) = LOWER('Bologna'));
INSERT INTO real_teams (name, short_name) SELECT 'Cagliari', 'CAG' WHERE NOT EXISTS (SELECT 1 FROM real_teams WHERE LOWER(name) = LOWER('Cagliari'));
INSERT INTO real_teams (name, short_name) SELECT 'Como', 'COM' WHERE NOT EXISTS (SELECT 1 FROM real_teams WHERE LOWER(name) = LOWER('Como'));
INSERT INTO real_teams (name, short_name) SELECT 'Cremonese', 'CRE' WHERE NOT EXISTS (SELECT 1 FROM real_teams WHERE LOWER(name) = LOWER('Cremonese'));
INSERT INTO real_teams (name, short_name) SELECT 'Fiorentina', 'FIO' WHERE NOT EXISTS (SELECT 1 FROM real_teams WHERE LOWER(name) = LOWER('Fiorentina'));
INSERT INTO real_teams (name, short_name) SELECT 'Genoa', 'GEN' WHERE NOT EXISTS (SELECT 1 FROM real_teams WHERE LOWER(name) = LOWER('Genoa'));
INSERT INTO real_teams (name, short_name) SELECT 'Inter', 'INT' WHERE NOT EXISTS (SELECT 1 FROM real_teams WHERE LOWER(name) = LOWER('Inter'));
INSERT INTO real_teams (name, short_name) SELECT 'Juventus', 'JUV' WHERE NOT EXISTS (SELECT 1 FROM real_teams WHERE LOWER(name) = LOWER('Juventus'));
INSERT INTO real_teams (name, short_name) SELECT 'Lazio', 'LAZ' WHERE NOT EXISTS (SELECT 1 FROM real_teams WHERE LOWER(name) = LOWER('Lazio'));
INSERT INTO real_teams (name, short_name) SELECT 'Lecce', 'LEC' WHERE NOT EXISTS (SELECT 1 FROM real_teams WHERE LOWER(name) = LOWER('Lecce'));
INSERT INTO real_teams (name, short_name) SELECT 'Milan', 'MIL' WHERE NOT EXISTS (SELECT 1 FROM real_teams WHERE LOWER(name) = LOWER('Milan'));
INSERT INTO real_teams (name, short_name) SELECT 'Napoli', 'NAP' WHERE NOT EXISTS (SELECT 1 FROM real_teams WHERE LOWER(name) = LOWER('Napoli'));
INSERT INTO real_teams (name, short_name) SELECT 'Parma', 'PAR' WHERE NOT EXISTS (SELECT 1 FROM real_teams WHERE LOWER(name) = LOWER('Parma'));
INSERT INTO real_teams (name, short_name) SELECT 'Pisa', 'PIS' WHERE NOT EXISTS (SELECT 1 FROM real_teams WHERE LOWER(name) = LOWER('Pisa'));
INSERT INTO real_teams (name, short_name) SELECT 'Roma', 'ROM' WHERE NOT EXISTS (SELECT 1 FROM real_teams WHERE LOWER(name) = LOWER('Roma'));
INSERT INTO real_teams (name, short_name) SELECT 'Sassuolo', 'SAS' WHERE NOT EXISTS (SELECT 1 FROM real_teams WHERE LOWER(name) = LOWER('Sassuolo'));
INSERT INTO real_teams (name, short_name) SELECT 'Torino', 'TOR' WHERE NOT EXISTS (SELECT 1 FROM real_teams WHERE LOWER(name) = LOWER('Torino'));
INSERT INTO real_teams (name, short_name) SELECT 'Udinese', 'UDI' WHERE NOT EXISTS (SELECT 1 FROM real_teams WHERE LOWER(name) = LOWER('Udinese'));
INSERT INTO real_teams (name, short_name) SELECT 'Verona', 'VER' WHERE NOT EXISTS (SELECT 1 FROM real_teams WHERE LOWER(name) = LOWER('Verona'));

-- INSERISCI GIOCATORI MANCANTI (esempio: ripeti il pattern per tutti i 577 giocatori)
-- Formato: INSERT INTO players (name, position, initial_price, real_team_id, is_active)
--          SELECT 'Nome', 'POR'|'DIF'|'CEN'|'ATT', quota, rt.id, true FROM real_teams rt WHERE LOWER(rt.name) = LOWER('Squadra')
--          AND NOT EXISTS (SELECT 1 FROM players p INNER JOIN real_teams r ON p.real_team_id = r.id WHERE LOWER(p.name) = LOWER('Nome') AND LOWER(r.name) = LOWER('Squadra'));
-- Incolla qui le tue INSERT players (puoi lasciare ON CONFLICT DO NOTHING se non hai duplicati, oppure sostituire con AND NOT EXISTS come sopra).

COMMIT;
