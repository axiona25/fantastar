"""
Analisi voti da cronaca con keyword matching (Parte 2).
Locale, NO LLM/AI API.
"""
# Dizionario keyword → impatto sul voto
POSITIVE_KEYWORDS = {
    "brilliant": 0.5, "excellent": 0.5, "superb": 0.5,
    "stunning": 0.5, "clinical": 0.5, "decisive": 0.5,
    "magnifico": 0.5, "straordinario": 0.5, "decisivo": 0.5,
    "good": 0.3, "clever": 0.3, "neat": 0.3,
    "bravo": 0.3, "ottimo": 0.3, "preciso": 0.3,
    "key pass": 0.3, "passaggio chiave": 0.3,
    "through ball": 0.3, "cross": 0.2,
    "tackle": 0.2, "contrasto": 0.2,
    "save": 0.3, "parata": 0.3,
    "dribble": 0.2, "dribbling": 0.2,
    "finds": 0.1, "plays": 0.1, "passes": 0.1,
}

NEGATIVE_KEYWORDS = {
    "terrible": -0.5, "awful": -0.5, "disastrous": -0.5,
    "errore grave": -0.5, "disastro": -0.5,
    "own goal": -0.5, "autogol": -0.5,
    "poor": -0.3, "wasteful": -0.3, "sloppy": -0.3,
    "sbagliato": -0.3, "impreciso": -0.3,
    "loses possession": -0.3, "palla persa": -0.3,
    "misses": -0.2, "sbaglia": -0.2,
    "wide": -0.1, "fuori": -0.1,
    "foul": -0.2, "fallo": -0.2,
    "booked": -0.2, "ammonito": -0.2,
}

GOAL_ACTIONS = {
    "scores": 1.0, "segna": 1.0, "goal": 1.0, "gol": 1.0,
    "finishes": 0.8, "converts": 0.8, "nets": 0.8,
    "brace": 0.5, "hat-trick": 1.0,
    "assist": 0.5, "assists": 0.5,
    "sets up": 0.4, "serves": 0.3,
}


class LocalRatingService:
    """
    Analisi voti SENZA AI esterna.
    Usa keyword matching sul testo della cronaca.
    """

    def __init__(self) -> None:
        self.player_scores: dict[str, float] = {}
        self.player_mentions: dict[str, int] = {}
        self.player_actions: dict[str, list[dict]] = {}

    def analyze_entry(self, entry: dict, known_players: list[str]) -> list[dict]:
        """
        Analizza una singola entry della cronaca.
        Ritorna lista aggiornata di rating (get_all_ratings).
        """
        text = (entry.get("text") or "").lower()
        minute = entry.get("minute") or 0

        for player_name in known_players:
            if self._player_mentioned(text, player_name):
                impact = self._calculate_impact(text)
                if player_name not in self.player_scores:
                    self.player_scores[player_name] = 6.0
                    self.player_mentions[player_name] = 0
                    self.player_actions[player_name] = []
                self.player_scores[player_name] += impact
                self.player_mentions[player_name] += 1
                self.player_actions[player_name].append({
                    "minute": minute,
                    "text": (entry.get("text") or "")[:80],
                    "impact": impact,
                })
                self.player_scores[player_name] = max(
                    3.0, min(10.0, self.player_scores[player_name])
                )
        return self.get_all_ratings()

    def _calculate_impact(self, text: str) -> float:
        impact = 0.0
        for keyword, value in GOAL_ACTIONS.items():
            if keyword in text:
                impact += value
        for keyword, value in POSITIVE_KEYWORDS.items():
            if keyword in text:
                impact += value
        for keyword, value in NEGATIVE_KEYWORDS.items():
            if keyword in text:
                impact += value
        return impact

    def _player_mentioned(self, text: str, player_name: str) -> bool:
        name_parts = player_name.lower().split()
        return any(part in text for part in name_parts if len(part) > 3)

    def get_all_ratings(self) -> list[dict]:
        ratings = []
        for name, score in self.player_scores.items():
            actions = self.player_actions.get(name) or []
            prev_score = score - (actions[-1]["impact"] if actions else 0)
            trend = "up" if score > prev_score else ("down" if score < prev_score else "stable")
            last_action = actions[-1] if actions else None
            last_action_str: str | None = None
            if last_action:
                last_action_str = f"{last_action.get('text', '')} ({last_action.get('minute', 0)}')"
            ratings.append({
                "player_name": name,
                "rating": round(score, 1),
                "mentions": self.player_mentions.get(name, 0),
                "trend": trend,
                "last_action": last_action_str,
            })
        return sorted(ratings, key=lambda x: x["rating"], reverse=True)
