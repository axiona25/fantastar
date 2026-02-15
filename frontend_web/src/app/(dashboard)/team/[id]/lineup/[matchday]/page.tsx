"use client";

import { use } from "react";
import Link from "next/link";
import { useAuth } from "@/hooks/useAuth";
import { useApi } from "@/hooks/useApi";
import { FormationField } from "@/components/FormationField";
import type { LineupResponse } from "@/types";

const VALID_FORMATIONS = ["3-4-3", "3-5-2", "4-3-3", "4-4-2", "4-5-1", "5-3-2", "5-4-1"];

export default function LineupPage({
  params,
}: {
  params: Promise<{ id: string; matchday: string }>;
}) {
  const { id, matchday } = use(params);
  useAuth(true);
  const { data: lineup, isLoading, isError } = useApi<LineupResponse | null>(
    `/teams/${id}/lineup/${matchday}`
  );

  if (isLoading) return <p className="text-zinc-500 p-4">Caricamento...</p>;
  if (isError) return <p className="text-red-600 p-4">Errore nel caricamento formazione.</p>;

  const formation = lineup?.formation ?? "4-3-3";

  return (
    <div className="p-4">
      <Link href={`/team/${id}`} className="text-sm text-zinc-500 underline mb-4 inline-block">
        ← Squadra
      </Link>
      <h1 className="text-xl font-semibold">Formazione — Giornata {matchday}</h1>
      <p className="text-zinc-500 text-sm mt-1">
        Modulo: {formation}
        {lineup?.starters?.length ? ` (${lineup.starters.length} titolari)` : ""}
      </p>
      <div className="mt-6">
        <FormationField />
      </div>
      <div className="mt-4 flex gap-2 items-center">
        <select
          className="border border-zinc-300 dark:border-zinc-600 rounded px-2 py-1 bg-white dark:bg-zinc-900"
          defaultValue={formation}
          aria-label="Modulo"
        >
          {VALID_FORMATIONS.map((f) => (
            <option key={f} value={f}>{f}</option>
          ))}
        </select>
        <button
          type="button"
          className="rounded bg-zinc-800 text-white px-3 py-1 text-sm"
        >
          Salva (placeholder)
        </button>
      </div>
    </div>
  );
}
