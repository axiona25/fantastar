"use client";

import Link from "next/link";
import { useAuth } from "@/hooks/useAuth";
import { useApi } from "@/hooks/useApi";
import type { FantasyLeague, StandingRow } from "@/types";

export function MyTeamContent() {
  const { user } = useAuth(true);
  const { data: leagues } = useApi<FantasyLeague[] | null>("/leagues");
  const firstLeagueId = leagues?.[0]?.id ?? null;
  const { data: standings } = useApi<StandingRow[] | null>(
    firstLeagueId ? `/leagues/${firstLeagueId}/standings` : null
  );
  const myStanding = user && standings?.find((r) => r.user_id === user.id);

  if (!leagues?.length) {
    return (
      <div className="p-4">
        <h1 className="text-xl font-semibold">La mia squadra</h1>
        <p className="text-zinc-500 mt-2">Nessuna lega. Partecipa a una lega per gestire la squadra.</p>
      </div>
    );
  }
  if (!myStanding) {
    return (
      <div className="p-4">
        <h1 className="text-xl font-semibold">La mia squadra</h1>
        <p className="text-zinc-500 mt-2">Non hai ancora una squadra in questa lega (placeholder).</p>
        <Link href="/" className="text-sm underline mt-4 inline-block">← Dashboard</Link>
      </div>
    );
  }
  return (
    <div className="p-4">
      <h1 className="text-xl font-semibold">La mia squadra</h1>
      <p className="text-zinc-500 mt-1">{myStanding.team_name}</p>
      <div className="mt-4 flex gap-4">
        <Link href={`/team/${myStanding.fantasy_team_id}`} className="underline">
          Vedi squadra e rosa
        </Link>
        <Link href={`/team/${myStanding.fantasy_team_id}/lineup/1`} className="underline">
          Imposta formazione
        </Link>
      </div>
      <Link href="/" className="text-sm text-zinc-500 underline mt-4 inline-block">← Dashboard</Link>
    </div>
  );
}
