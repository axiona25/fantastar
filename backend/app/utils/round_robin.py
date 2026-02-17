"""
Calendario round-robin (circle method): andata con N-1 giornate, ogni squadra gioca contro tutte.
"""


def generate_round_robin(team_ids: list) -> list[list[tuple]]:
    """
    Genera un calendario round-robin per N squadre (N pari).
    Ritorna lista di giornate; ogni giornata è lista di tuple (home_id, away_id).

    Algoritmo: circle method. Fissa la prima squadra, ruota le altre.
    """
    teams = list(team_ids)
    n = len(teams)

    if n % 2 != 0:
        raise ValueError("Il numero di squadre deve essere pari")

    rounds: list[list[tuple]] = []
    fixed = teams[0]
    rotating = teams[1:]

    for round_idx in range(n - 1):
        round_matches: list[tuple] = []
        # Prima partita: fixed vs primo della lista rotante (alternando casa/trasferta)
        if round_idx % 2 == 0:
            round_matches.append((fixed, rotating[0]))
        else:
            round_matches.append((rotating[0], fixed))
        # Altre partite: accoppia rotating[i] con rotating[n-1-i] (rotating ha n-1 elementi)
        for i in range(1, n // 2):
            j = n - 1 - i
            home, away = rotating[i], rotating[j]
            if (round_idx + i) % 2 == 0:
                round_matches.append((home, away))
            else:
                round_matches.append((away, home))
        rounds.append(round_matches)
        # Ruota: ultimo va in prima posizione
        rotating = [rotating[-1]] + rotating[:-1]

    return rounds
