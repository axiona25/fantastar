"use client";

import { useAuth } from "@/hooks/useAuth";
import { useApi } from "@/hooks/useApi";
import { StandingsTable } from "@/components/StandingsTable";
import type { FantasyLeague, StandingRow } from "@/types";
import { useMemo, useState } from "react";

export function StandingsContent() {
  useAuth(true);
  const { data: leagues } = useApi<FantasyLeague[] | null>("/leagues");
  const [selectedLeagueId, setSelectedLeagueId] = useState<string | null>(null);
  const effectiveLeagueId = selectedLeagueId ?? leagues?.[0]?.id ?? null;
  const { data: standings } = useApi<StandingRow[] | null>(
    effectiveLeagueId ? `/leagues/${effectiveLeagueId}/standings` : null
  );

  const leagueOptions = useMemo(() => leagues ?? [], [leagues]);

  return (
    <div className="p-4">
      <h1 className="text-xl font-semibold">Classifiche</h1>

      <section className="mt-6">
        <h2 className="text-lg font-medium mb-2">Serie A</h2>
        <StandingsTable placeholder />
      </section>

      <section className="mt-8">
        <h2 className="text-lg font-medium mb-2">Classifica Fantasy</h2>
        {leagueOptions.length > 0 ? (
          <>
            <select
              className="mb-3 border border-zinc-300 dark:border-zinc-600 rounded px-2 py-1 bg-white dark:bg-zinc-900"
              value={effectiveLeagueId ?? ""}
              onChange={(e) => setSelectedLeagueId(e.target.value || null)}
            >
              {leagueOptions.map((l) => (
                <option key={l.id} value={l.id}>{l.name}</option>
              ))}
            </select>
            <StandingsTable rows={standings ?? undefined} />
          </>
        ) : (
          <StandingsTable placeholder />
        )}
      </section>
    </div>
  );
}
