"""Schema per API partite (live list e dettaglio)."""
from datetime import datetime

from pydantic import BaseModel


class TeamSummary(BaseModel):
    """Squadra nel dettaglio partita (nome, sigla, stemma)."""
    name: str
    short: str | None = None  # TLA
    crest: str | None = None


class RefereeSummary(BaseModel):
    """Arbitro (da football-data.org)."""
    name: str
    nationality: str | None = None


class MatchEventDetail(BaseModel):
    """Evento cronaca (gol, cartellino, sostituzione)."""
    minute: str | int  # es. "15'", "90'+4" o numero
    type: str  # Goal, Yellow Card, Red Card, Substitution
    team: str | None = None  # "home" | "away"
    player: str | None = None
    detail: str | None = None  # es. "Assist: Colpani", "Rigore"
    player_in: str | None = None
    player_out: str | None = None


class LineupPlayer(BaseModel):
    name: str
    number: str | int | None = None
    position: str | None = None


class TeamLineup(BaseModel):
    formation: str | None = None
    starting: list[LineupPlayer] = []
    substitutes: list[LineupPlayer] = []


class StatisticsEntry(BaseModel):
    """Una riga statistiche (nome IT, valore casa, valore trasferta)."""
    name: str
    home: str
    away: str


class CommentaryEntry(BaseModel):
    minute: str
    text: str


class MatchStatistics(BaseModel):
    """Statistiche comparative casa/trasferta (legacy)."""
    possession: list[int] = []
    shots: list[int] = []
    shots_on_target: list[int] = []
    corners: list[int] = []
    fouls: list[int] = []
    offsides: list[int] = []
    yellow_cards: list[int] = []
    red_cards: list[int] = []


class MatchDetailFullResponse(BaseModel):
    """Dettaglio partita: risultato, arbitro, stadio, eventi, formazioni, statistiche (IT), cronaca testuale."""
    id: int
    matchday: int
    status: str
    minute: int | None = None
    kick_off: datetime | None = None
    home_team: TeamSummary
    away_team: TeamSummary
    home_score: int | None = None
    away_score: int | None = None
    referee: RefereeSummary | None = None
    venue: str | None = None
    events: list[MatchEventDetail] = []
    lineups: dict[str, TeamLineup] = {}
    statistics: list[StatisticsEntry] = []
    statistics_legacy: MatchStatistics | None = None
    commentary: list[CommentaryEntry] = []
    translated: bool = True  # False = traduzione in corso in background


class MatchListItem(BaseModel):
    id: int
    matchday: int
    home_team_name: str
    away_team_name: str
    home_score: int | None
    away_score: int | None
    minute: int | None
    status: str
    kick_off: datetime | None = None
    home_crest: str | None = None
    away_crest: str | None = None
    home_tla: str | None = None
    away_tla: str | None = None

    class Config:
        from_attributes = True


class MatchEventItem(BaseModel):
    type: str
    minute: int | None

    class Config:
        from_attributes = True


class MatchDetailResponse(BaseModel):
    id: int
    matchday: int
    home_team_name: str
    away_team_name: str
    home_score: int | None
    away_score: int | None
    minute: int | None
    status: str
    events: list[MatchEventItem]

    class Config:
        from_attributes = True


class PlayerRatingRow(BaseModel):
    """Pagella: voto giocatore per partita (da player_ai_ratings)."""
    player_id: int
    player_name: str
    rating: float
    trend: str
    mentions: int
    minute: int

    class Config:
        from_attributes = True


class MatchRatingPlayerEvents(BaseModel):
    """Eventi fantacalcio per il giocatore (gol, assist, cartellini, sostituzione, infortunio, ecc.)."""
    goals: int = 0
    assists: int = 0
    own_goals: int = 0
    yellow_cards: int = 0
    red_cards: int = 0
    penalty_saved: int = 0
    penalty_missed: int = 0
    goals_conceded: int = 0
    saves: int = 0
    shots_on_target: int = 0
    minutes_played: int = 0
    subbed_in: int = 0
    subbed_out: int = 0
    injury: int = 0


class MatchRatingPlayerEventItem(BaseModel):
    """Singolo evento (gol, cartellino, ecc.) per il giocatore."""
    type: str  # goal, yellow_card, red_card, penalty_missed, penalty_saved, own_goal, injury
    minute: int | None = None


class MatchRatingPlayer(BaseModel):
    """Un giocatore nella tab voti partita."""
    name: str
    player_id: int | None = None  # ID DB per avatar: /static/media/avatars/{player_id}.png
    role: str = "CEN"
    number: str | int | None = None
    live_rating: float | None = None
    fantasy_score: float | None = None
    is_starter: bool = True
    played: bool = True
    subbed_in: bool = False
    subbed_out: bool = False
    minute_in: int | None = None
    minute_out: int | None = None
    events: MatchRatingPlayerEvents = MatchRatingPlayerEvents()
    event_list: list[MatchRatingPlayerEventItem] = []
    photo_url: str | None = None
    cutout_url: str | None = None


class MatchRatingTeam(BaseModel):
    """Squadra nella tab voti (casa o trasferta): titolari e panchina separati."""
    name: str
    starters: list[MatchRatingPlayer] = []
    bench: list[MatchRatingPlayer] = []


class MatchRatingsResponse(BaseModel):
    """Risposta GET /matches/{id}/ratings: voti live o ufficiali per partita."""
    match_id: int
    source: str = "algorithm"
    is_final: bool = False
    home_team: MatchRatingTeam = MatchRatingTeam(name="")
    away_team: MatchRatingTeam = MatchRatingTeam(name="")


class MatchHighlightItem(BaseModel):
    """Video highlight (ScoreBat o YouTube): watch_url per aprire in app/browser esterno."""
    title: str = ""
    embed: str = ""
    thumbnail: str = ""
    competition: str = ""
    matchviewUrl: str = ""
    video_id: str | None = None  # YouTube
    embed_url: str | None = None  # YouTube embed URL
    watch_url: str = ""  # URL da aprire con url_launcher (ScoreBat page o YouTube watch)
    source: str = ""  # "ScoreBat" o canale YouTube per sottotitolo
