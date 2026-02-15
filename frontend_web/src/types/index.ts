/** API types aligned with backend (auth, leagues, matches, etc.). */

export interface User {
  id: string;
  email: string;
  username: string;
  full_name: string | null;
  avatar_url: string | null;
  phone_number: string | null;
  is_active: boolean;
  is_admin: boolean;
  created_at: string;
}

export interface Token {
  access_token: string;
  refresh_token: string;
  token_type?: string;
}

export interface StandingRow {
  rank: number;
  fantasy_team_id: string;
  team_name: string;
  user_id: string;
  total_points: number;
  wins: number;
  draws: number;
  losses: number;
  goals_for: number;
  goals_against: number;
}

export interface FantasyLeague {
  id: string;
  name: string;
  invite_code: string;
  admin_user_id?: string;
}

export interface MatchListItem {
  id: number;
  matchday: number;
  home_team_name: string;
  away_team_name: string;
  home_score: number | null;
  away_score: number | null;
  minute: number | null;
  status: string;
}

/** GET /matches/{id} */
export interface MatchDetail {
  id: number;
  matchday: number;
  home_team_name: string;
  away_team_name: string;
  home_score: number | null;
  away_score: number | null;
  minute: number | null;
  status: string;
  events?: { type: string; minute: number | null }[];
}

export interface PlayerListItem {
  id: number;
  name: string;
  position: string;
  real_team_name: string;
  initial_price: number;
}

/** GET /players/{id} */
export interface PlayerDetail {
  id: number;
  name: string;
  position: string;
  real_team_name?: string;
  initial_price?: number;
  [key: string]: unknown;
}

/** GET /teams/{id} */
export interface TeamDetail {
  id: string;
  name: string;
  league_id: string;
  budget_remaining?: number;
  total_points?: number;
  roster?: { player_id: number; player_name: string; position: string; purchase_price?: number }[];
  [key: string]: unknown;
}

/** GET /teams/{id}/lineup/{matchday} */
export interface LineupSlot {
  player_id: number;
  position_slot: string;
  is_starter: boolean;
  bench_order?: number | null;
}
export interface LineupResponse {
  fantasy_team_id: string;
  matchday: number;
  formation: string | null;
  starters: LineupSlot[];
  bench: LineupSlot[];
}

/** GET /news */
export interface NewsItem {
  id: number;
  title: string;
  summary: string | null;
  url: string | null;
  source: string | null;
  image_url: string | null;
  published_at: string | null;
}
