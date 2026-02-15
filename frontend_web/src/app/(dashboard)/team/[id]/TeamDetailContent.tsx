"use client";

import Link from "next/link";
import { useAuth } from "@/hooks/useAuth";
import { useApi } from "@/hooks/useApi";
import type { TeamDetail } from "@/types";

export function TeamDetailContent({ id }: { id: string }) {
  useAuth(true);
  const { data: team, isLoading, isError } = useApi<TeamDetail | null>(`/teams/${id}`);

  if (isLoading) return <p className="text-zinc-500">Caricamento...</p>;
  if (isError || !team) return <p className="text-red-600">Squadra non trovata.</p>;

  const roster = team.roster ?? [];

  return (
    <div className="p-4">
      <Link href="/" className="text-sm text-zinc-500 underline mb-4 inline-block">← Dashboard</Link>
      <h1 className="text-xl font-semibold">{team.name}</h1>
      <p className="text-zinc-500 text-sm mt-1">Lega: {team.league_id}</p>
      {team.total_points != null && <p className="text-sm mt-1">Punti: {team.total_points}</p>}
      <h2 className="text-lg font-medium mt-6 mb-2">Rosa</h2>
      {roster.length === 0 ? (
        <p className="text-zinc-500">Nessun giocatore in rosa (placeholder).</p>
      ) : (
        <ul className="list-disc list-inside text-sm">
          {roster.map((r) => (
            <li key={r.player_id}>
              <Link href={`/player/${r.player_id}`} className="underline">
                {r.player_name}
              </Link>
              {" "}— {r.position}
            </li>
          ))}
        </ul>
      )}
      <div className="mt-6">
        <Link href={`/team/${id}/lineup/1`} className="underline">Imposta formazione (placeholder giornata 1)</Link>
      </div>
    </div>
  );
}
