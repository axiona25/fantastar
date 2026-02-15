"use client";

import { use } from "react";
import Link from "next/link";
import { useAuth } from "@/hooks/useAuth";
import { useApi } from "@/hooks/useApi";
import { MatchCard } from "@/components/MatchCard";
import type { MatchDetail } from "@/types";
import type { MatchListItem } from "@/types";

function toListItem(m: MatchDetail): MatchListItem {
  return {
    id: m.id,
    matchday: m.matchday,
    home_team_name: m.home_team_name,
    away_team_name: m.away_team_name,
    home_score: m.home_score,
    away_score: m.away_score,
    minute: m.minute,
    status: m.status,
  };
}

export default function MatchDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  useAuth(true);
  const { data: match, isLoading, isError } = useApi<MatchDetail | null>(`/matches/${id}`);

  if (isLoading) return <p className="text-zinc-500 p-4">Caricamento...</p>;
  if (isError || !match) return <p className="text-red-600 p-4">Partita non trovata.</p>;

  return (
    <div className="p-4">
      <Link href="/live" className="text-sm text-zinc-500 underline mb-4 inline-block">← Live</Link>
      <h1 className="text-xl font-semibold">Dettaglio partita</h1>
      <div className="mt-4">
        <MatchCard match={toListItem(match)} />
      </div>
      {match.events?.length ? (
        <>
          <h2 className="text-lg font-medium mt-6 mb-2">Eventi</h2>
          <ul className="text-sm list-disc list-inside">
            {match.events.map((e, i) => (
              <li key={i}>{e.type} {e.minute != null ? `${e.minute}'` : ""}</li>
            ))}
          </ul>
        </>
      ) : (
        <p className="text-zinc-500 mt-4 text-sm">Nessun evento (placeholder).</p>
      )}
    </div>
  );
}
