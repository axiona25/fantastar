"use client";

import Link from "next/link";
import { useAuth } from "@/hooks/useAuth";
import { useApi } from "@/hooks/useApi";
import { PlayerCard } from "@/components/PlayerCard";
import type { PlayerDetail } from "@/types";
import type { PlayerListItem } from "@/types";

function toListItem(p: PlayerDetail): PlayerListItem {
  return {
    id: p.id,
    name: p.name,
    position: p.position,
    real_team_name: p.real_team_name ?? "",
    initial_price: Number(p.initial_price ?? 0),
  };
}

export function PlayerDetailContent({ id }: { id: string }) {
  useAuth(true);
  const { data: player, isLoading, isError } = useApi<PlayerDetail | null>(`/players/${id}`);

  if (isLoading) return <p className="text-zinc-500">Caricamento...</p>;
  if (isError || !player) return <p className="text-red-600">Giocatore non trovato.</p>;

  return (
    <div className="p-4">
      <Link href="/" className="text-sm text-zinc-500 underline mb-4 inline-block">← Dashboard</Link>
      <h1 className="text-xl font-semibold">Dettaglio giocatore</h1>
      <div className="mt-4">
        <PlayerCard player={toListItem(player)} />
      </div>
    </div>
  );
}
