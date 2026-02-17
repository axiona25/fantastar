-- AGGIORNAMENTO QUOTAZIONI FANTAMASTER 2025/2026
-- Colonne: position (POR/DIF/CEN/ATT), initial_price
-- NO transaction (ogni UPDATE indipendente)

-- Audero (Cremonese P = 17)
UPDATE players p SET initial_price = 17
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%audero%')
  AND p.position = 'POR';

-- Bijlow (Genoa P = 4)
UPDATE players p SET initial_price = 4
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%genoa%')
  AND (LOWER(p.name) LIKE '%bijlow%')
  AND p.position = 'POR';

-- Borghi (Verona P = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%borghi%')
  AND p.position = 'POR';

-- Butez (Como P = 24)
UPDATE players p SET initial_price = 24
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%como%')
  AND (LOWER(p.name) LIKE '%butez%')
  AND p.position = 'POR';

-- Calligaris (Inter P = 2)
UPDATE players p SET initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%calligaris%')
  AND p.position = 'POR';

-- Caprile (Cagliari P = 20)
UPDATE players p SET initial_price = 20
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cagliari%')
  AND (LOWER(p.name) LIKE '%caprile%')
  AND p.position = 'POR';

-- Carnesecchi (Atalanta P = 25)
UPDATE players p SET initial_price = 25
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%carnesecchi%')
  AND p.position = 'POR';

-- Cavlina (Como P = 3)
UPDATE players p SET initial_price = 3
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%como%')
  AND (LOWER(p.name) LIKE '%cavlina%')
  AND p.position = 'POR';

-- Christensen (Fiorentina P = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%fiorentina%')
  AND (LOWER(p.name) LIKE '%christensen%')
  AND p.position = 'POR';

-- Ciocci (Cagliari P = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cagliari%')
  AND (LOWER(p.name) LIKE '%ciocci%')
  AND p.position = 'POR';

-- Contini (Napoli P = 2)
UPDATE players p SET initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%napoli%')
  AND (LOWER(p.name) LIKE '%contini%')
  AND p.position = 'POR';

-- Corvi (Parma P = 8)
UPDATE players p SET initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%parma%')
  AND (LOWER(p.name) LIKE '%corvi%')
  AND p.position = 'POR';

-- De Gea (Fiorentina P = 24)
UPDATE players p SET initial_price = 24
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%fiorentina%')
  AND (LOWER(p.name) LIKE '%gea%')
  AND p.position = 'POR';

-- Di Gennaro R (Inter P = 2)
UPDATE players p SET initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%gennaro%')
  AND p.position = 'POR';

-- Di Gregorio (Juventus P = 24)
UPDATE players p SET initial_price = 24
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND ((LOWER(rt.name) LIKE '%juventus%' OR LOWER(rt.name) LIKE '%juve%'))
  AND (LOWER(p.name) LIKE '%gregorio%')
  AND p.position = 'POR';

-- Falcone (Lecce P = 25)
UPDATE players p SET initial_price = 25
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lecce%')
  AND (LOWER(p.name) LIKE '%falcone%')
  AND p.position = 'POR';

-- Ferrante (Napoli P = 2)
UPDATE players p SET initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%napoli%')
  AND (LOWER(p.name) LIKE '%ferrante%')
  AND p.position = 'POR';

-- Fruchtl (Lecce P = 2)
UPDATE players p SET initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lecce%')
  AND (LOWER(p.name) LIKE '%fruchtl%')
  AND p.position = 'POR';

-- Furlanetto (Lazio P = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lazio%')
  AND (LOWER(p.name) LIKE '%furlanetto%')
  AND p.position = 'POR';

-- Gollini (Roma P = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%roma%' AND LOWER(rt.name) NOT LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%gollini%')
  AND p.position = 'POR';

-- Israel (Torino P = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%israel%')
  AND p.position = 'POR';

-- Leali (Genoa P = 15)
UPDATE players p SET initial_price = 15
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%genoa%')
  AND (LOWER(p.name) LIKE '%leali%')
  AND p.position = 'POR';

-- Lezzerini (Fiorentina P = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%fiorentina%')
  AND (LOWER(p.name) LIKE '%lezzerini%')
  AND p.position = 'POR';

-- Maignan (Milan P = 25)
UPDATE players p SET initial_price = 25
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%milan%' AND LOWER(rt.name) NOT LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%maignan%')
  AND p.position = 'POR';

-- Martinez J (Inter P = 4)
UPDATE players p SET initial_price = 4
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%martinez%')
  AND p.position = 'POR';

-- Meret (Napoli P = 15)
UPDATE players p SET initial_price = 15
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%napoli%')
  AND (LOWER(p.name) LIKE '%meret%')
  AND p.position = 'POR';

-- Milinkovic-Savic V (Napoli P = 13)
UPDATE players p SET initial_price = 13
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%napoli%')
  AND (LOWER(p.name) LIKE '%milinkovic-savic%')
  AND p.position = 'POR';

-- Montipo' (Verona P = 19)
UPDATE players p SET initial_price = 19
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%montipo''%')
  AND p.position = 'POR';

-- Motta E (Lazio P = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lazio%')
  AND (LOWER(p.name) LIKE '%motta%')
  AND p.position = 'POR';

-- Muric A (Sassuolo P = 11)
UPDATE players p SET initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%sassuolo%')
  AND (LOWER(p.name) LIKE '%muric%')
  AND p.position = 'POR';

-- Nava (Cremonese P = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%nava%')
  AND p.position = 'POR';

-- Nicolas (Pisa P = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%pisa%')
  AND (LOWER(p.name) LIKE '%nicolas%')
  AND p.position = 'POR';

-- Nunziante (Udinese P = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%udinese%')
  AND (LOWER(p.name) LIKE '%nunziante%')
  AND p.position = 'POR';

-- Okoye (Udinese P = 12)
UPDATE players p SET initial_price = 12
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%udinese%')
  AND (LOWER(p.name) LIKE '%okoye%')
  AND p.position = 'POR';

-- Padelli (Udinese P = 2)
UPDATE players p SET initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%udinese%')
  AND (LOWER(p.name) LIKE '%padelli%')
  AND p.position = 'POR';

-- Paleari (Torino P = 11)
UPDATE players p SET initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%paleari%')
  AND p.position = 'POR';

-- Perilli (Verona P = 3)
UPDATE players p SET initial_price = 3
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%perilli%')
  AND p.position = 'POR';

-- Perin (Juventus P = 2)
UPDATE players p SET initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND ((LOWER(rt.name) LIKE '%juventus%' OR LOWER(rt.name) LIKE '%juve%'))
  AND (LOWER(p.name) LIKE '%perin%')
  AND p.position = 'POR';

-- Pessina M (Bologna P = 3)
UPDATE players p SET initial_price = 3
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%bologna%')
  AND (LOWER(p.name) LIKE '%pessina%')
  AND p.position = 'POR';

-- Pinsoglio (Juventus P = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND ((LOWER(rt.name) LIKE '%juventus%' OR LOWER(rt.name) LIKE '%juve%'))
  AND (LOWER(p.name) LIKE '%pinsoglio%')
  AND p.position = 'POR';

-- Provedel (Lazio P = 19)
UPDATE players p SET initial_price = 19
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lazio%')
  AND (LOWER(p.name) LIKE '%provedel%')
  AND p.position = 'POR';

-- Ravaglia F (Bologna P = 7)
UPDATE players p SET initial_price = 7
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%bologna%')
  AND (LOWER(p.name) LIKE '%ravaglia%')
  AND p.position = 'POR';

-- Rinaldi (Parma P = 2)
UPDATE players p SET initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%parma%')
  AND (LOWER(p.name) LIKE '%rinaldi%')
  AND p.position = 'POR';

-- Rossi F (Atalanta P = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%rossi%')
  AND p.position = 'POR';

-- Samooja (Lecce P = 2)
UPDATE players p SET initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lecce%')
  AND (LOWER(p.name) LIKE '%samooja%')
  AND p.position = 'POR';

-- Satalino (Sassuolo P = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%sassuolo%')
  AND (LOWER(p.name) LIKE '%satalino%')
  AND p.position = 'POR';

-- Sava (Udinese P = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%udinese%')
  AND (LOWER(p.name) LIKE '%sava%')
  AND p.position = 'POR';

-- Scuffet (Pisa P = 11)
UPDATE players p SET initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%pisa%')
  AND (LOWER(p.name) LIKE '%scuffet%')
  AND p.position = 'POR';

-- Semper (Pisa P = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%pisa%')
  AND (LOWER(p.name) LIKE '%semper%')
  AND p.position = 'POR';

-- Sherri (Cagliari P = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cagliari%')
  AND (LOWER(p.name) LIKE '%sherri%')
  AND p.position = 'POR';

-- Siegrist (Genoa P = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%genoa%')
  AND (LOWER(p.name) LIKE '%siegrist%')
  AND p.position = 'POR';

-- Silvestri (Cremonese P = 4)
UPDATE players p SET initial_price = 4
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%silvestri%')
  AND p.position = 'POR';

-- Siviero (Torino P = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%siviero%')
  AND p.position = 'POR';

-- Skorupski (Bologna P = 12)
UPDATE players p SET initial_price = 12
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%bologna%')
  AND (LOWER(p.name) LIKE '%skorupski%')
  AND p.position = 'POR';

-- Sommariva (Genoa P = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%genoa%')
  AND (LOWER(p.name) LIKE '%sommariva%')
  AND p.position = 'POR';

-- Sommer (Inter P = 25)
UPDATE players p SET initial_price = 25
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%sommer%')
  AND p.position = 'POR';

-- Sportiello (Atalanta P = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%sportiello%')
  AND p.position = 'POR';

-- Suzuki (Parma P = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%parma%')
  AND (LOWER(p.name) LIKE '%suzuki%')
  AND p.position = 'POR';

-- Svilar (Roma P = 25)
UPDATE players p SET initial_price = 25
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%roma%' AND LOWER(rt.name) NOT LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%svilar%')
  AND p.position = 'POR';

-- Terracciano (Milan P = 5)
UPDATE players p SET initial_price = 5
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%milan%' AND LOWER(rt.name) NOT LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%terracciano%')
  AND p.position = 'POR';

-- Toniolo (Verona P = 2)
UPDATE players p SET initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%toniolo%')
  AND p.position = 'POR';

-- Tornqvist (Como P = 2)
UPDATE players p SET initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%como%')
  AND (LOWER(p.name) LIKE '%tornqvist%')
  AND p.position = 'POR';

-- Torriani (Milan P = 3)
UPDATE players p SET initial_price = 3
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%milan%' AND LOWER(rt.name) NOT LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%torriani%')
  AND p.position = 'POR';

-- Turati (Sassuolo P = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%sassuolo%')
  AND (LOWER(p.name) LIKE '%turati%')
  AND p.position = 'POR';

-- Vigorito (Como P = 3)
UPDATE players p SET initial_price = 3
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%como%')
  AND (LOWER(p.name) LIKE '%vigorito%')
  AND p.position = 'POR';

-- Zacchi (Sassuolo P = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%sassuolo%')
  AND (LOWER(p.name) LIKE '%zacchi%')
  AND p.position = 'POR';

-- Zelezny (Roma P = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%roma%' AND LOWER(rt.name) NOT LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%zelezny%')
  AND p.position = 'POR';

-- Acerbi (Inter D = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%acerbi%')
  AND p.position = 'DIF';

-- Ahanor (Atalanta D = 8)
UPDATE players p SET initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%ahanor%')
  AND p.position = 'DIF';

-- Akanji (Inter D = 16)
UPDATE players p SET initial_price = 16
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%akanji%')
  AND p.position = 'DIF';

-- Albiol (Pisa D = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%pisa%')
  AND (LOWER(p.name) LIKE '%albiol%')
  AND p.position = 'DIF';

-- Alex Valle (Como D = 12)
UPDATE players p SET initial_price = 12
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%como%')
  AND (LOWER(p.name) LIKE '%alex%' AND LOWER(p.name) LIKE '%valle%')
  AND p.position = 'DIF';

-- Alexiou (Inter D = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%alexiou%')
  AND p.position = 'DIF';

-- Angelino (Roma D = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%roma%' AND LOWER(rt.name) NOT LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%angelino%')
  AND p.position = 'DIF';

-- Angori (Pisa D = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%pisa%')
  AND (LOWER(p.name) LIKE '%angori%')
  AND p.position = 'DIF';

-- Arizala (Udinese D = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%udinese%')
  AND (LOWER(p.name) LIKE '%arizala%')
  AND p.position = 'DIF';

-- Athekame (Milan D = 11)
UPDATE players p SET initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%milan%' AND LOWER(rt.name) NOT LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%athekame%')
  AND p.position = 'DIF';

-- Bakker (Atalanta D = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%bakker%')
  AND p.position = 'DIF';

-- Barbieri (Cremonese D = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%barbieri%')
  AND p.position = 'DIF';

-- Bartesaghi (Milan D = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%milan%' AND LOWER(rt.name) NOT LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%bartesaghi%')
  AND p.position = 'DIF';

-- Baschirotto (Cremonese D = 11)
UPDATE players p SET initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%baschirotto%')
  AND p.position = 'DIF';

-- Bastoni (Inter D = 22)
UPDATE players p SET initial_price = 22
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%bastoni%')
  AND p.position = 'DIF';

-- Belghali (Verona D = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%belghali%')
  AND p.position = 'DIF';

-- Bella-Kotchap (Verona D = 2)
UPDATE players p SET initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%bella-kotchap%')
  AND p.position = 'DIF';

-- Bellanova (Atalanta D = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%bellanova%')
  AND p.position = 'DIF';

-- Bertola (Udinese D = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%udinese%')
  AND (LOWER(p.name) LIKE '%bertola%')
  AND p.position = 'DIF';

-- Beukema (Napoli D = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%napoli%')
  AND (LOWER(p.name) LIKE '%beukema%')
  AND p.position = 'DIF';

-- Bianchetti (Cremonese D = 6)
UPDATE players p SET initial_price = 6
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%bianchetti%')
  AND p.position = 'DIF';

-- Biraghi (Torino D = 8)
UPDATE players p SET initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%biraghi%')
  AND p.position = 'DIF';

-- Bisseck (Inter D = 16)
UPDATE players p SET initial_price = 16
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%bisseck%')
  AND p.position = 'DIF';

-- Bonifazi (Bologna D = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%bologna%')
  AND (LOWER(p.name) LIKE '%bonifazi%')
  AND p.position = 'DIF';

-- Bozhinov (Pisa D = 2)
UPDATE players p SET initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%pisa%')
  AND (LOWER(p.name) LIKE '%bozhinov%')
  AND p.position = 'DIF';

-- Bradaric D (Verona D = 6)
UPDATE players p SET initial_price = 6
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%bradaric%')
  AND p.position = 'DIF';

-- Bremer (Juventus D = 17)
UPDATE players p SET initial_price = 17
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND ((LOWER(rt.name) LIKE '%juventus%' OR LOWER(rt.name) LIKE '%juve%'))
  AND (LOWER(p.name) LIKE '%bremer%')
  AND p.position = 'DIF';

-- Britschgi (Parma D = 5)
UPDATE players p SET initial_price = 5
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%parma%')
  AND (LOWER(p.name) LIKE '%britschgi%')
  AND p.position = 'DIF';

-- Buongiorno (Napoli D = 11)
UPDATE players p SET initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%napoli%')
  AND (LOWER(p.name) LIKE '%buongiorno%')
  AND p.position = 'DIF';

-- Cabal (Juventus D = 7)
UPDATE players p SET initial_price = 7
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND ((LOWER(rt.name) LIKE '%juventus%' OR LOWER(rt.name) LIKE '%juve%'))
  AND (LOWER(p.name) LIKE '%cabal%')
  AND p.position = 'DIF';

-- Calabresi (Pisa D = 8)
UPDATE players p SET initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%pisa%')
  AND (LOWER(p.name) LIKE '%calabresi%')
  AND p.position = 'DIF';

-- Cambiaso (Juventus D = 12)
UPDATE players p SET initial_price = 12
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND ((LOWER(rt.name) LIKE '%juventus%' OR LOWER(rt.name) LIKE '%juve%'))
  AND (LOWER(p.name) LIKE '%cambiaso%')
  AND p.position = 'DIF';

-- Cande (Sassuolo D = 5)
UPDATE players p SET initial_price = 5
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%sassuolo%')
  AND (LOWER(p.name) LIKE '%cande%')
  AND p.position = 'DIF';

-- Canestrelli (Pisa D = 6)
UPDATE players p SET initial_price = 6
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%pisa%')
  AND (LOWER(p.name) LIKE '%canestrelli%')
  AND p.position = 'DIF';

-- Caracciolo A (Pisa D = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%pisa%')
  AND (LOWER(p.name) LIKE '%caracciolo%')
  AND p.position = 'DIF';

-- Carboni F (Parma D = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%parma%')
  AND (LOWER(p.name) LIKE '%carboni%')
  AND p.position = 'DIF';

-- Carlos Augusto (Inter D = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%carlos%' AND LOWER(p.name) LIKE '%augusto%')
  AND p.position = 'DIF';

-- Casale (Bologna D = 4)
UPDATE players p SET initial_price = 4
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%bologna%')
  AND (LOWER(p.name) LIKE '%casale%')
  AND p.position = 'DIF';

-- Ceccherini (Cremonese D = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%ceccherini%')
  AND p.position = 'DIF';

-- Celik (Roma D = 13)
UPDATE players p SET initial_price = 13
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%roma%' AND LOWER(rt.name) NOT LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%celik%')
  AND p.position = 'DIF';

-- Cham (Verona D = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%cham%')
  AND p.position = 'DIF';

-- Circati (Parma D = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%parma%')
  AND (LOWER(p.name) LIKE '%circati%')
  AND p.position = 'DIF';

-- Cocchi (Inter D = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%cocchi%')
  AND p.position = 'DIF';

-- Coco S (Torino D = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%coco%')
  AND p.position = 'DIF';

-- Comi (Atalanta D = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%comi%')
  AND p.position = 'DIF';

-- Comuzzo (Fiorentina D = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%fiorentina%')
  AND (LOWER(p.name) LIKE '%comuzzo%')
  AND p.position = 'DIF';

-- Coppola Fr (Pisa D = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%pisa%')
  AND (LOWER(p.name) LIKE '%coppola%')
  AND p.position = 'DIF';

-- Coulibaly W (Sassuolo D = 7)
UPDATE players p SET initial_price = 7
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%sassuolo%')
  AND (LOWER(p.name) LIKE '%coulibaly%')
  AND p.position = 'DIF';

-- Cuadrado (Pisa D = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%pisa%')
  AND (LOWER(p.name) LIKE '%cuadrado%')
  AND p.position = 'DIF';

-- Danilo Veiga (Lecce D = 8)
UPDATE players p SET initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lecce%')
  AND (LOWER(p.name) LIKE '%danilo%' AND LOWER(p.name) LIKE '%veiga%')
  AND p.position = 'DIF';

-- Darmian (Inter D = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%darmian%')
  AND p.position = 'DIF';

-- De Silvestri (Bologna D = 6)
UPDATE players p SET initial_price = 6
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%bologna%')
  AND (LOWER(p.name) LIKE '%silvestri%')
  AND p.position = 'DIF';

-- De Vrij (Inter D = 7)
UPDATE players p SET initial_price = 7
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%vrij%')
  AND p.position = 'DIF';

-- De Winter (Milan D = 12)
UPDATE players p SET initial_price = 12
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%milan%' AND LOWER(rt.name) NOT LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%winter%')
  AND p.position = 'DIF';

-- Delprato (Parma D = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%parma%')
  AND (LOWER(p.name) LIKE '%delprato%')
  AND p.position = 'DIF';

-- Denoon (Pisa D = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%pisa%')
  AND (LOWER(p.name) LIKE '%denoon%')
  AND p.position = 'DIF';

-- Di Lorenzo (Napoli D = 17)
UPDATE players p SET initial_price = 17
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%napoli%')
  AND (LOWER(p.name) LIKE '%lorenzo%')
  AND p.position = 'DIF';

-- Diego Carlos (Como D = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%como%')
  AND (LOWER(p.name) LIKE '%diego%' AND LOWER(p.name) LIKE '%carlos%')
  AND p.position = 'DIF';

-- Dimarco (Inter D = 25)
UPDATE players p SET initial_price = 25
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%dimarco%')
  AND p.position = 'DIF';

-- Djimsiti (Atalanta D = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%djimsiti%')
  AND p.position = 'DIF';

-- Dodo D (Fiorentina D = 12)
UPDATE players p SET initial_price = 12
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%fiorentina%')
  AND (LOWER(p.name) LIKE '%dodo%')
  AND p.position = 'DIF';

-- Doig (Sassuolo D = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%sassuolo%')
  AND (LOWER(p.name) LIKE '%doig%')
  AND p.position = 'DIF';

-- Dossena A (Cagliari D = 5)
UPDATE players p SET initial_price = 5
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cagliari%')
  AND (LOWER(p.name) LIKE '%dossena%')
  AND p.position = 'DIF';

-- Dumfries (Inter D = 14)
UPDATE players p SET initial_price = 14
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%dumfries%')
  AND p.position = 'DIF';

-- Ebosse (Torino D = 2)
UPDATE players p SET initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%ebosse%')
  AND p.position = 'DIF';

-- Edmundsson (Verona D = 3)
UPDATE players p SET initial_price = 3
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%edmundsson%')
  AND p.position = 'DIF';

-- Ehizibue (Udinese D = 5)
UPDATE players p SET initial_price = 5
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%udinese%')
  AND (LOWER(p.name) LIKE '%ehizibue%')
  AND p.position = 'DIF';

-- Estupinan (Milan D = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%milan%' AND LOWER(rt.name) NOT LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%estupinan%')
  AND p.position = 'DIF';

-- Faye (Cremonese D = 3)
UPDATE players p SET initial_price = 3
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%faye%')
  AND p.position = 'DIF';

-- Feola (Verona D = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%feola%')
  AND p.position = 'DIF';

-- Floriani M (Cremonese D = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%floriani%')
  AND p.position = 'DIF';

-- Folino (Cremonese D = 5)
UPDATE players p SET initial_price = 5
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%folino%')
  AND p.position = 'DIF';

-- Fortini (Fiorentina D = 6)
UPDATE players p SET initial_price = 6
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%fiorentina%')
  AND (LOWER(p.name) LIKE '%fortini%')
  AND p.position = 'DIF';

-- Frese (Verona D = 6)
UPDATE players p SET initial_price = 6
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%frese%')
  AND p.position = 'DIF';

-- Gabbia (Milan D = 11)
UPDATE players p SET initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%milan%' AND LOWER(rt.name) NOT LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%gabbia%')
  AND p.position = 'DIF';

-- Gallo (Lecce D = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lecce%')
  AND (LOWER(p.name) LIKE '%gallo%')
  AND p.position = 'DIF';

-- Gaspar K (Lecce D = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lecce%')
  AND (LOWER(p.name) LIKE '%gaspar%')
  AND p.position = 'DIF';

-- Gatti (Juventus D = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND ((LOWER(rt.name) LIKE '%juventus%' OR LOWER(rt.name) LIKE '%juve%'))
  AND (LOWER(p.name) LIKE '%gatti%')
  AND p.position = 'DIF';

-- Ghilardi (Roma D = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%roma%' AND LOWER(rt.name) NOT LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%ghilardi%')
  AND p.position = 'DIF';

-- Gigot (Lazio D = 5)
UPDATE players p SET initial_price = 5
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lazio%')
  AND (LOWER(p.name) LIKE '%gigot%')
  AND p.position = 'DIF';

-- Gila (Lazio D = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lazio%')
  AND (LOWER(p.name) LIKE '%gila%')
  AND p.position = 'DIF';

-- Goldaniga (Como D = 5)
UPDATE players p SET initial_price = 5
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%como%')
  AND (LOWER(p.name) LIKE '%goldaniga%')
  AND p.position = 'DIF';

-- Gosens (Fiorentina D = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%fiorentina%')
  AND (LOWER(p.name) LIKE '%gosens%')
  AND p.position = 'DIF';

-- Gutierrez M (Napoli D = 8)
UPDATE players p SET initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%napoli%')
  AND (LOWER(p.name) LIKE '%gutierrez%')
  AND p.position = 'DIF';

-- Heggem (Bologna D = 8)
UPDATE players p SET initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%bologna%')
  AND (LOWER(p.name) LIKE '%heggem%')
  AND p.position = 'DIF';

-- Helland (Bologna D = 5)
UPDATE players p SET initial_price = 5
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%bologna%')
  AND (LOWER(p.name) LIKE '%helland%')
  AND p.position = 'DIF';

-- Hermoso (Roma D = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%roma%' AND LOWER(rt.name) NOT LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%hermoso%')
  AND p.position = 'DIF';

-- Hien (Atalanta D = 11)
UPDATE players p SET initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%hien%')
  AND p.position = 'DIF';

-- Holm (Juventus D = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND ((LOWER(rt.name) LIKE '%juventus%' OR LOWER(rt.name) LIKE '%juve%'))
  AND (LOWER(p.name) LIKE '%holm%')
  AND p.position = 'DIF';

-- Hysaj (Lazio D = 2)
UPDATE players p SET initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lazio%')
  AND (LOWER(p.name) LIKE '%hysaj%')
  AND p.position = 'DIF';

-- Idrissi (Cagliari D = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cagliari%')
  AND (LOWER(p.name) LIKE '%idrissi%')
  AND p.position = 'DIF';

-- Idzes (Sassuolo D = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%sassuolo%')
  AND (LOWER(p.name) LIKE '%idzes%')
  AND p.position = 'DIF';

-- Ismajli (Torino D = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%ismajli%')
  AND p.position = 'DIF';

-- Jakirovic (Inter D = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%jakirovic%')
  AND p.position = 'DIF';

-- Jean (Lecce D = 3)
UPDATE players p SET initial_price = 3
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lecce%')
  AND (LOWER(p.name) LIKE '%jean%')
  AND p.position = 'DIF';

-- Joao Mario N (Bologna D = 7)
UPDATE players p SET initial_price = 7
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%bologna%')
  AND (LOWER(p.name) LIKE '%joao%' AND LOWER(p.name) LIKE '%mario%')
  AND p.position = 'DIF';

-- Juan Jesus (Napoli D = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%napoli%')
  AND (LOWER(p.name) LIKE '%juan%' AND LOWER(p.name) LIKE '%jesus%')
  AND p.position = 'DIF';

-- Kabasele (Udinese D = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%udinese%')
  AND (LOWER(p.name) LIKE '%kabasele%')
  AND p.position = 'DIF';

-- Kalulu (Juventus D = 20)
UPDATE players p SET initial_price = 20
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND ((LOWER(rt.name) LIKE '%juventus%' OR LOWER(rt.name) LIKE '%juve%'))
  AND (LOWER(p.name) LIKE '%kalulu%')
  AND p.position = 'DIF';

-- Kamara (Udinese D = 8)
UPDATE players p SET initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%udinese%')
  AND (LOWER(p.name) LIKE '%kamara%')
  AND p.position = 'DIF';

-- Kelly (Juventus D = 12)
UPDATE players p SET initial_price = 12
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND ((LOWER(rt.name) LIKE '%juventus%' OR LOWER(rt.name) LIKE '%juve%'))
  AND (LOWER(p.name) LIKE '%kelly%')
  AND p.position = 'DIF';

-- Kempf (Como D = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%como%')
  AND (LOWER(p.name) LIKE '%kempf%')
  AND p.position = 'DIF';

-- Kolasinac (Atalanta D = 11)
UPDATE players p SET initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%kolasinac%')
  AND p.position = 'DIF';

-- Kospo (Fiorentina D = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%fiorentina%')
  AND (LOWER(p.name) LIKE '%kospo%')
  AND p.position = 'DIF';

-- Kossounou (Atalanta D = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%kossounou%')
  AND p.position = 'DIF';

-- Kouadio (Fiorentina D = 2)
UPDATE players p SET initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%fiorentina%')
  AND (LOWER(p.name) LIKE '%kouadio%')
  AND p.position = 'DIF';

-- Kristensen T (Udinese D = 8)
UPDATE players p SET initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%udinese%')
  AND (LOWER(p.name) LIKE '%kristensen%')
  AND p.position = 'DIF';

-- Kumer Celik (Genoa D = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%genoa%')
  AND (LOWER(p.name) LIKE '%kumer%' AND LOWER(p.name) LIKE '%celik%')
  AND p.position = 'DIF';

-- Lamptey (Fiorentina D = 4)
UPDATE players p SET initial_price = 4
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%fiorentina%')
  AND (LOWER(p.name) LIKE '%lamptey%')
  AND p.position = 'DIF';

-- Lazaro (Torino D = 8)
UPDATE players p SET initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%lazaro%')
  AND p.position = 'DIF';

-- Lazzari M (Lazio D = 7)
UPDATE players p SET initial_price = 7
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lazio%')
  AND (LOWER(p.name) LIKE '%lazzari%')
  AND p.position = 'DIF';

-- Lirola (Verona D = 3)
UPDATE players p SET initial_price = 3
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%lirola%')
  AND p.position = 'DIF';

-- Lucumi (Bologna D = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%bologna%')
  AND (LOWER(p.name) LIKE '%lucumi%')
  AND p.position = 'DIF';

-- Luperto (Cremonese D = 12)
UPDATE players p SET initial_price = 12
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%luperto%')
  AND p.position = 'DIF';

-- Lykogiannis (Bologna D = 6)
UPDATE players p SET initial_price = 6
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%bologna%')
  AND (LOWER(p.name) LIKE '%lykogiannis%')
  AND p.position = 'DIF';

-- Macchioni (Sassuolo D = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%sassuolo%')
  AND (LOWER(p.name) LIKE '%macchioni%')
  AND p.position = 'DIF';

-- Mancini (Roma D = 18)
UPDATE players p SET initial_price = 18
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%roma%' AND LOWER(rt.name) NOT LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%mancini%')
  AND p.position = 'DIF';

-- Marcandalli (Genoa D = 8)
UPDATE players p SET initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%genoa%')
  AND (LOWER(p.name) LIKE '%marcandalli%')
  AND p.position = 'DIF';

-- Marianucci (Torino D = 4)
UPDATE players p SET initial_price = 4
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%marianucci%')
  AND p.position = 'DIF';

-- Maripan (Torino D = 11)
UPDATE players p SET initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%maripan%')
  AND p.position = 'DIF';

-- Martin (Genoa D = 16)
UPDATE players p SET initial_price = 16
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%genoa%')
  AND (LOWER(p.name) LIKE '%martin%')
  AND p.position = 'DIF';

-- Marusic (Lazio D = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lazio%')
  AND (LOWER(p.name) LIKE '%marusic%')
  AND p.position = 'DIF';

-- Mathias Olivera (Napoli D = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%napoli%')
  AND (LOWER(p.name) LIKE '%mathias%' AND LOWER(p.name) LIKE '%olivera%')
  AND p.position = 'DIF';

-- Mazzocchi (Napoli D = 3)
UPDATE players p SET initial_price = 3
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%napoli%')
  AND (LOWER(p.name) LIKE '%mazzocchi%')
  AND p.position = 'DIF';

-- Mina (Cagliari D = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cagliari%')
  AND (LOWER(p.name) LIKE '%mina%')
  AND p.position = 'DIF';

-- Miranda J (Bologna D = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%bologna%')
  AND (LOWER(p.name) LIKE '%miranda%')
  AND p.position = 'DIF';

-- Mlacic (Udinese D = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%udinese%')
  AND (LOWER(p.name) LIKE '%mlacic%')
  AND p.position = 'DIF';

-- Moreno A (Como D = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%como%')
  AND (LOWER(p.name) LIKE '%moreno%')
  AND p.position = 'DIF';

-- Muharemovic (Sassuolo D = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%sassuolo%')
  AND (LOWER(p.name) LIKE '%muharemovic%')
  AND p.position = 'DIF';

-- Ndaba (Lecce D = 3)
UPDATE players p SET initial_price = 3
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lecce%')
  AND (LOWER(p.name) LIKE '%ndaba%')
  AND p.position = 'DIF';

-- Ndiaye A (Parma D = 2)
UPDATE players p SET initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%parma%')
  AND (LOWER(p.name) LIKE '%ndiaye%')
  AND p.position = 'DIF';

-- Ndicka (Roma D = 11)
UPDATE players p SET initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%roma%' AND LOWER(rt.name) NOT LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%ndicka%')
  AND p.position = 'DIF';

-- Nelsson (Verona D = 7)
UPDATE players p SET initial_price = 7
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%nelsson%')
  AND p.position = 'DIF';

-- Nkounkou (Torino D = 5)
UPDATE players p SET initial_price = 5
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%nkounkou%')
  AND p.position = 'DIF';

-- Norton-Cuffy (Genoa D = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%genoa%')
  AND (LOWER(p.name) LIKE '%norton-cuffy%')
  AND p.position = 'DIF';

-- Nuno Tavares (Lazio D = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lazio%')
  AND (LOWER(p.name) LIKE '%nuno%' AND LOWER(p.name) LIKE '%tavares%')
  AND p.position = 'DIF';

-- Obert (Cagliari D = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cagliari%')
  AND (LOWER(p.name) LIKE '%obert%')
  AND p.position = 'DIF';

-- Obrador (Torino D = 3)
UPDATE players p SET initial_price = 3
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%obrador%')
  AND p.position = 'DIF';

-- Obric (Atalanta D = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%obric%')
  AND p.position = 'DIF';

-- Odogu (Milan D = 3)
UPDATE players p SET initial_price = 3
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%milan%' AND LOWER(rt.name) NOT LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%odogu%')
  AND p.position = 'DIF';

-- Ostigard (Genoa D = 11)
UPDATE players p SET initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%genoa%')
  AND (LOWER(p.name) LIKE '%ostigard%')
  AND p.position = 'DIF';

-- Otoa (Genoa D = 3)
UPDATE players p SET initial_price = 3
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%genoa%')
  AND (LOWER(p.name) LIKE '%otoa%')
  AND p.position = 'DIF';

-- Oyegoke (Verona D = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%oyegoke%')
  AND p.position = 'DIF';

-- Parisi F (Fiorentina D = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%fiorentina%')
  AND (LOWER(p.name) LIKE '%parisi%')
  AND p.position = 'DIF';

-- Patric (Lazio D = 4)
UPDATE players p SET initial_price = 4
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lazio%')
  AND (LOWER(p.name) LIKE '%patric%')
  AND p.position = 'DIF';

-- Pavlovic S (Milan D = 12)
UPDATE players p SET initial_price = 12
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%milan%' AND LOWER(rt.name) NOT LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%pavlovic%')
  AND p.position = 'DIF';

-- Pedersen (Torino D = 4)
UPDATE players p SET initial_price = 4
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%pedersen%')
  AND p.position = 'DIF';

-- Pedro Felipe (Sassuolo D = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%sassuolo%')
  AND (LOWER(p.name) LIKE '%pedro%' AND LOWER(p.name) LIKE '%felipe%')
  AND p.position = 'DIF';

-- Pellegrini Lu (Lazio D = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lazio%')
  AND (LOWER(p.name) LIKE '%pellegrini%')
  AND p.position = 'DIF';

-- Pellini (Torino D = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%pellini%')
  AND p.position = 'DIF';

-- Perez A (Torino D = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%perez%')
  AND p.position = 'DIF';

-- Perez M (Lecce D = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lecce%')
  AND (LOWER(p.name) LIKE '%perez%')
  AND p.position = 'DIF';

-- Pezzella (Cremonese D = 7)
UPDATE players p SET initial_price = 7
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%pezzella%')
  AND p.position = 'DIF';

-- Pieragnolo (Sassuolo D = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%sassuolo%')
  AND (LOWER(p.name) LIKE '%pieragnolo%')
  AND p.position = 'DIF';

-- Pongracic (Fiorentina D = 8)
UPDATE players p SET initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%fiorentina%')
  AND (LOWER(p.name) LIKE '%pongracic%')
  AND p.position = 'DIF';

-- Provstgaard (Lazio D = 8)
UPDATE players p SET initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lazio%')
  AND (LOWER(p.name) LIKE '%provstgaard%')
  AND p.position = 'DIF';

-- Ramon J (Como D = 14)
UPDATE players p SET initial_price = 14
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%como%')
  AND (LOWER(p.name) LIKE '%ramon%')
  AND p.position = 'DIF';

-- Ranieri (Fiorentina D = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%fiorentina%')
  AND (LOWER(p.name) LIKE '%ranieri%')
  AND p.position = 'DIF';

-- Raterink (Cagliari D = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cagliari%')
  AND (LOWER(p.name) LIKE '%raterink%')
  AND p.position = 'DIF';

-- Rensch (Roma D = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%roma%' AND LOWER(rt.name) NOT LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%rensch%')
  AND p.position = 'DIF';

-- Rocchetti (Cremonese D = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%rocchetti%')
  AND p.position = 'DIF';

-- Rodriguez Ju (Cagliari D = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cagliari%')
  AND (LOWER(p.name) LIKE '%rodriguez%')
  AND p.position = 'DIF';

-- Romagna (Sassuolo D = 2)
UPDATE players p SET initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%sassuolo%')
  AND (LOWER(p.name) LIKE '%romagna%')
  AND p.position = 'DIF';

-- Romagnoli A (Lazio D = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lazio%')
  AND (LOWER(p.name) LIKE '%romagnoli%')
  AND p.position = 'DIF';

-- Rrahmani (Napoli D = 11)
UPDATE players p SET initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%napoli%')
  AND (LOWER(p.name) LIKE '%rrahmani%')
  AND p.position = 'DIF';

-- Rugani (Fiorentina D = 4)
UPDATE players p SET initial_price = 4
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%fiorentina%')
  AND (LOWER(p.name) LIKE '%rugani%')
  AND p.position = 'DIF';

-- Sabelli (Genoa D = 4)
UPDATE players p SET initial_price = 4
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%genoa%')
  AND (LOWER(p.name) LIKE '%sabelli%')
  AND p.position = 'DIF';

-- Sangare' (Roma D = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%roma%' AND LOWER(rt.name) NOT LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%sangare''%')
  AND p.position = 'DIF';

-- Sazonov (Torino D = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%sazonov%')
  AND p.position = 'DIF';

-- Scalvini (Atalanta D = 11)
UPDATE players p SET initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%scalvini%')
  AND p.position = 'DIF';

-- Scott (Lecce D = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lecce%')
  AND (LOWER(p.name) LIKE '%scott%')
  AND p.position = 'DIF';

-- Siebert (Lecce D = 4)
UPDATE players p SET initial_price = 4
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lecce%')
  AND (LOWER(p.name) LIKE '%siebert%')
  AND p.position = 'DIF';

-- Slotsager (Verona D = 2)
UPDATE players p SET initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%slotsager%')
  AND p.position = 'DIF';

-- Smolcic (Como D = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%como%')
  AND (LOWER(p.name) LIKE '%smolcic%')
  AND p.position = 'DIF';

-- Solet (Udinese D = 15)
UPDATE players p SET initial_price = 15
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%udinese%')
  AND (LOWER(p.name) LIKE '%solet%')
  AND p.position = 'DIF';

-- Spinazzola (Napoli D = 14)
UPDATE players p SET initial_price = 14
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%napoli%')
  AND (LOWER(p.name) LIKE '%spinazzola%')
  AND p.position = 'DIF';

-- Terracciano F (Cremonese D = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%terracciano%')
  AND p.position = 'DIF';

-- Tiago Gabriel (Lecce D = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lecce%')
  AND (LOWER(p.name) LIKE '%tiago%' AND LOWER(p.name) LIKE '%gabriel%')
  AND p.position = 'DIF';

-- Tomori (Milan D = 11)
UPDATE players p SET initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%milan%' AND LOWER(rt.name) NOT LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%tomori%')
  AND p.position = 'DIF';

-- Troilo (Parma D = 3)
UPDATE players p SET initial_price = 3
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%parma%')
  AND (LOWER(p.name) LIKE '%troilo%')
  AND p.position = 'DIF';

-- Tsimikas (Roma D = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%roma%' AND LOWER(rt.name) NOT LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%tsimikas%')
  AND p.position = 'DIF';

-- Ulisses Garcia (Sassuolo D = 6)
UPDATE players p SET initial_price = 6
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%sassuolo%')
  AND (LOWER(p.name) LIKE '%ulisses%' AND LOWER(p.name) LIKE '%garcia%')
  AND p.position = 'DIF';

-- Valenti (Parma D = 8)
UPDATE players p SET initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%parma%')
  AND (LOWER(p.name) LIKE '%valenti%')
  AND p.position = 'DIF';

-- Valentini N (Verona D = 4)
UPDATE players p SET initial_price = 4
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%valentini%')
  AND p.position = 'DIF';

-- Valeri (Parma D = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%parma%')
  AND (LOWER(p.name) LIKE '%valeri%')
  AND p.position = 'DIF';

-- Van der Brempt (Como D = 8)
UPDATE players p SET initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%como%')
  AND (LOWER(p.name) LIKE '%van%' AND LOWER(p.name) LIKE '%der%' AND LOWER(p.name) LIKE '%brempt%')
  AND p.position = 'DIF';

-- Vasquez (Genoa D = 12)
UPDATE players p SET initial_price = 12
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%genoa%')
  AND (LOWER(p.name) LIKE '%vasquez%')
  AND p.position = 'DIF';

-- Vitik (Bologna D = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%bologna%')
  AND (LOWER(p.name) LIKE '%vitik%')
  AND p.position = 'DIF';

-- Vojvoda (Como D = 11)
UPDATE players p SET initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%como%')
  AND (LOWER(p.name) LIKE '%vojvoda%')
  AND p.position = 'DIF';

-- Walukiewicz (Sassuolo D = 8)
UPDATE players p SET initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%sassuolo%')
  AND (LOWER(p.name) LIKE '%walukiewicz%')
  AND p.position = 'DIF';

-- Wesley F (Roma D = 15)
UPDATE players p SET initial_price = 15
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%roma%' AND LOWER(rt.name) NOT LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%wesley%')
  AND p.position = 'DIF';

-- Zaia (Torino D = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%zaia%')
  AND p.position = 'DIF';

-- Zalewski (Atalanta D = 15)
UPDATE players p SET initial_price = 15
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%zalewski%')
  AND p.position = 'DIF';

-- Zanoli (Udinese D = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%udinese%')
  AND (LOWER(p.name) LIKE '%zanoli%')
  AND p.position = 'DIF';

-- Zappa (Cagliari D = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cagliari%')
  AND (LOWER(p.name) LIKE '%zappa%')
  AND p.position = 'DIF';

-- Zappacosta (Atalanta D = 13)
UPDATE players p SET initial_price = 13
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%zappacosta%')
  AND p.position = 'DIF';

-- Zatterstrom (Genoa D = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%genoa%')
  AND (LOWER(p.name) LIKE '%zatterstrom%')
  AND p.position = 'DIF';

-- Ze Pedro (Cagliari D = 5)
UPDATE players p SET initial_price = 5
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cagliari%')
  AND (LOWER(p.name) LIKE '%pedro%')
  AND p.position = 'DIF';

-- Zemura (Udinese D = 7)
UPDATE players p SET initial_price = 7
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%udinese%')
  AND (LOWER(p.name) LIKE '%zemura%')
  AND p.position = 'DIF';

-- Ziolkowski (Roma D = 6)
UPDATE players p SET initial_price = 6
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%roma%' AND LOWER(rt.name) NOT LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%ziolkowski%')
  AND p.position = 'DIF';

-- Zortea (Bologna D = 11)
UPDATE players p SET initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%bologna%')
  AND (LOWER(p.name) LIKE '%zortea%')
  AND p.position = 'DIF';

-- Addai (Como C = 6)
UPDATE players p SET initial_price = 6
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%como%')
  AND (LOWER(p.name) LIKE '%addai%')
  AND p.position = 'CEN';

-- Adopo (Cagliari C = 8)
UPDATE players p SET initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cagliari%')
  AND (LOWER(p.name) LIKE '%adopo%')
  AND p.position = 'CEN';

-- Adzic (Juventus C = 4)
UPDATE players p SET initial_price = 4
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND ((LOWER(rt.name) LIKE '%juventus%' OR LOWER(rt.name) LIKE '%juve%'))
  AND (LOWER(p.name) LIKE '%adzic%')
  AND p.position = 'CEN';

-- Aebischer (Pisa C = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%pisa%')
  AND (LOWER(p.name) LIKE '%aebischer%')
  AND p.position = 'CEN';

-- Agbonifo (Inter C = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%agbonifo%')
  AND p.position = 'CEN';

-- Akinsanmiro (Pisa C = 8)
UPDATE players p SET initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%pisa%')
  AND (LOWER(p.name) LIKE '%akinsanmiro%')
  AND p.position = 'CEN';

-- Akpa-Akpro (Verona C = 2)
UPDATE players p SET initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%akpa-akpro%')
  AND p.position = 'CEN';

-- Al-Musrati (Verona C = 7)
UPDATE players p SET initial_price = 7
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%al-musrati%')
  AND p.position = 'CEN';

-- Alex Sala (Lecce C = 5)
UPDATE players p SET initial_price = 5
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lecce%')
  AND (LOWER(p.name) LIKE '%alex%' AND LOWER(p.name) LIKE '%sala%')
  AND p.position = 'CEN';

-- Alisson Santos (Napoli C = 8)
UPDATE players p SET initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%napoli%')
  AND (LOWER(p.name) LIKE '%alisson%' AND LOWER(p.name) LIKE '%santos%')
  AND p.position = 'CEN';

-- Amorim (Genoa C = 2)
UPDATE players p SET initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%genoa%')
  AND (LOWER(p.name) LIKE '%amorim%')
  AND p.position = 'CEN';

-- Anguissa (Napoli C = 15)
UPDATE players p SET initial_price = 15
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%napoli%')
  AND (LOWER(p.name) LIKE '%anguissa%')
  AND p.position = 'CEN';

-- Anjorin (Torino C = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%anjorin%')
  AND p.position = 'CEN';

-- Assane Diao (Como C = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%como%')
  AND (LOWER(p.name) LIKE '%assane%' AND LOWER(p.name) LIKE '%diao%')
  AND p.position = 'CEN';

-- Atta (Udinese C = 13)
UPDATE players p SET initial_price = 13
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%udinese%')
  AND (LOWER(p.name) LIKE '%atta%')
  AND p.position = 'CEN';

-- Bakola (Sassuolo C = 3)
UPDATE players p SET initial_price = 3
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%sassuolo%')
  AND (LOWER(p.name) LIKE '%bakola%')
  AND p.position = 'CEN';

-- Baldanzi (Genoa C = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%genoa%')
  AND (LOWER(p.name) LIKE '%baldanzi%')
  AND p.position = 'CEN';

-- Barella (Inter C = 28)
UPDATE players p SET initial_price = 28
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%barella%')
  AND p.position = 'CEN';

-- Basic (Lazio C = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lazio%')
  AND (LOWER(p.name) LIKE '%basic%')
  AND p.position = 'CEN';

-- Baturina (Como C = 16)
UPDATE players p SET initial_price = 16
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%como%')
  AND (LOWER(p.name) LIKE '%baturina%')
  AND p.position = 'CEN';

-- Belahyane (Lazio C = 4)
UPDATE players p SET initial_price = 4
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lazio%')
  AND (LOWER(p.name) LIKE '%belahyane%')
  AND p.position = 'CEN';

-- Berenbruch (Inter C = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%berenbruch%')
  AND p.position = 'CEN';

-- Berisha M (Lecce C = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lecce%')
  AND (LOWER(p.name) LIKE '%berisha%')
  AND p.position = 'CEN';

-- Bernabe' (Parma C = 18)
UPDATE players p SET initial_price = 18
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%parma%')
  AND (LOWER(p.name) LIKE '%bernabe''%')
  AND p.position = 'CEN';

-- Bernardeschi (Bologna C = 11)
UPDATE players p SET initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%bologna%')
  AND (LOWER(p.name) LIKE '%bernardeschi%')
  AND p.position = 'CEN';

-- Bernasconi (Atalanta C = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%bernasconi%')
  AND p.position = 'CEN';

-- Bernede (Verona C = 5)
UPDATE players p SET initial_price = 5
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%bernede%')
  AND p.position = 'CEN';

-- Boloca (Sassuolo C = 6)
UPDATE players p SET initial_price = 6
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%sassuolo%')
  AND (LOWER(p.name) LIKE '%boloca%')
  AND p.position = 'CEN';

-- Bondo (Cremonese C = 8)
UPDATE players p SET initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%bondo%')
  AND p.position = 'CEN';

-- Brescianini (Fiorentina C = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%fiorentina%')
  AND (LOWER(p.name) LIKE '%brescianini%')
  AND p.position = 'CEN';

-- Calhanoglu (Inter C = 27)
UPDATE players p SET initial_price = 27
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%calhanoglu%')
  AND p.position = 'CEN';

-- Caqueret (Como C = 12)
UPDATE players p SET initial_price = 12
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%como%')
  AND (LOWER(p.name) LIKE '%caqueret%')
  AND p.position = 'CEN';

-- Casadei (Torino C = 12)
UPDATE players p SET initial_price = 12
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%casadei%')
  AND p.position = 'CEN';

-- Cassa (Atalanta C = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%cassa%')
  AND p.position = 'CEN';

-- Cataldi (Lazio C = 11)
UPDATE players p SET initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lazio%')
  AND (LOWER(p.name) LIKE '%cataldi%')
  AND p.position = 'CEN';

-- Caviglia (Parma C = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%parma%')
  AND (LOWER(p.name) LIKE '%caviglia%')
  AND p.position = 'CEN';

-- Collocolo (Cremonese C = 7)
UPDATE players p SET initial_price = 7
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%collocolo%')
  AND p.position = 'CEN';

-- Conceicao (Juventus C = 17)
UPDATE players p SET initial_price = 17
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND ((LOWER(rt.name) LIKE '%juventus%' OR LOWER(rt.name) LIKE '%juve%'))
  AND (LOWER(p.name) LIKE '%conceicao%')
  AND p.position = 'CEN';

-- Cornet (Genoa C = 4)
UPDATE players p SET initial_price = 4
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%genoa%')
  AND (LOWER(p.name) LIKE '%cornet%')
  AND p.position = 'CEN';

-- Coulibaly L (Lecce C = 12)
UPDATE players p SET initial_price = 12
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lecce%')
  AND (LOWER(p.name) LIKE '%coulibaly%')
  AND p.position = 'CEN';

-- Crapisto (Juventus C = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND ((LOWER(rt.name) LIKE '%juventus%' OR LOWER(rt.name) LIKE '%juve%'))
  AND (LOWER(p.name) LIKE '%crapisto%')
  AND p.position = 'CEN';

-- Cremaschi (Parma C = 4)
UPDATE players p SET initial_price = 4
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%parma%')
  AND (LOWER(p.name) LIKE '%cremaschi%')
  AND p.position = 'CEN';

-- Cristante (Roma C = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%roma%' AND LOWER(rt.name) NOT LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%cristante%')
  AND p.position = 'CEN';

-- Da Cunha (Como C = 13)
UPDATE players p SET initial_price = 13
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%como%')
  AND (LOWER(p.name) LIKE '%cunha%')
  AND p.position = 'CEN';

-- De Bruyne (Napoli C = 13)
UPDATE players p SET initial_price = 13
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%napoli%')
  AND (LOWER(p.name) LIKE '%bruyne%')
  AND p.position = 'CEN';

-- De Ketelaere (Atalanta C = 20)
UPDATE players p SET initial_price = 20
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%ketelaere%')
  AND p.position = 'CEN';

-- De Roon (Atalanta C = 11)
UPDATE players p SET initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%roon%')
  AND p.position = 'CEN';

-- Deiola (Cagliari C = 7)
UPDATE players p SET initial_price = 7
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cagliari%')
  AND (LOWER(p.name) LIKE '%deiola%')
  AND p.position = 'CEN';

-- Dele Bashiru (Lazio C = 4)
UPDATE players p SET initial_price = 4
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lazio%')
  AND (LOWER(p.name) LIKE '%dele%' AND LOWER(p.name) LIKE '%bashiru%')
  AND p.position = 'CEN';

-- Diouf A (Inter C = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%diouf%')
  AND p.position = 'CEN';

-- Dominguez B (Bologna C = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%bologna%')
  AND (LOWER(p.name) LIKE '%dominguez%')
  AND p.position = 'CEN';

-- Ederson J (Atalanta C = 13)
UPDATE players p SET initial_price = 13
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%ederson%')
  AND p.position = 'CEN';

-- Ekkelenkamp (Udinese C = 12)
UPDATE players p SET initial_price = 12
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%udinese%')
  AND (LOWER(p.name) LIKE '%ekkelenkamp%')
  AND p.position = 'CEN';

-- El Aynaoui (Roma C = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%roma%' AND LOWER(rt.name) NOT LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%aynaoui%')
  AND p.position = 'CEN';

-- Ellertsson (Genoa C = 7)
UPDATE players p SET initial_price = 7
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%genoa%')
  AND (LOWER(p.name) LIKE '%ellertsson%')
  AND p.position = 'CEN';

-- Elmas (Napoli C = 11)
UPDATE players p SET initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%napoli%')
  AND (LOWER(p.name) LIKE '%elmas%')
  AND p.position = 'CEN';

-- Estevez (Parma C = 5)
UPDATE players p SET initial_price = 5
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%parma%')
  AND (LOWER(p.name) LIKE '%estevez%')
  AND p.position = 'CEN';

-- Fabbian (Fiorentina C = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%fiorentina%')
  AND (LOWER(p.name) LIKE '%fabbian%')
  AND p.position = 'CEN';

-- Fadera (Sassuolo C = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%sassuolo%')
  AND (LOWER(p.name) LIKE '%fadera%')
  AND p.position = 'CEN';

-- Fagioli (Fiorentina C = 15)
UPDATE players p SET initial_price = 15
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%fiorentina%')
  AND (LOWER(p.name) LIKE '%fagioli%')
  AND p.position = 'CEN';

-- Fazzini (Fiorentina C = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%fiorentina%')
  AND (LOWER(p.name) LIKE '%fazzini%')
  AND p.position = 'CEN';

-- Felici (Cagliari C = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cagliari%')
  AND (LOWER(p.name) LIKE '%felici%')
  AND p.position = 'CEN';

-- Ferguson (Bologna C = 11)
UPDATE players p SET initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%bologna%')
  AND (LOWER(p.name) LIKE '%ferguson%')
  AND p.position = 'CEN';

-- Fofana S (Lecce C = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lecce%')
  AND (LOWER(p.name) LIKE '%fofana%')
  AND p.position = 'CEN';

-- Fofana Y (Milan C = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%milan%' AND LOWER(rt.name) NOT LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%fofana%')
  AND p.position = 'CEN';

-- Folorunsho (Cagliari C = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cagliari%')
  AND (LOWER(p.name) LIKE '%folorunsho%')
  AND p.position = 'CEN';

-- Frattesi (Inter C = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%frattesi%')
  AND p.position = 'CEN';

-- Frendrup (Genoa C = 13)
UPDATE players p SET initial_price = 13
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%genoa%')
  AND (LOWER(p.name) LIKE '%frendrup%')
  AND p.position = 'CEN';

-- Freuler (Bologna C = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%bologna%')
  AND (LOWER(p.name) LIKE '%freuler%')
  AND p.position = 'CEN';

-- Gaetano (Cagliari C = 13)
UPDATE players p SET initial_price = 13
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cagliari%')
  AND (LOWER(p.name) LIKE '%gaetano%')
  AND p.position = 'CEN';

-- Gagliardini (Verona C = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%gagliardini%')
  AND p.position = 'CEN';

-- Gandelman (Lecce C = 7)
UPDATE players p SET initial_price = 7
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lecce%')
  AND (LOWER(p.name) LIKE '%gandelman%')
  AND p.position = 'CEN';

-- Gilmour (Napoli C = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%napoli%')
  AND (LOWER(p.name) LIKE '%gilmour%')
  AND p.position = 'CEN';

-- Gineitis (Torino C = 6)
UPDATE players p SET initial_price = 6
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%gineitis%')
  AND p.position = 'CEN';

-- Gorter (Lecce C = 2)
UPDATE players p SET initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lecce%')
  AND (LOWER(p.name) LIKE '%gorter%')
  AND p.position = 'CEN';

-- Grassi (Cremonese C = 3)
UPDATE players p SET initial_price = 3
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%grassi%')
  AND p.position = 'CEN';

-- Harrison (Fiorentina C = 5)
UPDATE players p SET initial_price = 5
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%fiorentina%')
  AND (LOWER(p.name) LIKE '%harrison%')
  AND p.position = 'CEN';

-- Harroui (Verona C = 6)
UPDATE players p SET initial_price = 6
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%harroui%')
  AND p.position = 'CEN';

-- Helgason (Lecce C = 5)
UPDATE players p SET initial_price = 5
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lecce%')
  AND (LOWER(p.name) LIKE '%helgason%')
  AND p.position = 'CEN';

-- Hojholt (Pisa C = 2)
UPDATE players p SET initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%pisa%')
  AND (LOWER(p.name) LIKE '%hojholt%')
  AND p.position = 'CEN';

-- Iannoni (Sassuolo C = 5)
UPDATE players p SET initial_price = 5
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%sassuolo%')
  AND (LOWER(p.name) LIKE '%iannoni%')
  AND p.position = 'CEN';

-- Ilic (Torino C = 8)
UPDATE players p SET initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%ilic%')
  AND p.position = 'CEN';

-- Iling-Junior (Pisa C = 5)
UPDATE players p SET initial_price = 5
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%pisa%')
  AND (LOWER(p.name) LIKE '%iling-junior%')
  AND p.position = 'CEN';

-- Ilkhan (Torino C = 5)
UPDATE players p SET initial_price = 5
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%ilkhan%')
  AND p.position = 'CEN';

-- Isaksen (Lazio C = 14)
UPDATE players p SET initial_price = 14
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lazio%')
  AND (LOWER(p.name) LIKE '%isaksen%')
  AND p.position = 'CEN';

-- Jashari (Milan C = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%milan%' AND LOWER(rt.name) NOT LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%jashari%')
  AND p.position = 'CEN';

-- Kamate (Inter C = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%kamate%')
  AND p.position = 'CEN';

-- Karlstrom (Udinese C = 8)
UPDATE players p SET initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%udinese%')
  AND (LOWER(p.name) LIKE '%karlstrom%')
  AND p.position = 'CEN';

-- Kone I (Sassuolo C = 16)
UPDATE players p SET initial_price = 16
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%sassuolo%')
  AND (LOWER(p.name) LIKE '%kone%')
  AND p.position = 'CEN';

-- Koopmeiners (Juventus C = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND ((LOWER(rt.name) LIKE '%juventus%' OR LOWER(rt.name) LIKE '%juve%'))
  AND (LOWER(p.name) LIKE '%koopmeiners%')
  AND p.position = 'CEN';

-- Kostic (Juventus C = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND ((LOWER(rt.name) LIKE '%juventus%' OR LOWER(rt.name) LIKE '%juve%'))
  AND (LOWER(p.name) LIKE '%kostic%')
  AND p.position = 'CEN';

-- Kuhn (Como C = 11)
UPDATE players p SET initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%como%')
  AND (LOWER(p.name) LIKE '%kuhn%')
  AND p.position = 'CEN';

-- Lafont G (Genoa C = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%genoa%')
  AND (LOWER(p.name) LIKE '%lafont%')
  AND p.position = 'CEN';

-- Lahdo (Como C = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%como%')
  AND (LOWER(p.name) LIKE '%lahdo%')
  AND p.position = 'CEN';

-- Leris (Pisa C = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%pisa%')
  AND (LOWER(p.name) LIKE '%leris%')
  AND p.position = 'CEN';

-- Lipani (Sassuolo C = 5)
UPDATE players p SET initial_price = 5
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%sassuolo%')
  AND (LOWER(p.name) LIKE '%lipani%')
  AND p.position = 'CEN';

-- Liteta (Cagliari C = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cagliari%')
  AND (LOWER(p.name) LIKE '%liteta%')
  AND p.position = 'CEN';

-- Lobotka (Napoli C = 12)
UPDATE players p SET initial_price = 12
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%napoli%')
  AND (LOWER(p.name) LIKE '%lobotka%')
  AND p.position = 'CEN';

-- Locatelli M (Juventus C = 17)
UPDATE players p SET initial_price = 17
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND ((LOWER(rt.name) LIKE '%juventus%' OR LOWER(rt.name) LIKE '%juve%'))
  AND (LOWER(p.name) LIKE '%locatelli%')
  AND p.position = 'CEN';

-- Loftus-Cheek (Milan C = 15)
UPDATE players p SET initial_price = 15
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%milan%' AND LOWER(rt.name) NOT LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%loftus-cheek%')
  AND p.position = 'CEN';

-- Lorran (Pisa C = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%pisa%')
  AND (LOWER(p.name) LIKE '%lorran%')
  AND p.position = 'CEN';

-- Lovric (Verona C = 8)
UPDATE players p SET initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%lovric%')
  AND p.position = 'CEN';

-- Loyola (Pisa C = 6)
UPDATE players p SET initial_price = 6
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%pisa%')
  AND (LOWER(p.name) LIKE '%loyola%')
  AND p.position = 'CEN';

-- Luis Henrique (Inter C = 11)
UPDATE players p SET initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%luis%' AND LOWER(p.name) LIKE '%henrique%')
  AND p.position = 'CEN';

-- Maldini D (Lazio C = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lazio%')
  AND (LOWER(p.name) LIKE '%maldini%')
  AND p.position = 'CEN';

-- Maleh (Cremonese C = 7)
UPDATE players p SET initial_price = 7
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%maleh%')
  AND p.position = 'CEN';

-- Malinovskyi (Genoa C = 15)
UPDATE players p SET initial_price = 15
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%genoa%')
  AND (LOWER(p.name) LIKE '%malinovskyi%')
  AND p.position = 'CEN';

-- Mandela Keita (Parma C = 12)
UPDATE players p SET initial_price = 12
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%parma%')
  AND (LOWER(p.name) LIKE '%mandela%' AND LOWER(p.name) LIKE '%keita%')
  AND p.position = 'CEN';

-- Mandragora (Fiorentina C = 19)
UPDATE players p SET initial_price = 19
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%fiorentina%')
  AND (LOWER(p.name) LIKE '%mandragora%')
  AND p.position = 'CEN';

-- Manu Kone (Roma C = 19)
UPDATE players p SET initial_price = 19
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%roma%' AND LOWER(rt.name) NOT LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%manu%' AND LOWER(p.name) LIKE '%kone%')
  AND p.position = 'CEN';

-- Manzoni A (Atalanta C = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%manzoni%')
  AND p.position = 'CEN';

-- Marchwinski (Lecce C = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lecce%')
  AND (LOWER(p.name) LIKE '%marchwinski%')
  AND p.position = 'CEN';

-- Marin M (Pisa C = 5)
UPDATE players p SET initial_price = 5
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%pisa%')
  AND (LOWER(p.name) LIKE '%marin%')
  AND p.position = 'CEN';

-- Masini (Genoa C = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%genoa%')
  AND (LOWER(p.name) LIKE '%masini%')
  AND p.position = 'CEN';

-- Matic (Sassuolo C = 12)
UPDATE players p SET initial_price = 12
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%sassuolo%')
  AND (LOWER(p.name) LIKE '%matic%')
  AND p.position = 'CEN';

-- Mazzitelli (Cagliari C = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cagliari%')
  AND (LOWER(p.name) LIKE '%mazzitelli%')
  AND p.position = 'CEN';

-- McKennie (Juventus C = 22)
UPDATE players p SET initial_price = 22
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND ((LOWER(rt.name) LIKE '%juventus%' OR LOWER(rt.name) LIKE '%juve%'))
  AND (LOWER(p.name) LIKE '%mckennie%')
  AND p.position = 'CEN';

-- McTominay (Napoli C = 34)
UPDATE players p SET initial_price = 34
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%napoli%')
  AND (LOWER(p.name) LIKE '%mctominay%')
  AND p.position = 'CEN';

-- Messias (Genoa C = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%genoa%')
  AND (LOWER(p.name) LIKE '%messias%')
  AND p.position = 'CEN';

-- Miller (Udinese C = 3)
UPDATE players p SET initial_price = 3
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%udinese%')
  AND (LOWER(p.name) LIKE '%miller%')
  AND p.position = 'CEN';

-- Miretti (Juventus C = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND ((LOWER(rt.name) LIKE '%juventus%' OR LOWER(rt.name) LIKE '%juve%'))
  AND (LOWER(p.name) LIKE '%miretti%')
  AND p.position = 'CEN';

-- Mkhitaryan (Inter C = 11)
UPDATE players p SET initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%mkhitaryan%')
  AND p.position = 'CEN';

-- Modric (Milan C = 25)
UPDATE players p SET initial_price = 25
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%milan%' AND LOWER(rt.name) NOT LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%modric%')
  AND p.position = 'CEN';

-- Moro N (Bologna C = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%bologna%')
  AND (LOWER(p.name) LIKE '%moro%')
  AND p.position = 'CEN';

-- Munoz (Lazio C = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lazio%')
  AND (LOWER(p.name) LIKE '%munoz%')
  AND p.position = 'CEN';

-- Musah (Atalanta C = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%musah%')
  AND p.position = 'CEN';

-- Ndour (Fiorentina C = 7)
UPDATE players p SET initial_price = 7
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%fiorentina%')
  AND (LOWER(p.name) LIKE '%ndour%')
  AND p.position = 'CEN';

-- Neres (Napoli C = 15)
UPDATE players p SET initial_price = 15
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%napoli%')
  AND (LOWER(p.name) LIKE '%neres%')
  AND p.position = 'CEN';

-- Ngom (Lecce C = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lecce%')
  AND (LOWER(p.name) LIKE '%ngom%')
  AND p.position = 'CEN';

-- Niasse (Verona C = 7)
UPDATE players p SET initial_price = 7
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%niasse%')
  AND p.position = 'CEN';

-- Nico Paz (Como C = 32)
UPDATE players p SET initial_price = 32
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%como%')
  AND (LOWER(p.name) LIKE '%nico%' AND LOWER(p.name) LIKE '%paz%')
  AND p.position = 'CEN';

-- Njie (Torino C = 5)
UPDATE players p SET initial_price = 5
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%njie%')
  AND p.position = 'CEN';

-- Onana J (Genoa C = 2)
UPDATE players p SET initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%genoa%')
  AND (LOWER(p.name) LIKE '%onana%')
  AND p.position = 'CEN';

-- Ondrejka (Parma C = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%parma%')
  AND (LOWER(p.name) LIKE '%ondrejka%')
  AND p.position = 'CEN';

-- Ordonez (Parma C = 8)
UPDATE players p SET initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%parma%')
  AND (LOWER(p.name) LIKE '%ordonez%')
  AND p.position = 'CEN';

-- Oristanio (Parma C = 8)
UPDATE players p SET initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%parma%')
  AND (LOWER(p.name) LIKE '%oristanio%')
  AND p.position = 'CEN';

-- Orsolini (Bologna C = 29)
UPDATE players p SET initial_price = 29
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%bologna%')
  AND (LOWER(p.name) LIKE '%orsolini%')
  AND p.position = 'CEN';

-- Palestra (Cagliari C = 15)
UPDATE players p SET initial_price = 15
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cagliari%')
  AND (LOWER(p.name) LIKE '%palestra%')
  AND p.position = 'CEN';

-- Papadopoulos (Atalanta C = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%papadopoulos%')
  AND p.position = 'CEN';

-- Pasalic (Atalanta C = 13)
UPDATE players p SET initial_price = 13
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%pasalic%')
  AND p.position = 'CEN';

-- Payero (Cremonese C = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%payero%')
  AND p.position = 'CEN';

-- Pellegrini (Roma C = 11)
UPDATE players p SET initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%roma%' AND LOWER(rt.name) NOT LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%pellegrini%')
  AND p.position = 'CEN';

-- Perciun (Torino C = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%perciun%')
  AND p.position = 'CEN';

-- Perrone (Como C = 16)
UPDATE players p SET initial_price = 16
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%como%')
  AND (LOWER(p.name) LIKE '%perrone%')
  AND p.position = 'CEN';

-- Piccinini G (Pisa C = 8)
UPDATE players p SET initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%pisa%')
  AND (LOWER(p.name) LIKE '%piccinini%')
  AND p.position = 'CEN';

-- Piotrowski (Udinese C = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%udinese%')
  AND (LOWER(p.name) LIKE '%piotrowski%')
  AND p.position = 'CEN';

-- Pisilli (Roma C = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%roma%' AND LOWER(rt.name) NOT LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%pisilli%')
  AND p.position = 'CEN';

-- Plicco (Parma C = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%parma%')
  AND (LOWER(p.name) LIKE '%plicco%')
  AND p.position = 'CEN';

-- Pobega (Bologna C = 7)
UPDATE players p SET initial_price = 7
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%bologna%')
  AND (LOWER(p.name) LIKE '%pobega%')
  AND p.position = 'CEN';

-- Prati (Torino C = 7)
UPDATE players p SET initial_price = 7
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%prati%')
  AND p.position = 'CEN';

-- Przyborek (Lazio C = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lazio%')
  AND (LOWER(p.name) LIKE '%przyborek%')
  AND p.position = 'CEN';

-- Pulisic (Milan C = 31)
UPDATE players p SET initial_price = 31
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%milan%' AND LOWER(rt.name) NOT LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%pulisic%')
  AND p.position = 'CEN';

-- Rabiot (Milan C = 23)
UPDATE players p SET initial_price = 23
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%milan%' AND LOWER(rt.name) NOT LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%rabiot%')
  AND p.position = 'CEN';

-- Ramadani (Lecce C = 12)
UPDATE players p SET initial_price = 12
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lecce%')
  AND (LOWER(p.name) LIKE '%ramadani%')
  AND p.position = 'CEN';

-- Ricci S (Milan C = 16)
UPDATE players p SET initial_price = 16
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%milan%' AND LOWER(rt.name) NOT LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%ricci%')
  AND p.position = 'CEN';

-- Rodriguez J (Como C = 12)
UPDATE players p SET initial_price = 12
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%como%')
  AND (LOWER(p.name) LIKE '%rodriguez%')
  AND p.position = 'CEN';

-- Rovella (Lazio C = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lazio%')
  AND (LOWER(p.name) LIKE '%rovella%')
  AND p.position = 'CEN';

-- Rowe (Bologna C = 12)
UPDATE players p SET initial_price = 12
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%bologna%')
  AND (LOWER(p.name) LIKE '%rowe%')
  AND p.position = 'CEN';

-- Sabiri (Fiorentina C = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%fiorentina%')
  AND (LOWER(p.name) LIKE '%sabiri%')
  AND p.position = 'CEN';

-- Saelemaekers (Milan C = 18)
UPDATE players p SET initial_price = 18
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%milan%' AND LOWER(rt.name) NOT LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%saelemaekers%')
  AND p.position = 'CEN';

-- Samardzic (Atalanta C = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%samardzic%')
  AND p.position = 'CEN';

-- Serdar (Verona C = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%serdar%')
  AND p.position = 'CEN';

-- Sergi Roberto (Como C = 7)
UPDATE players p SET initial_price = 7
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%como%')
  AND (LOWER(p.name) LIKE '%sergi%' AND LOWER(p.name) LIKE '%roberto%')
  AND p.position = 'CEN';

-- Sohm (Bologna C = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%bologna%')
  AND (LOWER(p.name) LIKE '%sohm%')
  AND p.position = 'CEN';

-- Sorensen O (Parma C = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%parma%')
  AND (LOWER(p.name) LIKE '%sorensen%')
  AND p.position = 'CEN';

-- Sottil (Lecce C = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lecce%')
  AND (LOWER(p.name) LIKE '%sottil%')
  AND p.position = 'CEN';

-- Soule (Roma C = 26)
UPDATE players p SET initial_price = 26
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%roma%' AND LOWER(rt.name) NOT LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%soule%')
  AND p.position = 'CEN';

-- Stengs (Pisa C = 5)
UPDATE players p SET initial_price = 5
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%pisa%')
  AND (LOWER(p.name) LIKE '%stengs%')
  AND p.position = 'CEN';

-- Strefezza (Parma C = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%parma%')
  AND (LOWER(p.name) LIKE '%strefezza%')
  AND p.position = 'CEN';

-- Sucic (Inter C = 11)
UPDATE players p SET initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%sucic%')
  AND p.position = 'CEN';

-- Sulemana (Cagliari C = 5)
UPDATE players p SET initial_price = 5
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cagliari%')
  AND (LOWER(p.name) LIKE '%sulemana%')
  AND p.position = 'CEN';

-- Sulemana K (Atalanta C = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%sulemana%')
  AND p.position = 'CEN';

-- Suslov (Verona C = 8)
UPDATE players p SET initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%suslov%')
  AND p.position = 'CEN';

-- Tameze (Torino C = 5)
UPDATE players p SET initial_price = 5
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%tameze%')
  AND p.position = 'CEN';

-- Taylor (Lazio C = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lazio%')
  AND (LOWER(p.name) LIKE '%taylor%')
  AND p.position = 'CEN';

-- Thorsby (Cremonese C = 12)
UPDATE players p SET initial_price = 12
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%thorsby%')
  AND p.position = 'CEN';

-- Thorstvedt (Sassuolo C = 12)
UPDATE players p SET initial_price = 12
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%sassuolo%')
  AND (LOWER(p.name) LIKE '%thorstvedt%')
  AND p.position = 'CEN';

-- Thuram K (Juventus C = 20)
UPDATE players p SET initial_price = 20
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND ((LOWER(rt.name) LIKE '%juventus%' OR LOWER(rt.name) LIKE '%juve%'))
  AND (LOWER(p.name) LIKE '%thuram%')
  AND p.position = 'CEN';

-- Tomczyk (Bologna C = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%bologna%')
  AND (LOWER(p.name) LIKE '%tomczyk%')
  AND p.position = 'CEN';

-- Topalovic (Inter C = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%topalovic%')
  AND p.position = 'CEN';

-- Toure Id (Pisa C = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%pisa%')
  AND (LOWER(p.name) LIKE '%toure%')
  AND p.position = 'CEN';

-- Tramoni (Pisa C = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%pisa%')
  AND (LOWER(p.name) LIKE '%tramoni%')
  AND p.position = 'CEN';

-- Traore C (Milan C = 2)
UPDATE players p SET initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%milan%' AND LOWER(rt.name) NOT LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%traore%')
  AND p.position = 'CEN';

-- Vandeputte (Cremonese C = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%vandeputte%')
  AND p.position = 'CEN';

-- Vergara (Napoli C = 5)
UPDATE players p SET initial_price = 5
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%napoli%')
  AND (LOWER(p.name) LIKE '%vergara%')
  AND p.position = 'CEN';

-- Vlasic (Torino C = 18)
UPDATE players p SET initial_price = 18
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%vlasic%')
  AND p.position = 'CEN';

-- Volpato C (Sassuolo C = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%sassuolo%')
  AND (LOWER(p.name) LIKE '%volpato%')
  AND p.position = 'CEN';

-- Vos (Milan C = 2)
UPDATE players p SET initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%milan%' AND LOWER(rt.name) NOT LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%vos%')
  AND p.position = 'CEN';

-- Vranckx (Sassuolo C = 3)
UPDATE players p SET initial_price = 3
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%sassuolo%')
  AND (LOWER(p.name) LIKE '%vranckx%')
  AND p.position = 'CEN';

-- Vural (Pisa C = 3)
UPDATE players p SET initial_price = 3
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%pisa%')
  AND (LOWER(p.name) LIKE '%vural%')
  AND p.position = 'CEN';

-- Yildiz V (Verona C = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%yildiz%')
  AND p.position = 'CEN';

-- Yilmaz (Lecce C = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lecce%')
  AND (LOWER(p.name) LIKE '%yilmaz%')
  AND p.position = 'CEN';

-- Zaccagni (Lazio C = 20)
UPDATE players p SET initial_price = 20
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lazio%')
  AND (LOWER(p.name) LIKE '%zaccagni%')
  AND p.position = 'CEN';

-- Zaniolo (Udinese C = 18)
UPDATE players p SET initial_price = 18
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%udinese%')
  AND (LOWER(p.name) LIKE '%zaniolo%')
  AND p.position = 'CEN';

-- Zaragoza (Roma C = 11)
UPDATE players p SET initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%roma%' AND LOWER(rt.name) NOT LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%zaragoza%')
  AND p.position = 'CEN';

-- Zarraga (Udinese C = 4)
UPDATE players p SET initial_price = 4
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%udinese%')
  AND (LOWER(p.name) LIKE '%zarraga%')
  AND p.position = 'CEN';

-- Zerbin (Cremonese C = 7)
UPDATE players p SET initial_price = 7
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%zerbin%')
  AND p.position = 'CEN';

-- Zhegrova (Juventus C = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND ((LOWER(rt.name) LIKE '%juventus%' OR LOWER(rt.name) LIKE '%juve%'))
  AND (LOWER(p.name) LIKE '%zhegrova%')
  AND p.position = 'CEN';

-- Zielinski (Inter C = 21)
UPDATE players p SET initial_price = 21
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%zielinski%')
  AND p.position = 'CEN';

-- Aboukhlal (Torino A = 8)
UPDATE players p SET initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%aboukhlal%')
  AND p.position = 'ATT';

-- Adams (Torino A = 14)
UPDATE players p SET initial_price = 14
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%adams%')
  AND p.position = 'ATT';

-- Ajayi (Verona A = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%ajayi%')
  AND p.position = 'ATT';

-- Albarracin (Cagliari A = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cagliari%')
  AND (LOWER(p.name) LIKE '%albarracin%')
  AND p.position = 'ATT';

-- Almqvist (Parma A = 2)
UPDATE players p SET initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%parma%')
  AND (LOWER(p.name) LIKE '%almqvist%')
  AND p.position = 'ATT';

-- Amin Sarr (Verona A = 8)
UPDATE players p SET initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%amin%' AND LOWER(p.name) LIKE '%sarr%')
  AND p.position = 'ATT';

-- Anghele (Juventus A = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND ((LOWER(rt.name) LIKE '%juventus%' OR LOWER(rt.name) LIKE '%juve%'))
  AND (LOWER(p.name) LIKE '%anghele%')
  AND p.position = 'ATT';

-- Arena A (Roma A = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%roma%' AND LOWER(rt.name) NOT LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%arena%')
  AND p.position = 'ATT';

-- Balentien (Milan A = 2)
UPDATE players p SET initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%milan%' AND LOWER(rt.name) NOT LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%balentien%')
  AND p.position = 'ATT';

-- Banda (Lecce A = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lecce%')
  AND (LOWER(p.name) LIKE '%banda%')
  AND p.position = 'ATT';

-- Bayo (Udinese A = 2)
UPDATE players p SET initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%udinese%')
  AND (LOWER(p.name) LIKE '%bayo%')
  AND p.position = 'ATT';

-- Belotti (Cagliari A = 6)
UPDATE players p SET initial_price = 6
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cagliari%')
  AND (LOWER(p.name) LIKE '%belotti%')
  AND p.position = 'ATT';

-- Berardi (Sassuolo A = 18)
UPDATE players p SET initial_price = 18
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%sassuolo%')
  AND (LOWER(p.name) LIKE '%berardi%')
  AND p.position = 'ATT';

-- Boga (Juventus A = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND ((LOWER(rt.name) LIKE '%juventus%' OR LOWER(rt.name) LIKE '%juve%'))
  AND (LOWER(p.name) LIKE '%boga%')
  AND p.position = 'ATT';

-- Bonazzoli (Cremonese A = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%bonazzoli%')
  AND p.position = 'ATT';

-- Bonny (Inter A = 11)
UPDATE players p SET initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%bonny%')
  AND p.position = 'ATT';

-- Borrelli (Cagliari A = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cagliari%')
  AND (LOWER(p.name) LIKE '%borrelli%')
  AND p.position = 'ATT';

-- Bowie (Verona A = 5)
UPDATE players p SET initial_price = 5
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%bowie%')
  AND p.position = 'ATT';

-- Buksa A (Udinese A = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%udinese%')
  AND (LOWER(p.name) LIKE '%buksa%')
  AND p.position = 'ATT';

-- Camarda (Lecce A = 3)
UPDATE players p SET initial_price = 3
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lecce%')
  AND (LOWER(p.name) LIKE '%camarda%')
  AND p.position = 'ATT';

-- Cambiaghi (Bologna A = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%bologna%')
  AND (LOWER(p.name) LIKE '%cambiaghi%')
  AND p.position = 'ATT';

-- Cancellieri (Lazio A = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lazio%')
  AND (LOWER(p.name) LIKE '%cancellieri%')
  AND p.position = 'ATT';

-- Castro S (Bologna A = 20)
UPDATE players p SET initial_price = 20
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%bologna%')
  AND (LOWER(p.name) LIKE '%castro%')
  AND p.position = 'ATT';

-- Cheddira (Lecce A = 4)
UPDATE players p SET initial_price = 4
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lecce%')
  AND (LOWER(p.name) LIKE '%cheddira%')
  AND p.position = 'ATT';

-- Colombo (Genoa A = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%genoa%')
  AND (LOWER(p.name) LIKE '%colombo%')
  AND p.position = 'ATT';

-- Dallinga (Bologna A = 8)
UPDATE players p SET initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%bologna%')
  AND (LOWER(p.name) LIKE '%dallinga%')
  AND p.position = 'ATT';

-- David (Juventus A = 21)
UPDATE players p SET initial_price = 21
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND ((LOWER(rt.name) LIKE '%juventus%' OR LOWER(rt.name) LIKE '%juve%'))
  AND (LOWER(p.name) LIKE '%david%')
  AND p.position = 'ATT';

-- Davis (Udinese A = 12)
UPDATE players p SET initial_price = 12
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%udinese%')
  AND (LOWER(p.name) LIKE '%davis%')
  AND p.position = 'ATT';

-- Dia (Lazio A = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lazio%')
  AND (LOWER(p.name) LIKE '%dia%')
  AND p.position = 'ATT';

-- Djuric (Cremonese A = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%djuric%')
  AND p.position = 'ATT';

-- Douvikas (Como A = 15)
UPDATE players p SET initial_price = 15
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%como%')
  AND (LOWER(p.name) LIKE '%douvikas%')
  AND p.position = 'ATT';

-- Dovbyk (Roma A = 16)
UPDATE players p SET initial_price = 16
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%roma%' AND LOWER(rt.name) NOT LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%dovbyk%')
  AND p.position = 'ATT';

-- Durosinmi (Pisa A = 8)
UPDATE players p SET initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%pisa%')
  AND (LOWER(p.name) LIKE '%durosinmi%')
  AND p.position = 'ATT';

-- Dybala (Roma A = 19)
UPDATE players p SET initial_price = 19
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%roma%' AND LOWER(rt.name) NOT LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%dybala%')
  AND p.position = 'ATT';

-- Ekhator (Genoa A = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%genoa%')
  AND (LOWER(p.name) LIKE '%ekhator%')
  AND p.position = 'ATT';

-- Ekuban (Genoa A = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%genoa%')
  AND (LOWER(p.name) LIKE '%ekuban%')
  AND p.position = 'ATT';

-- El Shaarawy (Roma A = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%roma%' AND LOWER(rt.name) NOT LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%shaarawy%')
  AND p.position = 'ATT';

-- Elphege (Parma A = 3)
UPDATE players p SET initial_price = 3
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%parma%')
  AND (LOWER(p.name) LIKE '%elphege%')
  AND p.position = 'ATT';

-- Esposito F (Inter A = 14)
UPDATE players p SET initial_price = 14
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%esposito%')
  AND p.position = 'ATT';

-- Esposito S (Cagliari A = 11)
UPDATE players p SET initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cagliari%')
  AND (LOWER(p.name) LIKE '%esposito%')
  AND p.position = 'ATT';

-- Ferguson E (Roma A = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%roma%' AND LOWER(rt.name) NOT LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%ferguson%')
  AND p.position = 'ATT';

-- Fernandes S (Lazio A = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lazio%')
  AND (LOWER(p.name) LIKE '%fernandes%')
  AND p.position = 'ATT';

-- Frigan (Parma A = 5)
UPDATE players p SET initial_price = 5
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%parma%')
  AND (LOWER(p.name) LIKE '%frigan%')
  AND p.position = 'ATT';

-- Fullkrug (Milan A = 15)
UPDATE players p SET initial_price = 15
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%milan%' AND LOWER(rt.name) NOT LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%fullkrug%')
  AND p.position = 'ATT';

-- Gabellini (Torino A = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%gabellini%')
  AND p.position = 'ATT';

-- Gimenez S (Milan A = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%milan%' AND LOWER(rt.name) NOT LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%gimenez%')
  AND p.position = 'ATT';

-- Giovane S (Napoli A = 11)
UPDATE players p SET initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%napoli%')
  AND (LOWER(p.name) LIKE '%giovane%')
  AND p.position = 'ATT';

-- Gudmundsson (Fiorentina A = 17)
UPDATE players p SET initial_price = 17
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%fiorentina%')
  AND (LOWER(p.name) LIKE '%gudmundsson%')
  AND p.position = 'ATT';

-- Gueye (Udinese A = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%udinese%')
  AND (LOWER(p.name) LIKE '%gueye%')
  AND p.position = 'ATT';

-- Hojlund (Napoli A = 19)
UPDATE players p SET initial_price = 19
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%napoli%')
  AND (LOWER(p.name) LIKE '%hojlund%')
  AND p.position = 'ATT';

-- Isaac (Verona A = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%isaac%')
  AND p.position = 'ATT';

-- Kean (Fiorentina A = 26)
UPDATE players p SET initial_price = 26
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%fiorentina%')
  AND (LOWER(p.name) LIKE '%kean%')
  AND p.position = 'ATT';

-- Kilicsoy (Cagliari A = 14)
UPDATE players p SET initial_price = 14
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cagliari%')
  AND (LOWER(p.name) LIKE '%kilicsoy%')
  AND p.position = 'ATT';

-- Krstovic (Atalanta A = 18)
UPDATE players p SET initial_price = 18
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%krstovic%')
  AND p.position = 'ATT';

-- Kulenovic (Torino A = 6)
UPDATE players p SET initial_price = 6
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%kulenovic%')
  AND p.position = 'ATT';

-- Lauriente' (Sassuolo A = 19)
UPDATE players p SET initial_price = 19
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%sassuolo%')
  AND (LOWER(p.name) LIKE '%lauriente''%')
  AND p.position = 'ATT';

-- Lavelli (Inter A = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%lavelli%')
  AND p.position = 'ATT';

-- Leao (Milan A = 22)
UPDATE players p SET initial_price = 22
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%milan%' AND LOWER(rt.name) NOT LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%leao%')
  AND p.position = 'ATT';

-- Licina (Juventus A = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND ((LOWER(rt.name) LIKE '%juventus%' OR LOWER(rt.name) LIKE '%juve%'))
  AND (LOWER(p.name) LIKE '%licina%')
  AND p.position = 'ATT';

-- Lukaku R (Napoli A = 15)
UPDATE players p SET initial_price = 15
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%napoli%')
  AND (LOWER(p.name) LIKE '%lukaku%')
  AND p.position = 'ATT';

-- Luna (Verona A = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%luna%')
  AND p.position = 'ATT';

-- Malen (Roma A = 20)
UPDATE players p SET initial_price = 20
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%roma%' AND LOWER(rt.name) NOT LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%malen%')
  AND p.position = 'ATT';

-- Martinez L (Inter A = 43)
UPDATE players p SET initial_price = 43
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%martinez%')
  AND p.position = 'ATT';

-- Meister (Pisa A = 4)
UPDATE players p SET initial_price = 4
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%pisa%')
  AND (LOWER(p.name) LIKE '%meister%')
  AND p.position = 'ATT';

-- Milik (Juventus A = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND ((LOWER(rt.name) LIKE '%juventus%' OR LOWER(rt.name) LIKE '%juve%'))
  AND (LOWER(p.name) LIKE '%milik%')
  AND p.position = 'ATT';

-- Misitano (Atalanta A = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%misitano%')
  AND p.position = 'ATT';

-- Morata (Como A = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%como%')
  AND (LOWER(p.name) LIKE '%morata%')
  AND p.position = 'ATT';

-- Moreo (Pisa A = 12)
UPDATE players p SET initial_price = 12
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%pisa%')
  AND (LOWER(p.name) LIKE '%moreo%')
  AND p.position = 'ATT';

-- Moro L (Sassuolo A = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%sassuolo%')
  AND (LOWER(p.name) LIKE '%moro%')
  AND p.position = 'ATT';

-- Mosquera (Verona A = 8)
UPDATE players p SET initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%mosquera%')
  AND p.position = 'ATT';

-- Moumbagna (Cremonese A = 2)
UPDATE players p SET initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%moumbagna%')
  AND p.position = 'ATT';

-- N'Dri (Lecce A = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lecce%')
  AND (LOWER(p.name) LIKE '%n''dri%')
  AND p.position = 'ATT';

-- Nkunku (Milan A = 16)
UPDATE players p SET initial_price = 16
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%milan%' AND LOWER(rt.name) NOT LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%nkunku%')
  AND p.position = 'ATT';

-- Noslin (Lazio A = 7)
UPDATE players p SET initial_price = 7
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lazio%')
  AND (LOWER(p.name) LIKE '%noslin%')
  AND p.position = 'ATT';

-- Nuredini (Genoa A = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%genoa%')
  AND (LOWER(p.name) LIKE '%nuredini%')
  AND p.position = 'ATT';

-- Nzola (Sassuolo A = 6)
UPDATE players p SET initial_price = 6
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%sassuolo%')
  AND (LOWER(p.name) LIKE '%nzola%')
  AND p.position = 'ATT';

-- Odgaard (Bologna A = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%bologna%')
  AND (LOWER(p.name) LIKE '%odgaard%')
  AND p.position = 'ATT';

-- Okereke (Cremonese A = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%okereke%')
  AND p.position = 'ATT';

-- Openda (Juventus A = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND ((LOWER(rt.name) LIKE '%juventus%' OR LOWER(rt.name) LIKE '%juve%'))
  AND (LOWER(p.name) LIKE '%openda%')
  AND p.position = 'ATT';

-- Orban G (Verona A = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%verona%')
  AND (LOWER(p.name) LIKE '%orban%')
  AND p.position = 'ATT';

-- Pavoletti (Cagliari A = 6)
UPDATE players p SET initial_price = 6
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cagliari%')
  AND (LOWER(p.name) LIKE '%pavoletti%')
  AND p.position = 'ATT';

-- Pedro R (Lazio A = 11)
UPDATE players p SET initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lazio%')
  AND (LOWER(p.name) LIKE '%pedro%')
  AND p.position = 'ATT';

-- Pellegrino Ma (Parma A = 13)
UPDATE players p SET initial_price = 13
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%parma%')
  AND (LOWER(p.name) LIKE '%pellegrino%')
  AND p.position = 'ATT';

-- Piccoli (Fiorentina A = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%fiorentina%')
  AND (LOWER(p.name) LIKE '%piccoli%')
  AND p.position = 'ATT';

-- Pierotti (Lecce A = 7)
UPDATE players p SET initial_price = 7
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lecce%')
  AND (LOWER(p.name) LIKE '%pierotti%')
  AND p.position = 'ATT';

-- Pinamonti (Sassuolo A = 14)
UPDATE players p SET initial_price = 14
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%sassuolo%')
  AND (LOWER(p.name) LIKE '%pinamonti%')
  AND p.position = 'ATT';

-- Pisano M (Como A = 2)
UPDATE players p SET initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%como%')
  AND (LOWER(p.name) LIKE '%pisano%')
  AND p.position = 'ATT';

-- Politano (Napoli A = 16)
UPDATE players p SET initial_price = 16
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%napoli%')
  AND (LOWER(p.name) LIKE '%politano%')
  AND p.position = 'ATT';

-- Pugno (Juventus A = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND ((LOWER(rt.name) LIKE '%juventus%' OR LOWER(rt.name) LIKE '%juve%'))
  AND (LOWER(p.name) LIKE '%pugno%')
  AND p.position = 'ATT';

-- Raspadori (Atalanta A = 16)
UPDATE players p SET initial_price = 16
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%raspadori%')
  AND p.position = 'ATT';

-- Ratkov (Lazio A = 8)
UPDATE players p SET initial_price = 8
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lazio%')
  AND (LOWER(p.name) LIKE '%ratkov%')
  AND p.position = 'ATT';

-- Sanabria (Cremonese A = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%sanabria%')
  AND p.position = 'ATT';

-- Savva (Torino A = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%savva%')
  AND p.position = 'ATT';

-- Scamacca (Atalanta A = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%scamacca%')
  AND p.position = 'ATT';

-- Scotti (Milan A = 2)
UPDATE players p SET initial_price = 2
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%milan%' AND LOWER(rt.name) NOT LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%scotti%')
  AND p.position = 'ATT';

-- Simeone (Torino A = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%simeone%')
  AND p.position = 'ATT';

-- Solomon (Fiorentina A = 13)
UPDATE players p SET initial_price = 13
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%fiorentina%')
  AND (LOWER(p.name) LIKE '%solomon%')
  AND p.position = 'ATT';

-- Stojilkovic (Pisa A = 3)
UPDATE players p SET initial_price = 3
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%pisa%')
  AND (LOWER(p.name) LIKE '%stojilkovic%')
  AND p.position = 'ATT';

-- Stulic (Lecce A = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%lecce%')
  AND (LOWER(p.name) LIKE '%stulic%')
  AND p.position = 'ATT';

-- Thuram (Inter A = 31)
UPDATE players p SET initial_price = 31
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%inter%')
  AND (LOWER(p.name) LIKE '%thuram%')
  AND p.position = 'ATT';

-- Trepy (Cagliari A = 3)
UPDATE players p SET initial_price = 3
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cagliari%')
  AND (LOWER(p.name) LIKE '%trepy%')
  AND p.position = 'ATT';

-- Vardy (Cremonese A = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%vardy%')
  AND p.position = 'ATT';

-- Vavassori (Atalanta A = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%atalanta%')
  AND (LOWER(p.name) LIKE '%vavassori%')
  AND p.position = 'ATT';

-- Vaz (Roma A = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%roma%' AND LOWER(rt.name) NOT LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%vaz%')
  AND p.position = 'ATT';

-- Venturino (Roma A = 3)
UPDATE players p SET initial_price = 3
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%roma%' AND LOWER(rt.name) NOT LIKE '%cremonese%')
  AND (LOWER(p.name) LIKE '%venturino%')
  AND p.position = 'ATT';

-- Vinciati (Udinese A = 1)
UPDATE players p SET initial_price = 1
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%udinese%')
  AND (LOWER(p.name) LIKE '%vinciati%')
  AND p.position = 'ATT';

-- Vitinha (Genoa A = 10)
UPDATE players p SET initial_price = 10
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%genoa%')
  AND (LOWER(p.name) LIKE '%vitinha%')
  AND p.position = 'ATT';

-- Vlahovic (Juventus A = 9)
UPDATE players p SET initial_price = 9
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND ((LOWER(rt.name) LIKE '%juventus%' OR LOWER(rt.name) LIKE '%juve%'))
  AND (LOWER(p.name) LIKE '%vlahovic%')
  AND p.position = 'ATT';

-- Yildiz (Juventus A = 29)
UPDATE players p SET initial_price = 29
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND ((LOWER(rt.name) LIKE '%juventus%' OR LOWER(rt.name) LIKE '%juve%'))
  AND (LOWER(p.name) LIKE '%yildiz%')
  AND p.position = 'ATT';

-- Zapata D (Torino A = 11)
UPDATE players p SET initial_price = 11
FROM real_teams rt
WHERE p.real_team_id = rt.id
  AND (LOWER(rt.name) LIKE '%torino%')
  AND (LOWER(p.name) LIKE '%zapata%')
  AND p.position = 'ATT';

-- Verifica
SELECT position, COUNT(*) as totale,
  COUNT(CASE WHEN initial_price > 1 THEN 1 END) as con_quotazione,
  ROUND(AVG(initial_price)) as media
FROM players GROUP BY position ORDER BY position;