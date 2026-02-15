"use client";

import type { StandingRow } from "@/types";

interface StandingsTableProps {
  rows?: StandingRow[];
  placeholder?: boolean;
}

export function StandingsTable({ rows, placeholder }: StandingsTableProps) {
  if (placeholder || !rows?.length) {
    return (
      <div className="rounded-lg border border-zinc-200 dark:border-zinc-800 p-4">
        <p className="text-zinc-500 dark:text-zinc-400">Tabella classifica (placeholder)</p>
      </div>
    );
  }
  return (
    <div className="overflow-x-auto rounded-lg border border-zinc-200 dark:border-zinc-800">
      <table className="w-full text-sm">
        <thead>
          <tr className="border-b border-zinc-200 dark:border-zinc-700">
            <th className="p-2 text-left">#</th>
            <th className="p-2 text-left">Squadra</th>
            <th className="p-2 text-right">Pt</th>
            <th className="p-2 text-right">V</th>
            <th className="p-2 text-right">P</th>
          </tr>
        </thead>
        <tbody>
          {rows.map((r) => (
            <tr key={r.fantasy_team_id} className="border-b border-zinc-100 dark:border-zinc-800">
              <td className="p-2">{r.rank}</td>
              <td className="p-2">{r.team_name}</td>
              <td className="p-2 text-right">{r.total_points}</td>
              <td className="p-2 text-right">{r.wins}</td>
              <td className="p-2 text-right">{r.losses}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
