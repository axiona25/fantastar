"use client";

import Link from "next/link";
import { useAuth } from "@/hooks/useAuth";
import { useApi } from "@/hooks/useApi";
import { LiveScoreBar } from "@/components/LiveScoreBar";
import { MatchCard } from "@/components/MatchCard";
import type { MatchListItem } from "@/types";

export function LiveContent() {
  useAuth(true);
  const { data: matches, isLoading, isError } = useApi<MatchListItem[] | null>(
    "/matches?status=IN_PLAY"
  );
  const list = matches ?? [];

  return (
    <div className="p-4">
      <h1 className="text-xl font-semibold">Live</h1>
      <div className="mt-4">
        <LiveScoreBar />
      </div>
      <h2 className="text-lg font-medium mt-6 mb-2">Partite in corso</h2>
      {isLoading && <p className="text-zinc-500">Caricamento...</p>}
      {isError && <p className="text-red-600">Errore nel caricamento delle partite.</p>}
      {!isLoading && !isError && list.length === 0 && (
        <p className="text-zinc-500">Nessuna partita in corso.</p>
      )}
      {list.length > 0 && (
        <ul className="space-y-3">
          {list.map((m) => (
            <li key={m.id}>
              <Link href={`/match/${m.id}`} className="block hover:opacity-80">
                <MatchCard match={m} />
              </Link>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
