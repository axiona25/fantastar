"use client";

import { Card, CardContent } from "@/components/ui/card";
import type { PlayerListItem } from "@/types";

interface PlayerCardProps {
  player?: PlayerListItem | null;
  /** Placeholder mode when no player */
  placeholder?: boolean;
}

export function PlayerCard({ player, placeholder }: PlayerCardProps) {
  if (placeholder || !player) {
    return (
      <Card>
        <CardContent className="pt-4">
          <p className="text-zinc-500 dark:text-zinc-400">Player card (placeholder)</p>
        </CardContent>
      </Card>
    );
  }
  return (
    <Card>
      <CardContent className="pt-4">
        <p className="font-medium">{player.name}</p>
        <p className="text-sm text-zinc-500">{player.position} · {player.real_team_name}</p>
        <p className="text-sm">Quot. {player.initial_price}</p>
      </CardContent>
    </Card>
  );
}
