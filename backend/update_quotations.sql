-- ============================================
-- AGGIORNAMENTO QUOTAZIONI FANTAMASTER 2025/2026
-- 577 giocatori - Match per cognome + squadra
-- ============================================
BEGIN;

-- Audero (Cremonese P = 17)
UPDATE players p SET quotation = 17, initial_price = 17
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%audero%')
  AND p.role = 'P';

-- Bijlow (Genoa P = 4)
UPDATE players p SET quotation = 4, initial_price = 4
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%genoa%')
  AND (LOWER(p.name) LIKE '%bijlow%')
  AND p.role = 'P';

-- Borghi (Verona P = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%borghi%')
  AND p.role = 'P';

-- Butez (Como P = 24)
UPDATE players p SET quotation = 24, initial_price = 24
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%como%')
  AND (LOWER(p.name) LIKE '%butez%')
  AND p.role = 'P';

-- Calligaris (Inter P = 2)
UPDATE players p SET quotation = 2, initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%calligaris%')
  AND p.role = 'P';

-- Caprile (Cagliari P = 20)
UPDATE players p SET quotation = 20, initial_price = 20
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cagliari%')
  AND (LOWER(p.name) LIKE '%caprile%')
  AND p.role = 'P';

-- Carnesecchi (Atalanta P = 25)
UPDATE players p SET quotation = 25, initial_price = 25
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%carnesecchi%')
  AND p.role = 'P';

-- Cavlina (Como P = 3)
UPDATE players p SET quotation = 3, initial_price = 3
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%como%')
  AND (LOWER(p.name) LIKE '%cavlina%')
  AND p.role = 'P';

-- Christensen (Fiorentina P = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%fiorentina%')
  AND (LOWER(p.name) LIKE '%christensen%')
  AND p.role = 'P';

-- Ciocci (Cagliari P = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cagliari%')
  AND (LOWER(p.name) LIKE '%ciocci%')
  AND p.role = 'P';

-- Contini (Napoli P = 2)
UPDATE players p SET quotation = 2, initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%napoli%')
  AND (LOWER(p.name) LIKE '%contini%')
  AND p.role = 'P';

-- Corvi (Parma P = 8)
UPDATE players p SET quotation = 8, initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%parma%')
  AND (LOWER(p.name) LIKE '%corvi%')
  AND p.role = 'P';

-- De Gea (Fiorentina P = 24)
UPDATE players p SET quotation = 24, initial_price = 24
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%fiorentina%')
  AND (LOWER(p.name) LIKE '%gea%')
  AND p.role = 'P';

-- Di Gennaro R (Inter P = 2)
UPDATE players p SET quotation = 2, initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%gennaro%')
  AND p.role = 'P';

-- Di Gregorio (Juventus P = 24)
UPDATE players p SET quotation = 24, initial_price = 24
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%juventus%' OR LOWER(rt.name) LIKE '%juve%')
  AND (LOWER(p.name) LIKE '%gregorio%')
  AND p.role = 'P';

-- Falcone (Lecce P = 25)
UPDATE players p SET quotation = 25, initial_price = 25
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lecce%')
  AND (LOWER(p.name) LIKE '%falcone%')
  AND p.role = 'P';

-- Ferrante (Napoli P = 2)
UPDATE players p SET quotation = 2, initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%napoli%')
  AND (LOWER(p.name) LIKE '%ferrante%')
  AND p.role = 'P';

-- Fruchtl (Lecce P = 2)
UPDATE players p SET quotation = 2, initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lecce%')
  AND (LOWER(p.name) LIKE '%fruchtl%')
  AND p.role = 'P';

-- Furlanetto (Lazio P = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lazio%')
  AND (LOWER(p.name) LIKE '%furlanetto%')
  AND p.role = 'P';

-- Gollini (Roma P = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%roma%' AND LOWER(rt.name) NOT LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%gollini%')
  AND p.role = 'P';

-- Israel (Torino P = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%israel%')
  AND p.role = 'P';

-- Leali (Genoa P = 15)
UPDATE players p SET quotation = 15, initial_price = 15
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%genoa%')
  AND (LOWER(p.name) LIKE '%leali%')
  AND p.role = 'P';

-- Lezzerini (Fiorentina P = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%fiorentina%')
  AND (LOWER(p.name) LIKE '%lezzerini%')
  AND p.role = 'P';

-- Maignan (Milan P = 25)
UPDATE players p SET quotation = 25, initial_price = 25
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%milan%' AND LOWER(rt.name) NOT LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%maignan%')
  AND p.role = 'P';

-- Martinez J (Inter P = 4)
UPDATE players p SET quotation = 4, initial_price = 4
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%martinez%')
  AND p.role = 'P';

-- Meret (Napoli P = 15)
UPDATE players p SET quotation = 15, initial_price = 15
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%napoli%')
  AND (LOWER(p.name) LIKE '%meret%')
  AND p.role = 'P';

-- Milinkovic-Savic V (Napoli P = 13)
UPDATE players p SET quotation = 13, initial_price = 13
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%napoli%')
  AND (LOWER(p.name) LIKE '%milinkovic-savic%')
  AND p.role = 'P';

-- Montipo' (Verona P = 19)
UPDATE players p SET quotation = 19, initial_price = 19
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%montipo''%')
  AND p.role = 'P';

-- Motta E (Lazio P = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lazio%')
  AND (LOWER(p.name) LIKE '%motta%')
  AND p.role = 'P';

-- Muric A (Sassuolo P = 11)
UPDATE players p SET quotation = 11, initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%sassuolo%')
  AND (LOWER(p.name) LIKE '%muric%')
  AND p.role = 'P';

-- Nava (Cremonese P = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%nava%')
  AND p.role = 'P';

-- Nicolas (Pisa P = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%pisa%')
  AND (LOWER(p.name) LIKE '%nicolas%')
  AND p.role = 'P';

-- Nunziante (Udinese P = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%udinese%')
  AND (LOWER(p.name) LIKE '%nunziante%')
  AND p.role = 'P';

-- Okoye (Udinese P = 12)
UPDATE players p SET quotation = 12, initial_price = 12
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%udinese%')
  AND (LOWER(p.name) LIKE '%okoye%')
  AND p.role = 'P';

-- Padelli (Udinese P = 2)
UPDATE players p SET quotation = 2, initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%udinese%')
  AND (LOWER(p.name) LIKE '%padelli%')
  AND p.role = 'P';

-- Paleari (Torino P = 11)
UPDATE players p SET quotation = 11, initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%paleari%')
  AND p.role = 'P';

-- Perilli (Verona P = 3)
UPDATE players p SET quotation = 3, initial_price = 3
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%perilli%')
  AND p.role = 'P';

-- Perin (Juventus P = 2)
UPDATE players p SET quotation = 2, initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%juventus%' OR LOWER(rt.name) LIKE '%juve%')
  AND (LOWER(p.name) LIKE '%perin%')
  AND p.role = 'P';

-- Pessina M (Bologna P = 3)
UPDATE players p SET quotation = 3, initial_price = 3
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%bologna%')
  AND (LOWER(p.name) LIKE '%pessina%')
  AND p.role = 'P';

-- Pinsoglio (Juventus P = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%juventus%' OR LOWER(rt.name) LIKE '%juve%')
  AND (LOWER(p.name) LIKE '%pinsoglio%')
  AND p.role = 'P';

-- Provedel (Lazio P = 19)
UPDATE players p SET quotation = 19, initial_price = 19
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lazio%')
  AND (LOWER(p.name) LIKE '%provedel%')
  AND p.role = 'P';

-- Ravaglia F (Bologna P = 7)
UPDATE players p SET quotation = 7, initial_price = 7
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%bologna%')
  AND (LOWER(p.name) LIKE '%ravaglia%')
  AND p.role = 'P';

-- Rinaldi (Parma P = 2)
UPDATE players p SET quotation = 2, initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%parma%')
  AND (LOWER(p.name) LIKE '%rinaldi%')
  AND p.role = 'P';

-- Rossi F (Atalanta P = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%rossi%')
  AND p.role = 'P';

-- Samooja (Lecce P = 2)
UPDATE players p SET quotation = 2, initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lecce%')
  AND (LOWER(p.name) LIKE '%samooja%')
  AND p.role = 'P';

-- Satalino (Sassuolo P = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%sassuolo%')
  AND (LOWER(p.name) LIKE '%satalino%')
  AND p.role = 'P';

-- Sava (Udinese P = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%udinese%')
  AND (LOWER(p.name) LIKE '%sava%')
  AND p.role = 'P';

-- Scuffet (Pisa P = 11)
UPDATE players p SET quotation = 11, initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%pisa%')
  AND (LOWER(p.name) LIKE '%scuffet%')
  AND p.role = 'P';

-- Semper (Pisa P = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%pisa%')
  AND (LOWER(p.name) LIKE '%semper%')
  AND p.role = 'P';

-- Sherri (Cagliari P = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cagliari%')
  AND (LOWER(p.name) LIKE '%sherri%')
  AND p.role = 'P';

-- Siegrist (Genoa P = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%genoa%')
  AND (LOWER(p.name) LIKE '%siegrist%')
  AND p.role = 'P';

-- Silvestri (Cremonese P = 4)
UPDATE players p SET quotation = 4, initial_price = 4
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%silvestri%')
  AND p.role = 'P';

-- Siviero (Torino P = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%siviero%')
  AND p.role = 'P';

-- Skorupski (Bologna P = 12)
UPDATE players p SET quotation = 12, initial_price = 12
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%bologna%')
  AND (LOWER(p.name) LIKE '%skorupski%')
  AND p.role = 'P';

-- Sommariva (Genoa P = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%genoa%')
  AND (LOWER(p.name) LIKE '%sommariva%')
  AND p.role = 'P';

-- Sommer (Inter P = 25)
UPDATE players p SET quotation = 25, initial_price = 25
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%sommer%')
  AND p.role = 'P';

-- Sportiello (Atalanta P = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%sportiello%')
  AND p.role = 'P';

-- Suzuki (Parma P = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%parma%')
  AND (LOWER(p.name) LIKE '%suzuki%')
  AND p.role = 'P';

-- Svilar (Roma P = 25)
UPDATE players p SET quotation = 25, initial_price = 25
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%roma%' AND LOWER(rt.name) NOT LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%svilar%')
  AND p.role = 'P';

-- Terracciano (Milan P = 5)
UPDATE players p SET quotation = 5, initial_price = 5
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%milan%' AND LOWER(rt.name) NOT LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%terracciano%')
  AND p.role = 'P';

-- Toniolo (Verona P = 2)
UPDATE players p SET quotation = 2, initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%toniolo%')
  AND p.role = 'P';

-- Tornqvist (Como P = 2)
UPDATE players p SET quotation = 2, initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%como%')
  AND (LOWER(p.name) LIKE '%tornqvist%')
  AND p.role = 'P';

-- Torriani (Milan P = 3)
UPDATE players p SET quotation = 3, initial_price = 3
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%milan%' AND LOWER(rt.name) NOT LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%torriani%')
  AND p.role = 'P';

-- Turati (Sassuolo P = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%sassuolo%')
  AND (LOWER(p.name) LIKE '%turati%')
  AND p.role = 'P';

-- Vigorito (Como P = 3)
UPDATE players p SET quotation = 3, initial_price = 3
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%como%')
  AND (LOWER(p.name) LIKE '%vigorito%')
  AND p.role = 'P';

-- Zacchi (Sassuolo P = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%sassuolo%')
  AND (LOWER(p.name) LIKE '%zacchi%')
  AND p.role = 'P';

-- Zelezny (Roma P = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%roma%' AND LOWER(rt.name) NOT LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%zelezny%')
  AND p.role = 'P';

-- Acerbi (Inter D = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%acerbi%')
  AND p.role = 'D';

-- Ahanor (Atalanta D = 8)
UPDATE players p SET quotation = 8, initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%ahanor%')
  AND p.role = 'D';

-- Akanji (Inter D = 16)
UPDATE players p SET quotation = 16, initial_price = 16
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%akanji%')
  AND p.role = 'D';

-- Albiol (Pisa D = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%pisa%')
  AND (LOWER(p.name) LIKE '%albiol%')
  AND p.role = 'D';

-- Alex Valle (Como D = 12)
UPDATE players p SET quotation = 12, initial_price = 12
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%como%')
  AND (LOWER(p.name) LIKE '%alex%' AND LOWER(p.name) LIKE '%valle%')
  AND p.role = 'D';

-- Alexiou (Inter D = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%alexiou%')
  AND p.role = 'D';

-- Angelino (Roma D = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%roma%' AND LOWER(rt.name) NOT LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%angelino%')
  AND p.role = 'D';

-- Angori (Pisa D = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%pisa%')
  AND (LOWER(p.name) LIKE '%angori%')
  AND p.role = 'D';

-- Arizala (Udinese D = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%udinese%')
  AND (LOWER(p.name) LIKE '%arizala%')
  AND p.role = 'D';

-- Athekame (Milan D = 11)
UPDATE players p SET quotation = 11, initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%milan%' AND LOWER(rt.name) NOT LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%athekame%')
  AND p.role = 'D';

-- Bakker (Atalanta D = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%bakker%')
  AND p.role = 'D';

-- Barbieri (Cremonese D = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%barbieri%')
  AND p.role = 'D';

-- Bartesaghi (Milan D = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%milan%' AND LOWER(rt.name) NOT LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%bartesaghi%')
  AND p.role = 'D';

-- Baschirotto (Cremonese D = 11)
UPDATE players p SET quotation = 11, initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%baschirotto%')
  AND p.role = 'D';

-- Bastoni (Inter D = 22)
UPDATE players p SET quotation = 22, initial_price = 22
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%bastoni%')
  AND p.role = 'D';

-- Belghali (Verona D = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%belghali%')
  AND p.role = 'D';

-- Bella-Kotchap (Verona D = 2)
UPDATE players p SET quotation = 2, initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%bella-kotchap%')
  AND p.role = 'D';

-- Bellanova (Atalanta D = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%bellanova%')
  AND p.role = 'D';

-- Bertola (Udinese D = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%udinese%')
  AND (LOWER(p.name) LIKE '%bertola%')
  AND p.role = 'D';

-- Beukema (Napoli D = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%napoli%')
  AND (LOWER(p.name) LIKE '%beukema%')
  AND p.role = 'D';

-- Bianchetti (Cremonese D = 6)
UPDATE players p SET quotation = 6, initial_price = 6
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%bianchetti%')
  AND p.role = 'D';

-- Biraghi (Torino D = 8)
UPDATE players p SET quotation = 8, initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%biraghi%')
  AND p.role = 'D';

-- Bisseck (Inter D = 16)
UPDATE players p SET quotation = 16, initial_price = 16
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%bisseck%')
  AND p.role = 'D';

-- Bonifazi (Bologna D = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%bologna%')
  AND (LOWER(p.name) LIKE '%bonifazi%')
  AND p.role = 'D';

-- Bozhinov (Pisa D = 2)
UPDATE players p SET quotation = 2, initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%pisa%')
  AND (LOWER(p.name) LIKE '%bozhinov%')
  AND p.role = 'D';

-- Bradaric D (Verona D = 6)
UPDATE players p SET quotation = 6, initial_price = 6
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%bradaric%')
  AND p.role = 'D';

-- Bremer (Juventus D = 17)
UPDATE players p SET quotation = 17, initial_price = 17
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%juventus%' OR LOWER(rt.name) LIKE '%juve%')
  AND (LOWER(p.name) LIKE '%bremer%')
  AND p.role = 'D';

-- Britschgi (Parma D = 5)
UPDATE players p SET quotation = 5, initial_price = 5
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%parma%')
  AND (LOWER(p.name) LIKE '%britschgi%')
  AND p.role = 'D';

-- Buongiorno (Napoli D = 11)
UPDATE players p SET quotation = 11, initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%napoli%')
  AND (LOWER(p.name) LIKE '%buongiorno%')
  AND p.role = 'D';

-- Cabal (Juventus D = 7)
UPDATE players p SET quotation = 7, initial_price = 7
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%juventus%' OR LOWER(rt.name) LIKE '%juve%')
  AND (LOWER(p.name) LIKE '%cabal%')
  AND p.role = 'D';

-- Calabresi (Pisa D = 8)
UPDATE players p SET quotation = 8, initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%pisa%')
  AND (LOWER(p.name) LIKE '%calabresi%')
  AND p.role = 'D';

-- Cambiaso (Juventus D = 12)
UPDATE players p SET quotation = 12, initial_price = 12
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%juventus%' OR LOWER(rt.name) LIKE '%juve%')
  AND (LOWER(p.name) LIKE '%cambiaso%')
  AND p.role = 'D';

-- Cande (Sassuolo D = 5)
UPDATE players p SET quotation = 5, initial_price = 5
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%sassuolo%')
  AND (LOWER(p.name) LIKE '%cande%')
  AND p.role = 'D';

-- Canestrelli (Pisa D = 6)
UPDATE players p SET quotation = 6, initial_price = 6
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%pisa%')
  AND (LOWER(p.name) LIKE '%canestrelli%')
  AND p.role = 'D';

-- Caracciolo A (Pisa D = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%pisa%')
  AND (LOWER(p.name) LIKE '%caracciolo%')
  AND p.role = 'D';

-- Carboni F (Parma D = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%parma%')
  AND (LOWER(p.name) LIKE '%carboni%')
  AND p.role = 'D';

-- Carlos Augusto (Inter D = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%carlos%' AND LOWER(p.name) LIKE '%augusto%')
  AND p.role = 'D';

-- Casale (Bologna D = 4)
UPDATE players p SET quotation = 4, initial_price = 4
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%bologna%')
  AND (LOWER(p.name) LIKE '%casale%')
  AND p.role = 'D';

-- Ceccherini (Cremonese D = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%ceccherini%')
  AND p.role = 'D';

-- Celik (Roma D = 13)
UPDATE players p SET quotation = 13, initial_price = 13
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%roma%' AND LOWER(rt.name) NOT LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%celik%')
  AND p.role = 'D';

-- Cham (Verona D = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%cham%')
  AND p.role = 'D';

-- Circati (Parma D = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%parma%')
  AND (LOWER(p.name) LIKE '%circati%')
  AND p.role = 'D';

-- Cocchi (Inter D = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%cocchi%')
  AND p.role = 'D';

-- Coco S (Torino D = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%coco%')
  AND p.role = 'D';

-- Comi (Atalanta D = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%comi%')
  AND p.role = 'D';

-- Comuzzo (Fiorentina D = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%fiorentina%')
  AND (LOWER(p.name) LIKE '%comuzzo%')
  AND p.role = 'D';

-- Coppola Fr (Pisa D = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%pisa%')
  AND (LOWER(p.name) LIKE '%coppola%')
  AND p.role = 'D';

-- Coulibaly W (Sassuolo D = 7)
UPDATE players p SET quotation = 7, initial_price = 7
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%sassuolo%')
  AND (LOWER(p.name) LIKE '%coulibaly%')
  AND p.role = 'D';

-- Cuadrado (Pisa D = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%pisa%')
  AND (LOWER(p.name) LIKE '%cuadrado%')
  AND p.role = 'D';

-- Danilo Veiga (Lecce D = 8)
UPDATE players p SET quotation = 8, initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lecce%')
  AND (LOWER(p.name) LIKE '%danilo%' AND LOWER(p.name) LIKE '%veiga%')
  AND p.role = 'D';

-- Darmian (Inter D = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%darmian%')
  AND p.role = 'D';

-- De Silvestri (Bologna D = 6)
UPDATE players p SET quotation = 6, initial_price = 6
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%bologna%')
  AND (LOWER(p.name) LIKE '%silvestri%')
  AND p.role = 'D';

-- De Vrij (Inter D = 7)
UPDATE players p SET quotation = 7, initial_price = 7
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%vrij%')
  AND p.role = 'D';

-- De Winter (Milan D = 12)
UPDATE players p SET quotation = 12, initial_price = 12
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%milan%' AND LOWER(rt.name) NOT LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%winter%')
  AND p.role = 'D';

-- Delprato (Parma D = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%parma%')
  AND (LOWER(p.name) LIKE '%delprato%')
  AND p.role = 'D';

-- Denoon (Pisa D = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%pisa%')
  AND (LOWER(p.name) LIKE '%denoon%')
  AND p.role = 'D';

-- Di Lorenzo (Napoli D = 17)
UPDATE players p SET quotation = 17, initial_price = 17
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%napoli%')
  AND (LOWER(p.name) LIKE '%lorenzo%')
  AND p.role = 'D';

-- Diego Carlos (Como D = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%como%')
  AND (LOWER(p.name) LIKE '%diego%' AND LOWER(p.name) LIKE '%carlos%')
  AND p.role = 'D';

-- Dimarco (Inter D = 25)
UPDATE players p SET quotation = 25, initial_price = 25
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%dimarco%')
  AND p.role = 'D';

-- Djimsiti (Atalanta D = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%djimsiti%')
  AND p.role = 'D';

-- Dodo D (Fiorentina D = 12)
UPDATE players p SET quotation = 12, initial_price = 12
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%fiorentina%')
  AND (LOWER(p.name) LIKE '%dodo%')
  AND p.role = 'D';

-- Doig (Sassuolo D = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%sassuolo%')
  AND (LOWER(p.name) LIKE '%doig%')
  AND p.role = 'D';

-- Dossena A (Cagliari D = 5)
UPDATE players p SET quotation = 5, initial_price = 5
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cagliari%')
  AND (LOWER(p.name) LIKE '%dossena%')
  AND p.role = 'D';

-- Dumfries (Inter D = 14)
UPDATE players p SET quotation = 14, initial_price = 14
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%dumfries%')
  AND p.role = 'D';

-- Ebosse (Torino D = 2)
UPDATE players p SET quotation = 2, initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%ebosse%')
  AND p.role = 'D';

-- Edmundsson (Verona D = 3)
UPDATE players p SET quotation = 3, initial_price = 3
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%edmundsson%')
  AND p.role = 'D';

-- Ehizibue (Udinese D = 5)
UPDATE players p SET quotation = 5, initial_price = 5
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%udinese%')
  AND (LOWER(p.name) LIKE '%ehizibue%')
  AND p.role = 'D';

-- Estupinan (Milan D = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%milan%' AND LOWER(rt.name) NOT LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%estupinan%')
  AND p.role = 'D';

-- Faye (Cremonese D = 3)
UPDATE players p SET quotation = 3, initial_price = 3
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%faye%')
  AND p.role = 'D';

-- Feola (Verona D = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%feola%')
  AND p.role = 'D';

-- Floriani M (Cremonese D = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%floriani%')
  AND p.role = 'D';

-- Folino (Cremonese D = 5)
UPDATE players p SET quotation = 5, initial_price = 5
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%folino%')
  AND p.role = 'D';

-- Fortini (Fiorentina D = 6)
UPDATE players p SET quotation = 6, initial_price = 6
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%fiorentina%')
  AND (LOWER(p.name) LIKE '%fortini%')
  AND p.role = 'D';

-- Frese (Verona D = 6)
UPDATE players p SET quotation = 6, initial_price = 6
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%frese%')
  AND p.role = 'D';

-- Gabbia (Milan D = 11)
UPDATE players p SET quotation = 11, initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%milan%' AND LOWER(rt.name) NOT LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%gabbia%')
  AND p.role = 'D';

-- Gallo (Lecce D = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lecce%')
  AND (LOWER(p.name) LIKE '%gallo%')
  AND p.role = 'D';

-- Gaspar K (Lecce D = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lecce%')
  AND (LOWER(p.name) LIKE '%gaspar%')
  AND p.role = 'D';

-- Gatti (Juventus D = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%juventus%' OR LOWER(rt.name) LIKE '%juve%')
  AND (LOWER(p.name) LIKE '%gatti%')
  AND p.role = 'D';

-- Ghilardi (Roma D = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%roma%' AND LOWER(rt.name) NOT LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%ghilardi%')
  AND p.role = 'D';

-- Gigot (Lazio D = 5)
UPDATE players p SET quotation = 5, initial_price = 5
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lazio%')
  AND (LOWER(p.name) LIKE '%gigot%')
  AND p.role = 'D';

-- Gila (Lazio D = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lazio%')
  AND (LOWER(p.name) LIKE '%gila%')
  AND p.role = 'D';

-- Goldaniga (Como D = 5)
UPDATE players p SET quotation = 5, initial_price = 5
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%como%')
  AND (LOWER(p.name) LIKE '%goldaniga%')
  AND p.role = 'D';

-- Gosens (Fiorentina D = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%fiorentina%')
  AND (LOWER(p.name) LIKE '%gosens%')
  AND p.role = 'D';

-- Gutierrez M (Napoli D = 8)
UPDATE players p SET quotation = 8, initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%napoli%')
  AND (LOWER(p.name) LIKE '%gutierrez%')
  AND p.role = 'D';

-- Heggem (Bologna D = 8)
UPDATE players p SET quotation = 8, initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%bologna%')
  AND (LOWER(p.name) LIKE '%heggem%')
  AND p.role = 'D';

-- Helland (Bologna D = 5)
UPDATE players p SET quotation = 5, initial_price = 5
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%bologna%')
  AND (LOWER(p.name) LIKE '%helland%')
  AND p.role = 'D';

-- Hermoso (Roma D = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%roma%' AND LOWER(rt.name) NOT LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%hermoso%')
  AND p.role = 'D';

-- Hien (Atalanta D = 11)
UPDATE players p SET quotation = 11, initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%hien%')
  AND p.role = 'D';

-- Holm (Juventus D = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%juventus%' OR LOWER(rt.name) LIKE '%juve%')
  AND (LOWER(p.name) LIKE '%holm%')
  AND p.role = 'D';

-- Hysaj (Lazio D = 2)
UPDATE players p SET quotation = 2, initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lazio%')
  AND (LOWER(p.name) LIKE '%hysaj%')
  AND p.role = 'D';

-- Idrissi (Cagliari D = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cagliari%')
  AND (LOWER(p.name) LIKE '%idrissi%')
  AND p.role = 'D';

-- Idzes (Sassuolo D = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%sassuolo%')
  AND (LOWER(p.name) LIKE '%idzes%')
  AND p.role = 'D';

-- Ismajli (Torino D = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%ismajli%')
  AND p.role = 'D';

-- Jakirovic (Inter D = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%jakirovic%')
  AND p.role = 'D';

-- Jean (Lecce D = 3)
UPDATE players p SET quotation = 3, initial_price = 3
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lecce%')
  AND (LOWER(p.name) LIKE '%jean%')
  AND p.role = 'D';

-- Joao Mario N (Bologna D = 7)
UPDATE players p SET quotation = 7, initial_price = 7
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%bologna%')
  AND (LOWER(p.name) LIKE '%joao%' AND LOWER(p.name) LIKE '%mario%')
  AND p.role = 'D';

-- Juan Jesus (Napoli D = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%napoli%')
  AND (LOWER(p.name) LIKE '%juan%' AND LOWER(p.name) LIKE '%jesus%')
  AND p.role = 'D';

-- Kabasele (Udinese D = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%udinese%')
  AND (LOWER(p.name) LIKE '%kabasele%')
  AND p.role = 'D';

-- Kalulu (Juventus D = 20)
UPDATE players p SET quotation = 20, initial_price = 20
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%juventus%' OR LOWER(rt.name) LIKE '%juve%')
  AND (LOWER(p.name) LIKE '%kalulu%')
  AND p.role = 'D';

-- Kamara (Udinese D = 8)
UPDATE players p SET quotation = 8, initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%udinese%')
  AND (LOWER(p.name) LIKE '%kamara%')
  AND p.role = 'D';

-- Kelly (Juventus D = 12)
UPDATE players p SET quotation = 12, initial_price = 12
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%juventus%' OR LOWER(rt.name) LIKE '%juve%')
  AND (LOWER(p.name) LIKE '%kelly%')
  AND p.role = 'D';

-- Kempf (Como D = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%como%')
  AND (LOWER(p.name) LIKE '%kempf%')
  AND p.role = 'D';

-- Kolasinac (Atalanta D = 11)
UPDATE players p SET quotation = 11, initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%kolasinac%')
  AND p.role = 'D';

-- Kospo (Fiorentina D = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%fiorentina%')
  AND (LOWER(p.name) LIKE '%kospo%')
  AND p.role = 'D';

-- Kossounou (Atalanta D = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%kossounou%')
  AND p.role = 'D';

-- Kouadio (Fiorentina D = 2)
UPDATE players p SET quotation = 2, initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%fiorentina%')
  AND (LOWER(p.name) LIKE '%kouadio%')
  AND p.role = 'D';

-- Kristensen T (Udinese D = 8)
UPDATE players p SET quotation = 8, initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%udinese%')
  AND (LOWER(p.name) LIKE '%kristensen%')
  AND p.role = 'D';

-- Kumer Celik (Genoa D = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%genoa%')
  AND (LOWER(p.name) LIKE '%kumer%' AND LOWER(p.name) LIKE '%celik%')
  AND p.role = 'D';

-- Lamptey (Fiorentina D = 4)
UPDATE players p SET quotation = 4, initial_price = 4
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%fiorentina%')
  AND (LOWER(p.name) LIKE '%lamptey%')
  AND p.role = 'D';

-- Lazaro (Torino D = 8)
UPDATE players p SET quotation = 8, initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%lazaro%')
  AND p.role = 'D';

-- Lazzari M (Lazio D = 7)
UPDATE players p SET quotation = 7, initial_price = 7
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lazio%')
  AND (LOWER(p.name) LIKE '%lazzari%')
  AND p.role = 'D';

-- Lirola (Verona D = 3)
UPDATE players p SET quotation = 3, initial_price = 3
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%lirola%')
  AND p.role = 'D';

-- Lucumi (Bologna D = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%bologna%')
  AND (LOWER(p.name) LIKE '%lucumi%')
  AND p.role = 'D';

-- Luperto (Cremonese D = 12)
UPDATE players p SET quotation = 12, initial_price = 12
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%luperto%')
  AND p.role = 'D';

-- Lykogiannis (Bologna D = 6)
UPDATE players p SET quotation = 6, initial_price = 6
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%bologna%')
  AND (LOWER(p.name) LIKE '%lykogiannis%')
  AND p.role = 'D';

-- Macchioni (Sassuolo D = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%sassuolo%')
  AND (LOWER(p.name) LIKE '%macchioni%')
  AND p.role = 'D';

-- Mancini (Roma D = 18)
UPDATE players p SET quotation = 18, initial_price = 18
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%roma%' AND LOWER(rt.name) NOT LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%mancini%')
  AND p.role = 'D';

-- Marcandalli (Genoa D = 8)
UPDATE players p SET quotation = 8, initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%genoa%')
  AND (LOWER(p.name) LIKE '%marcandalli%')
  AND p.role = 'D';

-- Marianucci (Torino D = 4)
UPDATE players p SET quotation = 4, initial_price = 4
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%marianucci%')
  AND p.role = 'D';

-- Maripan (Torino D = 11)
UPDATE players p SET quotation = 11, initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%maripan%')
  AND p.role = 'D';

-- Martin (Genoa D = 16)
UPDATE players p SET quotation = 16, initial_price = 16
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%genoa%')
  AND (LOWER(p.name) LIKE '%martin%')
  AND p.role = 'D';

-- Marusic (Lazio D = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lazio%')
  AND (LOWER(p.name) LIKE '%marusic%')
  AND p.role = 'D';

-- Mathias Olivera (Napoli D = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%napoli%')
  AND (LOWER(p.name) LIKE '%mathias%' AND LOWER(p.name) LIKE '%olivera%')
  AND p.role = 'D';

-- Mazzocchi (Napoli D = 3)
UPDATE players p SET quotation = 3, initial_price = 3
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%napoli%')
  AND (LOWER(p.name) LIKE '%mazzocchi%')
  AND p.role = 'D';

-- Mina (Cagliari D = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cagliari%')
  AND (LOWER(p.name) LIKE '%mina%')
  AND p.role = 'D';

-- Miranda J (Bologna D = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%bologna%')
  AND (LOWER(p.name) LIKE '%miranda%')
  AND p.role = 'D';

-- Mlacic (Udinese D = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%udinese%')
  AND (LOWER(p.name) LIKE '%mlacic%')
  AND p.role = 'D';

-- Moreno A (Como D = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%como%')
  AND (LOWER(p.name) LIKE '%moreno%')
  AND p.role = 'D';

-- Muharemovic (Sassuolo D = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%sassuolo%')
  AND (LOWER(p.name) LIKE '%muharemovic%')
  AND p.role = 'D';

-- Ndaba (Lecce D = 3)
UPDATE players p SET quotation = 3, initial_price = 3
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lecce%')
  AND (LOWER(p.name) LIKE '%ndaba%')
  AND p.role = 'D';

-- Ndiaye A (Parma D = 2)
UPDATE players p SET quotation = 2, initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%parma%')
  AND (LOWER(p.name) LIKE '%ndiaye%')
  AND p.role = 'D';

-- Ndicka (Roma D = 11)
UPDATE players p SET quotation = 11, initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%roma%' AND LOWER(rt.name) NOT LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%ndicka%')
  AND p.role = 'D';

-- Nelsson (Verona D = 7)
UPDATE players p SET quotation = 7, initial_price = 7
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%nelsson%')
  AND p.role = 'D';

-- Nkounkou (Torino D = 5)
UPDATE players p SET quotation = 5, initial_price = 5
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%nkounkou%')
  AND p.role = 'D';

-- Norton-Cuffy (Genoa D = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%genoa%')
  AND (LOWER(p.name) LIKE '%norton-cuffy%')
  AND p.role = 'D';

-- Nuno Tavares (Lazio D = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lazio%')
  AND (LOWER(p.name) LIKE '%nuno%' AND LOWER(p.name) LIKE '%tavares%')
  AND p.role = 'D';

-- Obert (Cagliari D = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cagliari%')
  AND (LOWER(p.name) LIKE '%obert%')
  AND p.role = 'D';

-- Obrador (Torino D = 3)
UPDATE players p SET quotation = 3, initial_price = 3
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%obrador%')
  AND p.role = 'D';

-- Obric (Atalanta D = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%obric%')
  AND p.role = 'D';

-- Odogu (Milan D = 3)
UPDATE players p SET quotation = 3, initial_price = 3
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%milan%' AND LOWER(rt.name) NOT LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%odogu%')
  AND p.role = 'D';

-- Ostigard (Genoa D = 11)
UPDATE players p SET quotation = 11, initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%genoa%')
  AND (LOWER(p.name) LIKE '%ostigard%')
  AND p.role = 'D';

-- Otoa (Genoa D = 3)
UPDATE players p SET quotation = 3, initial_price = 3
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%genoa%')
  AND (LOWER(p.name) LIKE '%otoa%')
  AND p.role = 'D';

-- Oyegoke (Verona D = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%oyegoke%')
  AND p.role = 'D';

-- Parisi F (Fiorentina D = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%fiorentina%')
  AND (LOWER(p.name) LIKE '%parisi%')
  AND p.role = 'D';

-- Patric (Lazio D = 4)
UPDATE players p SET quotation = 4, initial_price = 4
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lazio%')
  AND (LOWER(p.name) LIKE '%patric%')
  AND p.role = 'D';

-- Pavlovic S (Milan D = 12)
UPDATE players p SET quotation = 12, initial_price = 12
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%milan%' AND LOWER(rt.name) NOT LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%pavlovic%')
  AND p.role = 'D';

-- Pedersen (Torino D = 4)
UPDATE players p SET quotation = 4, initial_price = 4
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%pedersen%')
  AND p.role = 'D';

-- Pedro Felipe (Sassuolo D = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%sassuolo%')
  AND (LOWER(p.name) LIKE '%pedro%' AND LOWER(p.name) LIKE '%felipe%')
  AND p.role = 'D';

-- Pellegrini Lu (Lazio D = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lazio%')
  AND (LOWER(p.name) LIKE '%pellegrini%')
  AND p.role = 'D';

-- Pellini (Torino D = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%pellini%')
  AND p.role = 'D';

-- Perez A (Torino D = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%perez%')
  AND p.role = 'D';

-- Perez M (Lecce D = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lecce%')
  AND (LOWER(p.name) LIKE '%perez%')
  AND p.role = 'D';

-- Pezzella (Cremonese D = 7)
UPDATE players p SET quotation = 7, initial_price = 7
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%pezzella%')
  AND p.role = 'D';

-- Pieragnolo (Sassuolo D = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%sassuolo%')
  AND (LOWER(p.name) LIKE '%pieragnolo%')
  AND p.role = 'D';

-- Pongracic (Fiorentina D = 8)
UPDATE players p SET quotation = 8, initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%fiorentina%')
  AND (LOWER(p.name) LIKE '%pongracic%')
  AND p.role = 'D';

-- Provstgaard (Lazio D = 8)
UPDATE players p SET quotation = 8, initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lazio%')
  AND (LOWER(p.name) LIKE '%provstgaard%')
  AND p.role = 'D';

-- Ramon J (Como D = 14)
UPDATE players p SET quotation = 14, initial_price = 14
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%como%')
  AND (LOWER(p.name) LIKE '%ramon%')
  AND p.role = 'D';

-- Ranieri (Fiorentina D = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%fiorentina%')
  AND (LOWER(p.name) LIKE '%ranieri%')
  AND p.role = 'D';

-- Raterink (Cagliari D = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cagliari%')
  AND (LOWER(p.name) LIKE '%raterink%')
  AND p.role = 'D';

-- Rensch (Roma D = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%roma%' AND LOWER(rt.name) NOT LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%rensch%')
  AND p.role = 'D';

-- Rocchetti (Cremonese D = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%rocchetti%')
  AND p.role = 'D';

-- Rodriguez Ju (Cagliari D = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cagliari%')
  AND (LOWER(p.name) LIKE '%rodriguez%')
  AND p.role = 'D';

-- Romagna (Sassuolo D = 2)
UPDATE players p SET quotation = 2, initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%sassuolo%')
  AND (LOWER(p.name) LIKE '%romagna%')
  AND p.role = 'D';

-- Romagnoli A (Lazio D = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lazio%')
  AND (LOWER(p.name) LIKE '%romagnoli%')
  AND p.role = 'D';

-- Rrahmani (Napoli D = 11)
UPDATE players p SET quotation = 11, initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%napoli%')
  AND (LOWER(p.name) LIKE '%rrahmani%')
  AND p.role = 'D';

-- Rugani (Fiorentina D = 4)
UPDATE players p SET quotation = 4, initial_price = 4
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%fiorentina%')
  AND (LOWER(p.name) LIKE '%rugani%')
  AND p.role = 'D';

-- Sabelli (Genoa D = 4)
UPDATE players p SET quotation = 4, initial_price = 4
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%genoa%')
  AND (LOWER(p.name) LIKE '%sabelli%')
  AND p.role = 'D';

-- Sangare' (Roma D = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%roma%' AND LOWER(rt.name) NOT LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%sangare''%')
  AND p.role = 'D';

-- Sazonov (Torino D = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%sazonov%')
  AND p.role = 'D';

-- Scalvini (Atalanta D = 11)
UPDATE players p SET quotation = 11, initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%scalvini%')
  AND p.role = 'D';

-- Scott (Lecce D = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lecce%')
  AND (LOWER(p.name) LIKE '%scott%')
  AND p.role = 'D';

-- Siebert (Lecce D = 4)
UPDATE players p SET quotation = 4, initial_price = 4
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lecce%')
  AND (LOWER(p.name) LIKE '%siebert%')
  AND p.role = 'D';

-- Slotsager (Verona D = 2)
UPDATE players p SET quotation = 2, initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%slotsager%')
  AND p.role = 'D';

-- Smolcic (Como D = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%como%')
  AND (LOWER(p.name) LIKE '%smolcic%')
  AND p.role = 'D';

-- Solet (Udinese D = 15)
UPDATE players p SET quotation = 15, initial_price = 15
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%udinese%')
  AND (LOWER(p.name) LIKE '%solet%')
  AND p.role = 'D';

-- Spinazzola (Napoli D = 14)
UPDATE players p SET quotation = 14, initial_price = 14
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%napoli%')
  AND (LOWER(p.name) LIKE '%spinazzola%')
  AND p.role = 'D';

-- Terracciano F (Cremonese D = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%terracciano%')
  AND p.role = 'D';

-- Tiago Gabriel (Lecce D = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lecce%')
  AND (LOWER(p.name) LIKE '%tiago%' AND LOWER(p.name) LIKE '%gabriel%')
  AND p.role = 'D';

-- Tomori (Milan D = 11)
UPDATE players p SET quotation = 11, initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%milan%' AND LOWER(rt.name) NOT LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%tomori%')
  AND p.role = 'D';

-- Troilo (Parma D = 3)
UPDATE players p SET quotation = 3, initial_price = 3
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%parma%')
  AND (LOWER(p.name) LIKE '%troilo%')
  AND p.role = 'D';

-- Tsimikas (Roma D = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%roma%' AND LOWER(rt.name) NOT LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%tsimikas%')
  AND p.role = 'D';

-- Ulisses Garcia (Sassuolo D = 6)
UPDATE players p SET quotation = 6, initial_price = 6
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%sassuolo%')
  AND (LOWER(p.name) LIKE '%ulisses%' AND LOWER(p.name) LIKE '%garcia%')
  AND p.role = 'D';

-- Valenti (Parma D = 8)
UPDATE players p SET quotation = 8, initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%parma%')
  AND (LOWER(p.name) LIKE '%valenti%')
  AND p.role = 'D';

-- Valentini N (Verona D = 4)
UPDATE players p SET quotation = 4, initial_price = 4
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%valentini%')
  AND p.role = 'D';

-- Valeri (Parma D = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%parma%')
  AND (LOWER(p.name) LIKE '%valeri%')
  AND p.role = 'D';

-- Van der Brempt (Como D = 8)
UPDATE players p SET quotation = 8, initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%como%')
  AND (LOWER(p.name) LIKE '%van%' AND LOWER(p.name) LIKE '%der%' AND LOWER(p.name) LIKE '%brempt%')
  AND p.role = 'D';

-- Vasquez (Genoa D = 12)
UPDATE players p SET quotation = 12, initial_price = 12
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%genoa%')
  AND (LOWER(p.name) LIKE '%vasquez%')
  AND p.role = 'D';

-- Vitik (Bologna D = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%bologna%')
  AND (LOWER(p.name) LIKE '%vitik%')
  AND p.role = 'D';

-- Vojvoda (Como D = 11)
UPDATE players p SET quotation = 11, initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%como%')
  AND (LOWER(p.name) LIKE '%vojvoda%')
  AND p.role = 'D';

-- Walukiewicz (Sassuolo D = 8)
UPDATE players p SET quotation = 8, initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%sassuolo%')
  AND (LOWER(p.name) LIKE '%walukiewicz%')
  AND p.role = 'D';

-- Wesley F (Roma D = 15)
UPDATE players p SET quotation = 15, initial_price = 15
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%roma%' AND LOWER(rt.name) NOT LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%wesley%')
  AND p.role = 'D';

-- Zaia (Torino D = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%zaia%')
  AND p.role = 'D';

-- Zalewski (Atalanta D = 15)
UPDATE players p SET quotation = 15, initial_price = 15
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%zalewski%')
  AND p.role = 'D';

-- Zanoli (Udinese D = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%udinese%')
  AND (LOWER(p.name) LIKE '%zanoli%')
  AND p.role = 'D';

-- Zappa (Cagliari D = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cagliari%')
  AND (LOWER(p.name) LIKE '%zappa%')
  AND p.role = 'D';

-- Zappacosta (Atalanta D = 13)
UPDATE players p SET quotation = 13, initial_price = 13
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%zappacosta%')
  AND p.role = 'D';

-- Zatterstrom (Genoa D = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%genoa%')
  AND (LOWER(p.name) LIKE '%zatterstrom%')
  AND p.role = 'D';

-- Ze Pedro (Cagliari D = 5)
UPDATE players p SET quotation = 5, initial_price = 5
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cagliari%')
  AND (LOWER(p.name) LIKE '%pedro%')
  AND p.role = 'D';

-- Zemura (Udinese D = 7)
UPDATE players p SET quotation = 7, initial_price = 7
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%udinese%')
  AND (LOWER(p.name) LIKE '%zemura%')
  AND p.role = 'D';

-- Ziolkowski (Roma D = 6)
UPDATE players p SET quotation = 6, initial_price = 6
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%roma%' AND LOWER(rt.name) NOT LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%ziolkowski%')
  AND p.role = 'D';

-- Zortea (Bologna D = 11)
UPDATE players p SET quotation = 11, initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%bologna%')
  AND (LOWER(p.name) LIKE '%zortea%')
  AND p.role = 'D';

-- Addai (Como C = 6)
UPDATE players p SET quotation = 6, initial_price = 6
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%como%')
  AND (LOWER(p.name) LIKE '%addai%')
  AND p.role = 'C';

-- Adopo (Cagliari C = 8)
UPDATE players p SET quotation = 8, initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cagliari%')
  AND (LOWER(p.name) LIKE '%adopo%')
  AND p.role = 'C';

-- Adzic (Juventus C = 4)
UPDATE players p SET quotation = 4, initial_price = 4
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%juventus%' OR LOWER(rt.name) LIKE '%juve%')
  AND (LOWER(p.name) LIKE '%adzic%')
  AND p.role = 'C';

-- Aebischer (Pisa C = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%pisa%')
  AND (LOWER(p.name) LIKE '%aebischer%')
  AND p.role = 'C';

-- Agbonifo (Inter C = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%agbonifo%')
  AND p.role = 'C';

-- Akinsanmiro (Pisa C = 8)
UPDATE players p SET quotation = 8, initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%pisa%')
  AND (LOWER(p.name) LIKE '%akinsanmiro%')
  AND p.role = 'C';

-- Akpa-Akpro (Verona C = 2)
UPDATE players p SET quotation = 2, initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%akpa-akpro%')
  AND p.role = 'C';

-- Al-Musrati (Verona C = 7)
UPDATE players p SET quotation = 7, initial_price = 7
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%al-musrati%')
  AND p.role = 'C';

-- Alex Sala (Lecce C = 5)
UPDATE players p SET quotation = 5, initial_price = 5
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lecce%')
  AND (LOWER(p.name) LIKE '%alex%' AND LOWER(p.name) LIKE '%sala%')
  AND p.role = 'C';

-- Alisson Santos (Napoli C = 8)
UPDATE players p SET quotation = 8, initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%napoli%')
  AND (LOWER(p.name) LIKE '%alisson%' AND LOWER(p.name) LIKE '%santos%')
  AND p.role = 'C';

-- Amorim (Genoa C = 2)
UPDATE players p SET quotation = 2, initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%genoa%')
  AND (LOWER(p.name) LIKE '%amorim%')
  AND p.role = 'C';

-- Anguissa (Napoli C = 15)
UPDATE players p SET quotation = 15, initial_price = 15
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%napoli%')
  AND (LOWER(p.name) LIKE '%anguissa%')
  AND p.role = 'C';

-- Anjorin (Torino C = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%anjorin%')
  AND p.role = 'C';

-- Assane Diao (Como C = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%como%')
  AND (LOWER(p.name) LIKE '%assane%' AND LOWER(p.name) LIKE '%diao%')
  AND p.role = 'C';

-- Atta (Udinese C = 13)
UPDATE players p SET quotation = 13, initial_price = 13
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%udinese%')
  AND (LOWER(p.name) LIKE '%atta%')
  AND p.role = 'C';

-- Bakola (Sassuolo C = 3)
UPDATE players p SET quotation = 3, initial_price = 3
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%sassuolo%')
  AND (LOWER(p.name) LIKE '%bakola%')
  AND p.role = 'C';

-- Baldanzi (Genoa C = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%genoa%')
  AND (LOWER(p.name) LIKE '%baldanzi%')
  AND p.role = 'C';

-- Barella (Inter C = 28)
UPDATE players p SET quotation = 28, initial_price = 28
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%barella%')
  AND p.role = 'C';

-- Basic (Lazio C = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lazio%')
  AND (LOWER(p.name) LIKE '%basic%')
  AND p.role = 'C';

-- Baturina (Como C = 16)
UPDATE players p SET quotation = 16, initial_price = 16
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%como%')
  AND (LOWER(p.name) LIKE '%baturina%')
  AND p.role = 'C';

-- Belahyane (Lazio C = 4)
UPDATE players p SET quotation = 4, initial_price = 4
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lazio%')
  AND (LOWER(p.name) LIKE '%belahyane%')
  AND p.role = 'C';

-- Berenbruch (Inter C = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%berenbruch%')
  AND p.role = 'C';

-- Berisha M (Lecce C = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lecce%')
  AND (LOWER(p.name) LIKE '%berisha%')
  AND p.role = 'C';

-- Bernabe' (Parma C = 18)
UPDATE players p SET quotation = 18, initial_price = 18
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%parma%')
  AND (LOWER(p.name) LIKE '%bernabe''%')
  AND p.role = 'C';

-- Bernardeschi (Bologna C = 11)
UPDATE players p SET quotation = 11, initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%bologna%')
  AND (LOWER(p.name) LIKE '%bernardeschi%')
  AND p.role = 'C';

-- Bernasconi (Atalanta C = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%bernasconi%')
  AND p.role = 'C';

-- Bernede (Verona C = 5)
UPDATE players p SET quotation = 5, initial_price = 5
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%bernede%')
  AND p.role = 'C';

-- Boloca (Sassuolo C = 6)
UPDATE players p SET quotation = 6, initial_price = 6
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%sassuolo%')
  AND (LOWER(p.name) LIKE '%boloca%')
  AND p.role = 'C';

-- Bondo (Cremonese C = 8)
UPDATE players p SET quotation = 8, initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%bondo%')
  AND p.role = 'C';

-- Brescianini (Fiorentina C = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%fiorentina%')
  AND (LOWER(p.name) LIKE '%brescianini%')
  AND p.role = 'C';

-- Calhanoglu (Inter C = 27)
UPDATE players p SET quotation = 27, initial_price = 27
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%calhanoglu%')
  AND p.role = 'C';

-- Caqueret (Como C = 12)
UPDATE players p SET quotation = 12, initial_price = 12
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%como%')
  AND (LOWER(p.name) LIKE '%caqueret%')
  AND p.role = 'C';

-- Casadei (Torino C = 12)
UPDATE players p SET quotation = 12, initial_price = 12
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%casadei%')
  AND p.role = 'C';

-- Cassa (Atalanta C = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%cassa%')
  AND p.role = 'C';

-- Cataldi (Lazio C = 11)
UPDATE players p SET quotation = 11, initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lazio%')
  AND (LOWER(p.name) LIKE '%cataldi%')
  AND p.role = 'C';

-- Caviglia (Parma C = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%parma%')
  AND (LOWER(p.name) LIKE '%caviglia%')
  AND p.role = 'C';

-- Collocolo (Cremonese C = 7)
UPDATE players p SET quotation = 7, initial_price = 7
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%collocolo%')
  AND p.role = 'C';

-- Conceicao (Juventus C = 17)
UPDATE players p SET quotation = 17, initial_price = 17
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%juventus%' OR LOWER(rt.name) LIKE '%juve%')
  AND (LOWER(p.name) LIKE '%conceicao%')
  AND p.role = 'C';

-- Cornet (Genoa C = 4)
UPDATE players p SET quotation = 4, initial_price = 4
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%genoa%')
  AND (LOWER(p.name) LIKE '%cornet%')
  AND p.role = 'C';

-- Coulibaly L (Lecce C = 12)
UPDATE players p SET quotation = 12, initial_price = 12
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lecce%')
  AND (LOWER(p.name) LIKE '%coulibaly%')
  AND p.role = 'C';

-- Crapisto (Juventus C = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%juventus%' OR LOWER(rt.name) LIKE '%juve%')
  AND (LOWER(p.name) LIKE '%crapisto%')
  AND p.role = 'C';

-- Cremaschi (Parma C = 4)
UPDATE players p SET quotation = 4, initial_price = 4
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%parma%')
  AND (LOWER(p.name) LIKE '%cremaschi%')
  AND p.role = 'C';

-- Cristante (Roma C = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%roma%' AND LOWER(rt.name) NOT LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%cristante%')
  AND p.role = 'C';

-- Da Cunha (Como C = 13)
UPDATE players p SET quotation = 13, initial_price = 13
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%como%')
  AND (LOWER(p.name) LIKE '%cunha%')
  AND p.role = 'C';

-- De Bruyne (Napoli C = 13)
UPDATE players p SET quotation = 13, initial_price = 13
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%napoli%')
  AND (LOWER(p.name) LIKE '%bruyne%')
  AND p.role = 'C';

-- De Ketelaere (Atalanta C = 20)
UPDATE players p SET quotation = 20, initial_price = 20
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%ketelaere%')
  AND p.role = 'C';

-- De Roon (Atalanta C = 11)
UPDATE players p SET quotation = 11, initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%roon%')
  AND p.role = 'C';

-- Deiola (Cagliari C = 7)
UPDATE players p SET quotation = 7, initial_price = 7
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cagliari%')
  AND (LOWER(p.name) LIKE '%deiola%')
  AND p.role = 'C';

-- Dele Bashiru (Lazio C = 4)
UPDATE players p SET quotation = 4, initial_price = 4
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lazio%')
  AND (LOWER(p.name) LIKE '%dele%' AND LOWER(p.name) LIKE '%bashiru%')
  AND p.role = 'C';

-- Diouf A (Inter C = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%diouf%')
  AND p.role = 'C';

-- Dominguez B (Bologna C = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%bologna%')
  AND (LOWER(p.name) LIKE '%dominguez%')
  AND p.role = 'C';

-- Ederson J (Atalanta C = 13)
UPDATE players p SET quotation = 13, initial_price = 13
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%ederson%')
  AND p.role = 'C';

-- Ekkelenkamp (Udinese C = 12)
UPDATE players p SET quotation = 12, initial_price = 12
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%udinese%')
  AND (LOWER(p.name) LIKE '%ekkelenkamp%')
  AND p.role = 'C';

-- El Aynaoui (Roma C = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%roma%' AND LOWER(rt.name) NOT LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%aynaoui%')
  AND p.role = 'C';

-- Ellertsson (Genoa C = 7)
UPDATE players p SET quotation = 7, initial_price = 7
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%genoa%')
  AND (LOWER(p.name) LIKE '%ellertsson%')
  AND p.role = 'C';

-- Elmas (Napoli C = 11)
UPDATE players p SET quotation = 11, initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%napoli%')
  AND (LOWER(p.name) LIKE '%elmas%')
  AND p.role = 'C';

-- Estevez (Parma C = 5)
UPDATE players p SET quotation = 5, initial_price = 5
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%parma%')
  AND (LOWER(p.name) LIKE '%estevez%')
  AND p.role = 'C';

-- Fabbian (Fiorentina C = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%fiorentina%')
  AND (LOWER(p.name) LIKE '%fabbian%')
  AND p.role = 'C';

-- Fadera (Sassuolo C = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%sassuolo%')
  AND (LOWER(p.name) LIKE '%fadera%')
  AND p.role = 'C';

-- Fagioli (Fiorentina C = 15)
UPDATE players p SET quotation = 15, initial_price = 15
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%fiorentina%')
  AND (LOWER(p.name) LIKE '%fagioli%')
  AND p.role = 'C';

-- Fazzini (Fiorentina C = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%fiorentina%')
  AND (LOWER(p.name) LIKE '%fazzini%')
  AND p.role = 'C';

-- Felici (Cagliari C = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cagliari%')
  AND (LOWER(p.name) LIKE '%felici%')
  AND p.role = 'C';

-- Ferguson (Bologna C = 11)
UPDATE players p SET quotation = 11, initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%bologna%')
  AND (LOWER(p.name) LIKE '%ferguson%')
  AND p.role = 'C';

-- Fofana S (Lecce C = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lecce%')
  AND (LOWER(p.name) LIKE '%fofana%')
  AND p.role = 'C';

-- Fofana Y (Milan C = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%milan%' AND LOWER(rt.name) NOT LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%fofana%')
  AND p.role = 'C';

-- Folorunsho (Cagliari C = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cagliari%')
  AND (LOWER(p.name) LIKE '%folorunsho%')
  AND p.role = 'C';

-- Frattesi (Inter C = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%frattesi%')
  AND p.role = 'C';

-- Frendrup (Genoa C = 13)
UPDATE players p SET quotation = 13, initial_price = 13
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%genoa%')
  AND (LOWER(p.name) LIKE '%frendrup%')
  AND p.role = 'C';

-- Freuler (Bologna C = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%bologna%')
  AND (LOWER(p.name) LIKE '%freuler%')
  AND p.role = 'C';

-- Gaetano (Cagliari C = 13)
UPDATE players p SET quotation = 13, initial_price = 13
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cagliari%')
  AND (LOWER(p.name) LIKE '%gaetano%')
  AND p.role = 'C';

-- Gagliardini (Verona C = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%gagliardini%')
  AND p.role = 'C';

-- Gandelman (Lecce C = 7)
UPDATE players p SET quotation = 7, initial_price = 7
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lecce%')
  AND (LOWER(p.name) LIKE '%gandelman%')
  AND p.role = 'C';

-- Gilmour (Napoli C = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%napoli%')
  AND (LOWER(p.name) LIKE '%gilmour%')
  AND p.role = 'C';

-- Gineitis (Torino C = 6)
UPDATE players p SET quotation = 6, initial_price = 6
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%gineitis%')
  AND p.role = 'C';

-- Gorter (Lecce C = 2)
UPDATE players p SET quotation = 2, initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lecce%')
  AND (LOWER(p.name) LIKE '%gorter%')
  AND p.role = 'C';

-- Grassi (Cremonese C = 3)
UPDATE players p SET quotation = 3, initial_price = 3
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%grassi%')
  AND p.role = 'C';

-- Harrison (Fiorentina C = 5)
UPDATE players p SET quotation = 5, initial_price = 5
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%fiorentina%')
  AND (LOWER(p.name) LIKE '%harrison%')
  AND p.role = 'C';

-- Harroui (Verona C = 6)
UPDATE players p SET quotation = 6, initial_price = 6
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%harroui%')
  AND p.role = 'C';

-- Helgason (Lecce C = 5)
UPDATE players p SET quotation = 5, initial_price = 5
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lecce%')
  AND (LOWER(p.name) LIKE '%helgason%')
  AND p.role = 'C';

-- Hojholt (Pisa C = 2)
UPDATE players p SET quotation = 2, initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%pisa%')
  AND (LOWER(p.name) LIKE '%hojholt%')
  AND p.role = 'C';

-- Iannoni (Sassuolo C = 5)
UPDATE players p SET quotation = 5, initial_price = 5
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%sassuolo%')
  AND (LOWER(p.name) LIKE '%iannoni%')
  AND p.role = 'C';

-- Ilic (Torino C = 8)
UPDATE players p SET quotation = 8, initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%ilic%')
  AND p.role = 'C';

-- Iling-Junior (Pisa C = 5)
UPDATE players p SET quotation = 5, initial_price = 5
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%pisa%')
  AND (LOWER(p.name) LIKE '%iling-junior%')
  AND p.role = 'C';

-- Ilkhan (Torino C = 5)
UPDATE players p SET quotation = 5, initial_price = 5
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%ilkhan%')
  AND p.role = 'C';

-- Isaksen (Lazio C = 14)
UPDATE players p SET quotation = 14, initial_price = 14
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lazio%')
  AND (LOWER(p.name) LIKE '%isaksen%')
  AND p.role = 'C';

-- Jashari (Milan C = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%milan%' AND LOWER(rt.name) NOT LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%jashari%')
  AND p.role = 'C';

-- Kamate (Inter C = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%kamate%')
  AND p.role = 'C';

-- Karlstrom (Udinese C = 8)
UPDATE players p SET quotation = 8, initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%udinese%')
  AND (LOWER(p.name) LIKE '%karlstrom%')
  AND p.role = 'C';

-- Kone I (Sassuolo C = 16)
UPDATE players p SET quotation = 16, initial_price = 16
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%sassuolo%')
  AND (LOWER(p.name) LIKE '%kone%')
  AND p.role = 'C';

-- Koopmeiners (Juventus C = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%juventus%' OR LOWER(rt.name) LIKE '%juve%')
  AND (LOWER(p.name) LIKE '%koopmeiners%')
  AND p.role = 'C';

-- Kostic (Juventus C = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%juventus%' OR LOWER(rt.name) LIKE '%juve%')
  AND (LOWER(p.name) LIKE '%kostic%')
  AND p.role = 'C';

-- Kuhn (Como C = 11)
UPDATE players p SET quotation = 11, initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%como%')
  AND (LOWER(p.name) LIKE '%kuhn%')
  AND p.role = 'C';

-- Lafont G (Genoa C = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%genoa%')
  AND (LOWER(p.name) LIKE '%lafont%')
  AND p.role = 'C';

-- Lahdo (Como C = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%como%')
  AND (LOWER(p.name) LIKE '%lahdo%')
  AND p.role = 'C';

-- Leris (Pisa C = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%pisa%')
  AND (LOWER(p.name) LIKE '%leris%')
  AND p.role = 'C';

-- Lipani (Sassuolo C = 5)
UPDATE players p SET quotation = 5, initial_price = 5
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%sassuolo%')
  AND (LOWER(p.name) LIKE '%lipani%')
  AND p.role = 'C';

-- Liteta (Cagliari C = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cagliari%')
  AND (LOWER(p.name) LIKE '%liteta%')
  AND p.role = 'C';

-- Lobotka (Napoli C = 12)
UPDATE players p SET quotation = 12, initial_price = 12
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%napoli%')
  AND (LOWER(p.name) LIKE '%lobotka%')
  AND p.role = 'C';

-- Locatelli M (Juventus C = 17)
UPDATE players p SET quotation = 17, initial_price = 17
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%juventus%' OR LOWER(rt.name) LIKE '%juve%')
  AND (LOWER(p.name) LIKE '%locatelli%')
  AND p.role = 'C';

-- Loftus-Cheek (Milan C = 15)
UPDATE players p SET quotation = 15, initial_price = 15
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%milan%' AND LOWER(rt.name) NOT LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%loftus-cheek%')
  AND p.role = 'C';

-- Lorran (Pisa C = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%pisa%')
  AND (LOWER(p.name) LIKE '%lorran%')
  AND p.role = 'C';

-- Lovric (Verona C = 8)
UPDATE players p SET quotation = 8, initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%lovric%')
  AND p.role = 'C';

-- Loyola (Pisa C = 6)
UPDATE players p SET quotation = 6, initial_price = 6
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%pisa%')
  AND (LOWER(p.name) LIKE '%loyola%')
  AND p.role = 'C';

-- Luis Henrique (Inter C = 11)
UPDATE players p SET quotation = 11, initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%luis%' AND LOWER(p.name) LIKE '%henrique%')
  AND p.role = 'C';

-- Maldini D (Lazio C = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lazio%')
  AND (LOWER(p.name) LIKE '%maldini%')
  AND p.role = 'C';

-- Maleh (Cremonese C = 7)
UPDATE players p SET quotation = 7, initial_price = 7
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%maleh%')
  AND p.role = 'C';

-- Malinovskyi (Genoa C = 15)
UPDATE players p SET quotation = 15, initial_price = 15
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%genoa%')
  AND (LOWER(p.name) LIKE '%malinovskyi%')
  AND p.role = 'C';

-- Mandela Keita (Parma C = 12)
UPDATE players p SET quotation = 12, initial_price = 12
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%parma%')
  AND (LOWER(p.name) LIKE '%mandela%' AND LOWER(p.name) LIKE '%keita%')
  AND p.role = 'C';

-- Mandragora (Fiorentina C = 19)
UPDATE players p SET quotation = 19, initial_price = 19
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%fiorentina%')
  AND (LOWER(p.name) LIKE '%mandragora%')
  AND p.role = 'C';

-- Manu Kone (Roma C = 19)
UPDATE players p SET quotation = 19, initial_price = 19
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%roma%' AND LOWER(rt.name) NOT LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%manu%' AND LOWER(p.name) LIKE '%kone%')
  AND p.role = 'C';

-- Manzoni A (Atalanta C = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%manzoni%')
  AND p.role = 'C';

-- Marchwinski (Lecce C = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lecce%')
  AND (LOWER(p.name) LIKE '%marchwinski%')
  AND p.role = 'C';

-- Marin M (Pisa C = 5)
UPDATE players p SET quotation = 5, initial_price = 5
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%pisa%')
  AND (LOWER(p.name) LIKE '%marin%')
  AND p.role = 'C';

-- Masini (Genoa C = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%genoa%')
  AND (LOWER(p.name) LIKE '%masini%')
  AND p.role = 'C';

-- Matic (Sassuolo C = 12)
UPDATE players p SET quotation = 12, initial_price = 12
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%sassuolo%')
  AND (LOWER(p.name) LIKE '%matic%')
  AND p.role = 'C';

-- Mazzitelli (Cagliari C = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cagliari%')
  AND (LOWER(p.name) LIKE '%mazzitelli%')
  AND p.role = 'C';

-- McKennie (Juventus C = 22)
UPDATE players p SET quotation = 22, initial_price = 22
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%juventus%' OR LOWER(rt.name) LIKE '%juve%')
  AND (LOWER(p.name) LIKE '%mckennie%')
  AND p.role = 'C';

-- McTominay (Napoli C = 34)
UPDATE players p SET quotation = 34, initial_price = 34
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%napoli%')
  AND (LOWER(p.name) LIKE '%mctominay%')
  AND p.role = 'C';

-- Messias (Genoa C = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%genoa%')
  AND (LOWER(p.name) LIKE '%messias%')
  AND p.role = 'C';

-- Miller (Udinese C = 3)
UPDATE players p SET quotation = 3, initial_price = 3
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%udinese%')
  AND (LOWER(p.name) LIKE '%miller%')
  AND p.role = 'C';

-- Miretti (Juventus C = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%juventus%' OR LOWER(rt.name) LIKE '%juve%')
  AND (LOWER(p.name) LIKE '%miretti%')
  AND p.role = 'C';

-- Mkhitaryan (Inter C = 11)
UPDATE players p SET quotation = 11, initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%mkhitaryan%')
  AND p.role = 'C';

-- Modric (Milan C = 25)
UPDATE players p SET quotation = 25, initial_price = 25
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%milan%' AND LOWER(rt.name) NOT LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%modric%')
  AND p.role = 'C';

-- Moro N (Bologna C = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%bologna%')
  AND (LOWER(p.name) LIKE '%moro%')
  AND p.role = 'C';

-- Munoz (Lazio C = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lazio%')
  AND (LOWER(p.name) LIKE '%munoz%')
  AND p.role = 'C';

-- Musah (Atalanta C = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%musah%')
  AND p.role = 'C';

-- Ndour (Fiorentina C = 7)
UPDATE players p SET quotation = 7, initial_price = 7
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%fiorentina%')
  AND (LOWER(p.name) LIKE '%ndour%')
  AND p.role = 'C';

-- Neres (Napoli C = 15)
UPDATE players p SET quotation = 15, initial_price = 15
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%napoli%')
  AND (LOWER(p.name) LIKE '%neres%')
  AND p.role = 'C';

-- Ngom (Lecce C = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lecce%')
  AND (LOWER(p.name) LIKE '%ngom%')
  AND p.role = 'C';

-- Niasse (Verona C = 7)
UPDATE players p SET quotation = 7, initial_price = 7
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%niasse%')
  AND p.role = 'C';

-- Nico Paz (Como C = 32)
UPDATE players p SET quotation = 32, initial_price = 32
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%como%')
  AND (LOWER(p.name) LIKE '%nico%' AND LOWER(p.name) LIKE '%paz%')
  AND p.role = 'C';

-- Njie (Torino C = 5)
UPDATE players p SET quotation = 5, initial_price = 5
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%njie%')
  AND p.role = 'C';

-- Onana J (Genoa C = 2)
UPDATE players p SET quotation = 2, initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%genoa%')
  AND (LOWER(p.name) LIKE '%onana%')
  AND p.role = 'C';

-- Ondrejka (Parma C = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%parma%')
  AND (LOWER(p.name) LIKE '%ondrejka%')
  AND p.role = 'C';

-- Ordonez (Parma C = 8)
UPDATE players p SET quotation = 8, initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%parma%')
  AND (LOWER(p.name) LIKE '%ordonez%')
  AND p.role = 'C';

-- Oristanio (Parma C = 8)
UPDATE players p SET quotation = 8, initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%parma%')
  AND (LOWER(p.name) LIKE '%oristanio%')
  AND p.role = 'C';

-- Orsolini (Bologna C = 29)
UPDATE players p SET quotation = 29, initial_price = 29
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%bologna%')
  AND (LOWER(p.name) LIKE '%orsolini%')
  AND p.role = 'C';

-- Palestra (Cagliari C = 15)
UPDATE players p SET quotation = 15, initial_price = 15
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cagliari%')
  AND (LOWER(p.name) LIKE '%palestra%')
  AND p.role = 'C';

-- Papadopoulos (Atalanta C = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%papadopoulos%')
  AND p.role = 'C';

-- Pasalic (Atalanta C = 13)
UPDATE players p SET quotation = 13, initial_price = 13
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%pasalic%')
  AND p.role = 'C';

-- Payero (Cremonese C = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%payero%')
  AND p.role = 'C';

-- Pellegrini (Roma C = 11)
UPDATE players p SET quotation = 11, initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%roma%' AND LOWER(rt.name) NOT LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%pellegrini%')
  AND p.role = 'C';

-- Perciun (Torino C = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%perciun%')
  AND p.role = 'C';

-- Perrone (Como C = 16)
UPDATE players p SET quotation = 16, initial_price = 16
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%como%')
  AND (LOWER(p.name) LIKE '%perrone%')
  AND p.role = 'C';

-- Piccinini G (Pisa C = 8)
UPDATE players p SET quotation = 8, initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%pisa%')
  AND (LOWER(p.name) LIKE '%piccinini%')
  AND p.role = 'C';

-- Piotrowski (Udinese C = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%udinese%')
  AND (LOWER(p.name) LIKE '%piotrowski%')
  AND p.role = 'C';

-- Pisilli (Roma C = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%roma%' AND LOWER(rt.name) NOT LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%pisilli%')
  AND p.role = 'C';

-- Plicco (Parma C = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%parma%')
  AND (LOWER(p.name) LIKE '%plicco%')
  AND p.role = 'C';

-- Pobega (Bologna C = 7)
UPDATE players p SET quotation = 7, initial_price = 7
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%bologna%')
  AND (LOWER(p.name) LIKE '%pobega%')
  AND p.role = 'C';

-- Prati (Torino C = 7)
UPDATE players p SET quotation = 7, initial_price = 7
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%prati%')
  AND p.role = 'C';

-- Przyborek (Lazio C = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lazio%')
  AND (LOWER(p.name) LIKE '%przyborek%')
  AND p.role = 'C';

-- Pulisic (Milan C = 31)
UPDATE players p SET quotation = 31, initial_price = 31
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%milan%' AND LOWER(rt.name) NOT LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%pulisic%')
  AND p.role = 'C';

-- Rabiot (Milan C = 23)
UPDATE players p SET quotation = 23, initial_price = 23
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%milan%' AND LOWER(rt.name) NOT LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%rabiot%')
  AND p.role = 'C';

-- Ramadani (Lecce C = 12)
UPDATE players p SET quotation = 12, initial_price = 12
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lecce%')
  AND (LOWER(p.name) LIKE '%ramadani%')
  AND p.role = 'C';

-- Ricci S (Milan C = 16)
UPDATE players p SET quotation = 16, initial_price = 16
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%milan%' AND LOWER(rt.name) NOT LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%ricci%')
  AND p.role = 'C';

-- Rodriguez J (Como C = 12)
UPDATE players p SET quotation = 12, initial_price = 12
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%como%')
  AND (LOWER(p.name) LIKE '%rodriguez%')
  AND p.role = 'C';

-- Rovella (Lazio C = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lazio%')
  AND (LOWER(p.name) LIKE '%rovella%')
  AND p.role = 'C';

-- Rowe (Bologna C = 12)
UPDATE players p SET quotation = 12, initial_price = 12
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%bologna%')
  AND (LOWER(p.name) LIKE '%rowe%')
  AND p.role = 'C';

-- Sabiri (Fiorentina C = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%fiorentina%')
  AND (LOWER(p.name) LIKE '%sabiri%')
  AND p.role = 'C';

-- Saelemaekers (Milan C = 18)
UPDATE players p SET quotation = 18, initial_price = 18
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%milan%' AND LOWER(rt.name) NOT LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%saelemaekers%')
  AND p.role = 'C';

-- Samardzic (Atalanta C = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%samardzic%')
  AND p.role = 'C';

-- Serdar (Verona C = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%serdar%')
  AND p.role = 'C';

-- Sergi Roberto (Como C = 7)
UPDATE players p SET quotation = 7, initial_price = 7
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%como%')
  AND (LOWER(p.name) LIKE '%sergi%' AND LOWER(p.name) LIKE '%roberto%')
  AND p.role = 'C';

-- Sohm (Bologna C = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%bologna%')
  AND (LOWER(p.name) LIKE '%sohm%')
  AND p.role = 'C';

-- Sorensen O (Parma C = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%parma%')
  AND (LOWER(p.name) LIKE '%sorensen%')
  AND p.role = 'C';

-- Sottil (Lecce C = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lecce%')
  AND (LOWER(p.name) LIKE '%sottil%')
  AND p.role = 'C';

-- Soule (Roma C = 26)
UPDATE players p SET quotation = 26, initial_price = 26
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%roma%' AND LOWER(rt.name) NOT LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%soule%')
  AND p.role = 'C';

-- Stengs (Pisa C = 5)
UPDATE players p SET quotation = 5, initial_price = 5
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%pisa%')
  AND (LOWER(p.name) LIKE '%stengs%')
  AND p.role = 'C';

-- Strefezza (Parma C = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%parma%')
  AND (LOWER(p.name) LIKE '%strefezza%')
  AND p.role = 'C';

-- Sucic (Inter C = 11)
UPDATE players p SET quotation = 11, initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%sucic%')
  AND p.role = 'C';

-- Sulemana (Cagliari C = 5)
UPDATE players p SET quotation = 5, initial_price = 5
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cagliari%')
  AND (LOWER(p.name) LIKE '%sulemana%')
  AND p.role = 'C';

-- Sulemana K (Atalanta C = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%sulemana%')
  AND p.role = 'C';

-- Suslov (Verona C = 8)
UPDATE players p SET quotation = 8, initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%suslov%')
  AND p.role = 'C';

-- Tameze (Torino C = 5)
UPDATE players p SET quotation = 5, initial_price = 5
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%tameze%')
  AND p.role = 'C';

-- Taylor (Lazio C = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lazio%')
  AND (LOWER(p.name) LIKE '%taylor%')
  AND p.role = 'C';

-- Thorsby (Cremonese C = 12)
UPDATE players p SET quotation = 12, initial_price = 12
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%thorsby%')
  AND p.role = 'C';

-- Thorstvedt (Sassuolo C = 12)
UPDATE players p SET quotation = 12, initial_price = 12
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%sassuolo%')
  AND (LOWER(p.name) LIKE '%thorstvedt%')
  AND p.role = 'C';

-- Thuram K (Juventus C = 20)
UPDATE players p SET quotation = 20, initial_price = 20
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%juventus%' OR LOWER(rt.name) LIKE '%juve%')
  AND (LOWER(p.name) LIKE '%thuram%')
  AND p.role = 'C';

-- Tomczyk (Bologna C = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%bologna%')
  AND (LOWER(p.name) LIKE '%tomczyk%')
  AND p.role = 'C';

-- Topalovic (Inter C = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%topalovic%')
  AND p.role = 'C';

-- Toure Id (Pisa C = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%pisa%')
  AND (LOWER(p.name) LIKE '%toure%')
  AND p.role = 'C';

-- Tramoni (Pisa C = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%pisa%')
  AND (LOWER(p.name) LIKE '%tramoni%')
  AND p.role = 'C';

-- Traore C (Milan C = 2)
UPDATE players p SET quotation = 2, initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%milan%' AND LOWER(rt.name) NOT LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%traore%')
  AND p.role = 'C';

-- Vandeputte (Cremonese C = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%vandeputte%')
  AND p.role = 'C';

-- Vergara (Napoli C = 5)
UPDATE players p SET quotation = 5, initial_price = 5
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%napoli%')
  AND (LOWER(p.name) LIKE '%vergara%')
  AND p.role = 'C';

-- Vlasic (Torino C = 18)
UPDATE players p SET quotation = 18, initial_price = 18
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%vlasic%')
  AND p.role = 'C';

-- Volpato C (Sassuolo C = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%sassuolo%')
  AND (LOWER(p.name) LIKE '%volpato%')
  AND p.role = 'C';

-- Vos (Milan C = 2)
UPDATE players p SET quotation = 2, initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%milan%' AND LOWER(rt.name) NOT LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%vos%')
  AND p.role = 'C';

-- Vranckx (Sassuolo C = 3)
UPDATE players p SET quotation = 3, initial_price = 3
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%sassuolo%')
  AND (LOWER(p.name) LIKE '%vranckx%')
  AND p.role = 'C';

-- Vural (Pisa C = 3)
UPDATE players p SET quotation = 3, initial_price = 3
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%pisa%')
  AND (LOWER(p.name) LIKE '%vural%')
  AND p.role = 'C';

-- Yildiz V (Verona C = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%yildiz%')
  AND p.role = 'C';

-- Yilmaz (Lecce C = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lecce%')
  AND (LOWER(p.name) LIKE '%yilmaz%')
  AND p.role = 'C';

-- Zaccagni (Lazio C = 20)
UPDATE players p SET quotation = 20, initial_price = 20
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lazio%')
  AND (LOWER(p.name) LIKE '%zaccagni%')
  AND p.role = 'C';

-- Zaniolo (Udinese C = 18)
UPDATE players p SET quotation = 18, initial_price = 18
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%udinese%')
  AND (LOWER(p.name) LIKE '%zaniolo%')
  AND p.role = 'C';

-- Zaragoza (Roma C = 11)
UPDATE players p SET quotation = 11, initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%roma%' AND LOWER(rt.name) NOT LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%zaragoza%')
  AND p.role = 'C';

-- Zarraga (Udinese C = 4)
UPDATE players p SET quotation = 4, initial_price = 4
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%udinese%')
  AND (LOWER(p.name) LIKE '%zarraga%')
  AND p.role = 'C';

-- Zerbin (Cremonese C = 7)
UPDATE players p SET quotation = 7, initial_price = 7
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%zerbin%')
  AND p.role = 'C';

-- Zhegrova (Juventus C = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%juventus%' OR LOWER(rt.name) LIKE '%juve%')
  AND (LOWER(p.name) LIKE '%zhegrova%')
  AND p.role = 'C';

-- Zielinski (Inter C = 21)
UPDATE players p SET quotation = 21, initial_price = 21
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%zielinski%')
  AND p.role = 'C';

-- Aboukhlal (Torino A = 8)
UPDATE players p SET quotation = 8, initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%aboukhlal%')
  AND p.role = 'A';

-- Adams (Torino A = 14)
UPDATE players p SET quotation = 14, initial_price = 14
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%adams%')
  AND p.role = 'A';

-- Ajayi (Verona A = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%ajayi%')
  AND p.role = 'A';

-- Albarracin (Cagliari A = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cagliari%')
  AND (LOWER(p.name) LIKE '%albarracin%')
  AND p.role = 'A';

-- Almqvist (Parma A = 2)
UPDATE players p SET quotation = 2, initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%parma%')
  AND (LOWER(p.name) LIKE '%almqvist%')
  AND p.role = 'A';

-- Amin Sarr (Verona A = 8)
UPDATE players p SET quotation = 8, initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%amin%' AND LOWER(p.name) LIKE '%sarr%')
  AND p.role = 'A';

-- Anghele (Juventus A = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%juventus%' OR LOWER(rt.name) LIKE '%juve%')
  AND (LOWER(p.name) LIKE '%anghele%')
  AND p.role = 'A';

-- Arena A (Roma A = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%roma%' AND LOWER(rt.name) NOT LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%arena%')
  AND p.role = 'A';

-- Balentien (Milan A = 2)
UPDATE players p SET quotation = 2, initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%milan%' AND LOWER(rt.name) NOT LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%balentien%')
  AND p.role = 'A';

-- Banda (Lecce A = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lecce%')
  AND (LOWER(p.name) LIKE '%banda%')
  AND p.role = 'A';

-- Bayo (Udinese A = 2)
UPDATE players p SET quotation = 2, initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%udinese%')
  AND (LOWER(p.name) LIKE '%bayo%')
  AND p.role = 'A';

-- Belotti (Cagliari A = 6)
UPDATE players p SET quotation = 6, initial_price = 6
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cagliari%')
  AND (LOWER(p.name) LIKE '%belotti%')
  AND p.role = 'A';

-- Berardi (Sassuolo A = 18)
UPDATE players p SET quotation = 18, initial_price = 18
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%sassuolo%')
  AND (LOWER(p.name) LIKE '%berardi%')
  AND p.role = 'A';

-- Boga (Juventus A = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%juventus%' OR LOWER(rt.name) LIKE '%juve%')
  AND (LOWER(p.name) LIKE '%boga%')
  AND p.role = 'A';

-- Bonazzoli (Cremonese A = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%bonazzoli%')
  AND p.role = 'A';

-- Bonny (Inter A = 11)
UPDATE players p SET quotation = 11, initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%bonny%')
  AND p.role = 'A';

-- Borrelli (Cagliari A = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cagliari%')
  AND (LOWER(p.name) LIKE '%borrelli%')
  AND p.role = 'A';

-- Bowie (Verona A = 5)
UPDATE players p SET quotation = 5, initial_price = 5
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%bowie%')
  AND p.role = 'A';

-- Buksa A (Udinese A = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%udinese%')
  AND (LOWER(p.name) LIKE '%buksa%')
  AND p.role = 'A';

-- Camarda (Lecce A = 3)
UPDATE players p SET quotation = 3, initial_price = 3
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lecce%')
  AND (LOWER(p.name) LIKE '%camarda%')
  AND p.role = 'A';

-- Cambiaghi (Bologna A = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%bologna%')
  AND (LOWER(p.name) LIKE '%cambiaghi%')
  AND p.role = 'A';

-- Cancellieri (Lazio A = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lazio%')
  AND (LOWER(p.name) LIKE '%cancellieri%')
  AND p.role = 'A';

-- Castro S (Bologna A = 20)
UPDATE players p SET quotation = 20, initial_price = 20
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%bologna%')
  AND (LOWER(p.name) LIKE '%castro%')
  AND p.role = 'A';

-- Cheddira (Lecce A = 4)
UPDATE players p SET quotation = 4, initial_price = 4
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lecce%')
  AND (LOWER(p.name) LIKE '%cheddira%')
  AND p.role = 'A';

-- Colombo (Genoa A = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%genoa%')
  AND (LOWER(p.name) LIKE '%colombo%')
  AND p.role = 'A';

-- Dallinga (Bologna A = 8)
UPDATE players p SET quotation = 8, initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%bologna%')
  AND (LOWER(p.name) LIKE '%dallinga%')
  AND p.role = 'A';

-- David (Juventus A = 21)
UPDATE players p SET quotation = 21, initial_price = 21
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%juventus%' OR LOWER(rt.name) LIKE '%juve%')
  AND (LOWER(p.name) LIKE '%david%')
  AND p.role = 'A';

-- Davis (Udinese A = 12)
UPDATE players p SET quotation = 12, initial_price = 12
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%udinese%')
  AND (LOWER(p.name) LIKE '%davis%')
  AND p.role = 'A';

-- Dia (Lazio A = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lazio%')
  AND (LOWER(p.name) LIKE '%dia%')
  AND p.role = 'A';

-- Djuric (Cremonese A = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%djuric%')
  AND p.role = 'A';

-- Douvikas (Como A = 15)
UPDATE players p SET quotation = 15, initial_price = 15
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%como%')
  AND (LOWER(p.name) LIKE '%douvikas%')
  AND p.role = 'A';

-- Dovbyk (Roma A = 16)
UPDATE players p SET quotation = 16, initial_price = 16
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%roma%' AND LOWER(rt.name) NOT LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%dovbyk%')
  AND p.role = 'A';

-- Durosinmi (Pisa A = 8)
UPDATE players p SET quotation = 8, initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%pisa%')
  AND (LOWER(p.name) LIKE '%durosinmi%')
  AND p.role = 'A';

-- Dybala (Roma A = 19)
UPDATE players p SET quotation = 19, initial_price = 19
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%roma%' AND LOWER(rt.name) NOT LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%dybala%')
  AND p.role = 'A';

-- Ekhator (Genoa A = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%genoa%')
  AND (LOWER(p.name) LIKE '%ekhator%')
  AND p.role = 'A';

-- Ekuban (Genoa A = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%genoa%')
  AND (LOWER(p.name) LIKE '%ekuban%')
  AND p.role = 'A';

-- El Shaarawy (Roma A = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%roma%' AND LOWER(rt.name) NOT LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%shaarawy%')
  AND p.role = 'A';

-- Elphege (Parma A = 3)
UPDATE players p SET quotation = 3, initial_price = 3
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%parma%')
  AND (LOWER(p.name) LIKE '%elphege%')
  AND p.role = 'A';

-- Esposito F (Inter A = 14)
UPDATE players p SET quotation = 14, initial_price = 14
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%esposito%')
  AND p.role = 'A';

-- Esposito S (Cagliari A = 11)
UPDATE players p SET quotation = 11, initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cagliari%')
  AND (LOWER(p.name) LIKE '%esposito%')
  AND p.role = 'A';

-- Ferguson E (Roma A = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%roma%' AND LOWER(rt.name) NOT LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%ferguson%')
  AND p.role = 'A';

-- Fernandes S (Lazio A = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lazio%')
  AND (LOWER(p.name) LIKE '%fernandes%')
  AND p.role = 'A';

-- Frigan (Parma A = 5)
UPDATE players p SET quotation = 5, initial_price = 5
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%parma%')
  AND (LOWER(p.name) LIKE '%frigan%')
  AND p.role = 'A';

-- Fullkrug (Milan A = 15)
UPDATE players p SET quotation = 15, initial_price = 15
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%milan%' AND LOWER(rt.name) NOT LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%fullkrug%')
  AND p.role = 'A';

-- Gabellini (Torino A = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%gabellini%')
  AND p.role = 'A';

-- Gimenez S (Milan A = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%milan%' AND LOWER(rt.name) NOT LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%gimenez%')
  AND p.role = 'A';

-- Giovane S (Napoli A = 11)
UPDATE players p SET quotation = 11, initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%napoli%')
  AND (LOWER(p.name) LIKE '%giovane%')
  AND p.role = 'A';

-- Gudmundsson (Fiorentina A = 17)
UPDATE players p SET quotation = 17, initial_price = 17
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%fiorentina%')
  AND (LOWER(p.name) LIKE '%gudmundsson%')
  AND p.role = 'A';

-- Gueye (Udinese A = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%udinese%')
  AND (LOWER(p.name) LIKE '%gueye%')
  AND p.role = 'A';

-- Hojlund (Napoli A = 19)
UPDATE players p SET quotation = 19, initial_price = 19
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%napoli%')
  AND (LOWER(p.name) LIKE '%hojlund%')
  AND p.role = 'A';

-- Isaac (Verona A = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%isaac%')
  AND p.role = 'A';

-- Kean (Fiorentina A = 26)
UPDATE players p SET quotation = 26, initial_price = 26
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%fiorentina%')
  AND (LOWER(p.name) LIKE '%kean%')
  AND p.role = 'A';

-- Kilicsoy (Cagliari A = 14)
UPDATE players p SET quotation = 14, initial_price = 14
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cagliari%')
  AND (LOWER(p.name) LIKE '%kilicsoy%')
  AND p.role = 'A';

-- Krstovic (Atalanta A = 18)
UPDATE players p SET quotation = 18, initial_price = 18
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%krstovic%')
  AND p.role = 'A';

-- Kulenovic (Torino A = 6)
UPDATE players p SET quotation = 6, initial_price = 6
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%kulenovic%')
  AND p.role = 'A';

-- Lauriente' (Sassuolo A = 19)
UPDATE players p SET quotation = 19, initial_price = 19
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%sassuolo%')
  AND (LOWER(p.name) LIKE '%lauriente''%')
  AND p.role = 'A';

-- Lavelli (Inter A = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%lavelli%')
  AND p.role = 'A';

-- Leao (Milan A = 22)
UPDATE players p SET quotation = 22, initial_price = 22
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%milan%' AND LOWER(rt.name) NOT LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%leao%')
  AND p.role = 'A';

-- Licina (Juventus A = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%juventus%' OR LOWER(rt.name) LIKE '%juve%')
  AND (LOWER(p.name) LIKE '%licina%')
  AND p.role = 'A';

-- Lukaku R (Napoli A = 15)
UPDATE players p SET quotation = 15, initial_price = 15
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%napoli%')
  AND (LOWER(p.name) LIKE '%lukaku%')
  AND p.role = 'A';

-- Luna (Verona A = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%luna%')
  AND p.role = 'A';

-- Malen (Roma A = 20)
UPDATE players p SET quotation = 20, initial_price = 20
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%roma%' AND LOWER(rt.name) NOT LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%malen%')
  AND p.role = 'A';

-- Martinez L (Inter A = 43)
UPDATE players p SET quotation = 43, initial_price = 43
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%martinez%')
  AND p.role = 'A';

-- Meister (Pisa A = 4)
UPDATE players p SET quotation = 4, initial_price = 4
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%pisa%')
  AND (LOWER(p.name) LIKE '%meister%')
  AND p.role = 'A';

-- Milik (Juventus A = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%juventus%' OR LOWER(rt.name) LIKE '%juve%')
  AND (LOWER(p.name) LIKE '%milik%')
  AND p.role = 'A';

-- Misitano (Atalanta A = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%misitano%')
  AND p.role = 'A';

-- Morata (Como A = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%como%')
  AND (LOWER(p.name) LIKE '%morata%')
  AND p.role = 'A';

-- Moreo (Pisa A = 12)
UPDATE players p SET quotation = 12, initial_price = 12
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%pisa%')
  AND (LOWER(p.name) LIKE '%moreo%')
  AND p.role = 'A';

-- Moro L (Sassuolo A = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%sassuolo%')
  AND (LOWER(p.name) LIKE '%moro%')
  AND p.role = 'A';

-- Mosquera (Verona A = 8)
UPDATE players p SET quotation = 8, initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%mosquera%')
  AND p.role = 'A';

-- Moumbagna (Cremonese A = 2)
UPDATE players p SET quotation = 2, initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%moumbagna%')
  AND p.role = 'A';

-- N'Dri (Lecce A = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lecce%')
  AND (LOWER(p.name) LIKE '%n''dri%')
  AND p.role = 'A';

-- Nkunku (Milan A = 16)
UPDATE players p SET quotation = 16, initial_price = 16
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%milan%' AND LOWER(rt.name) NOT LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%nkunku%')
  AND p.role = 'A';

-- Noslin (Lazio A = 7)
UPDATE players p SET quotation = 7, initial_price = 7
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lazio%')
  AND (LOWER(p.name) LIKE '%noslin%')
  AND p.role = 'A';

-- Nuredini (Genoa A = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%genoa%')
  AND (LOWER(p.name) LIKE '%nuredini%')
  AND p.role = 'A';

-- Nzola (Sassuolo A = 6)
UPDATE players p SET quotation = 6, initial_price = 6
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%sassuolo%')
  AND (LOWER(p.name) LIKE '%nzola%')
  AND p.role = 'A';

-- Odgaard (Bologna A = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%bologna%')
  AND (LOWER(p.name) LIKE '%odgaard%')
  AND p.role = 'A';

-- Okereke (Cremonese A = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%okereke%')
  AND p.role = 'A';

-- Openda (Juventus A = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%juventus%' OR LOWER(rt.name) LIKE '%juve%')
  AND (LOWER(p.name) LIKE '%openda%')
  AND p.role = 'A';

-- Orban G (Verona A = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%orban%')
  AND p.role = 'A';

-- Pavoletti (Cagliari A = 6)
UPDATE players p SET quotation = 6, initial_price = 6
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cagliari%')
  AND (LOWER(p.name) LIKE '%pavoletti%')
  AND p.role = 'A';

-- Pedro R (Lazio A = 11)
UPDATE players p SET quotation = 11, initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lazio%')
  AND (LOWER(p.name) LIKE '%pedro%')
  AND p.role = 'A';

-- Pellegrino Ma (Parma A = 13)
UPDATE players p SET quotation = 13, initial_price = 13
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%parma%')
  AND (LOWER(p.name) LIKE '%pellegrino%')
  AND p.role = 'A';

-- Piccoli (Fiorentina A = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%fiorentina%')
  AND (LOWER(p.name) LIKE '%piccoli%')
  AND p.role = 'A';

-- Pierotti (Lecce A = 7)
UPDATE players p SET quotation = 7, initial_price = 7
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lecce%')
  AND (LOWER(p.name) LIKE '%pierotti%')
  AND p.role = 'A';

-- Pinamonti (Sassuolo A = 14)
UPDATE players p SET quotation = 14, initial_price = 14
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%sassuolo%')
  AND (LOWER(p.name) LIKE '%pinamonti%')
  AND p.role = 'A';

-- Pisano M (Como A = 2)
UPDATE players p SET quotation = 2, initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%como%')
  AND (LOWER(p.name) LIKE '%pisano%')
  AND p.role = 'A';

-- Politano (Napoli A = 16)
UPDATE players p SET quotation = 16, initial_price = 16
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%napoli%')
  AND (LOWER(p.name) LIKE '%politano%')
  AND p.role = 'A';

-- Pugno (Juventus A = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%juventus%' OR LOWER(rt.name) LIKE '%juve%')
  AND (LOWER(p.name) LIKE '%pugno%')
  AND p.role = 'A';

-- Raspadori (Atalanta A = 16)
UPDATE players p SET quotation = 16, initial_price = 16
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%raspadori%')
  AND p.role = 'A';

-- Ratkov (Lazio A = 8)
UPDATE players p SET quotation = 8, initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lazio%')
  AND (LOWER(p.name) LIKE '%ratkov%')
  AND p.role = 'A';

-- Sanabria (Cremonese A = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%sanabria%')
  AND p.role = 'A';

-- Savva (Torino A = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%savva%')
  AND p.role = 'A';

-- Scamacca (Atalanta A = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%scamacca%')
  AND p.role = 'A';

-- Scotti (Milan A = 2)
UPDATE players p SET quotation = 2, initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%milan%' AND LOWER(rt.name) NOT LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%scotti%')
  AND p.role = 'A';

-- Simeone (Torino A = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%simeone%')
  AND p.role = 'A';

-- Solomon (Fiorentina A = 13)
UPDATE players p SET quotation = 13, initial_price = 13
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%fiorentina%')
  AND (LOWER(p.name) LIKE '%solomon%')
  AND p.role = 'A';

-- Stojilkovic (Pisa A = 3)
UPDATE players p SET quotation = 3, initial_price = 3
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%pisa%')
  AND (LOWER(p.name) LIKE '%stojilkovic%')
  AND p.role = 'A';

-- Stulic (Lecce A = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lecce%')
  AND (LOWER(p.name) LIKE '%stulic%')
  AND p.role = 'A';

-- Thuram (Inter A = 31)
UPDATE players p SET quotation = 31, initial_price = 31
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%thuram%')
  AND p.role = 'A';

-- Trepy (Cagliari A = 3)
UPDATE players p SET quotation = 3, initial_price = 3
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cagliari%')
  AND (LOWER(p.name) LIKE '%trepy%')
  AND p.role = 'A';

-- Vardy (Cremonese A = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%vardy%')
  AND p.role = 'A';

-- Vavassori (Atalanta A = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%vavassori%')
  AND p.role = 'A';

-- Vaz (Roma A = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%roma%' AND LOWER(rt.name) NOT LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%vaz%')
  AND p.role = 'A';

-- Venturino (Roma A = 3)
UPDATE players p SET quotation = 3, initial_price = 3
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%roma%' AND LOWER(rt.name) NOT LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%venturino%')
  AND p.role = 'A';

-- Vinciati (Udinese A = 1)
UPDATE players p SET quotation = 1, initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%udinese%')
  AND (LOWER(p.name) LIKE '%vinciati%')
  AND p.role = 'A';

-- Vitinha (Genoa A = 10)
UPDATE players p SET quotation = 10, initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%genoa%')
  AND (LOWER(p.name) LIKE '%vitinha%')
  AND p.role = 'A';

-- Vlahovic (Juventus A = 9)
UPDATE players p SET quotation = 9, initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%juventus%' OR LOWER(rt.name) LIKE '%juve%')
  AND (LOWER(p.name) LIKE '%vlahovic%')
  AND p.role = 'A';

-- Yildiz (Juventus A = 29)
UPDATE players p SET quotation = 29, initial_price = 29
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%juventus%' OR LOWER(rt.name) LIKE '%juve%')
  AND (LOWER(p.name) LIKE '%yildiz%')
  AND p.role = 'A';

-- Zapata D (Torino A = 11)
UPDATE players p SET quotation = 11, initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%zapata%')
  AND p.role = 'A';

COMMIT;

-- Verifica risultati
SELECT role, COUNT(*) as totale,
  COUNT(CASE WHEN quotation > 1 THEN 1 END) as con_quotazione,
  AVG(quotation)::int as media
FROM players GROUP BY role ORDER BY role;