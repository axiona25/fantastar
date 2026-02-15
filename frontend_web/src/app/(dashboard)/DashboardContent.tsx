"use client";

import Link from "next/link";
import { useAuth } from "@/hooks/useAuth";
import { useApi } from "@/hooks/useApi";
import { MatchCard } from "@/components/MatchCard";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import type { FantasyLeague, StandingRow } from "@/types";

export function DashboardContent() {
  useAuth(true);
  const { data: leagues } = useApi<FantasyLeague[] | null>("/leagues");
  const firstLeagueId = leagues?.[0]?.id ?? null;
  const { data: standings } = useApi<StandingRow[] | null>(
    firstLeagueId ? `/leagues/${firstLeagueId}/standings` : null
  );
  const { user } = useAuth(true);
  const myStanding = user && standings?.find((r) => r.user_id === user.id);
  const top3 = standings?.slice(0, 3) ?? [];

  return (
    <div>
      <h1 className="text-2xl font-semibold">Dashboard</h1>
      <p className="text-zinc-500 mt-1">Overview</p>
      <div className="mt-6 grid gap-4 sm:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>Prossima giornata</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-zinc-500">
              {firstLeagueId ? `Lega: ${leagues?.[0]?.name ?? ""}` : "Nessuna lega (placeholder)"}
            </p>
          </CardContent>
        </Card>
        <Card>
          <CardHeader>
            <CardTitle>Partite</CardTitle>
          </CardHeader>
          <CardContent>
            <MatchCard placeholder />
            <Link href="/live" className="text-sm text-zinc-600 dark:text-zinc-400 underline mt-2 inline-block">
              Live
            </Link>
          </CardContent>
        </Card>
      </div>
      {top3.length > 0 && (
        <Card className="mt-6">
          <CardHeader>
            <CardTitle>Top 3 classifica Fantasy</CardTitle>
          </CardHeader>
          <CardContent>
            <ul className="list-decimal list-inside text-sm">
              {top3.map((r) => (
                <li key={r.fantasy_team_id}>
                  {r.team_name} — {r.total_points} pt
                </li>
              ))}
            </ul>
            <Link href="/standings" className="text-sm underline mt-2 inline-block">Vedi classifica</Link>
          </CardContent>
        </Card>
      )}
      <div className="mt-6 flex flex-wrap gap-4">
        <Link href="/standings" className="underline">Classifiche</Link>
        {myStanding && (
          <Link href={`/team/${myStanding.fantasy_team_id}`} className="underline">
            La mia squadra
          </Link>
        )}
      </div>
    </div>
  );
}
