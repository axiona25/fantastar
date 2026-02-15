"use client";

import { Card, CardContent } from "@/components/ui/card";
import type { MatchListItem } from "@/types";

interface MatchCardProps {
  match?: MatchListItem | null;
  placeholder?: boolean;
}

export function MatchCard({ match, placeholder }: MatchCardProps) {
  if (placeholder || !match) {
    return (
      <Card>
        <CardContent className="pt-4">
          <p className="text-zinc-500 dark:text-zinc-400">Match card (placeholder)</p>
        </CardContent>
      </Card>
    );
  }
  const score = `${match.home_score ?? "-"} - ${match.away_score ?? "-"}`;
  const minute = match.minute != null ? ` ${match.minute}'` : "";
  return (
    <Card>
      <CardContent className="pt-4">
        <p className="font-medium">{match.home_team_name} – {match.away_team_name}</p>
        <p className="text-sm text-zinc-500">Giornata {match.matchday}</p>
        <p>{score}{minute}</p>
      </CardContent>
    </Card>
  );
}
