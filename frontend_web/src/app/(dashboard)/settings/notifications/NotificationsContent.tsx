"use client";

import Link from "next/link";
import { useAuth } from "@/hooks/useAuth";
import { useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

const NOTIFICATION_OPTIONS = [
  { id: "goal_my_player", label: "Gol del mio giocatore" },
  { id: "red_card", label: "Cartellino rosso" },
  { id: "match_start_my_players", label: "Inizio partita dei miei giocatori" },
  { id: "fantasy_matchday_result", label: "Risultato finale giornata fantasy" },
] as const;

export function NotificationsContent() {
  useAuth(true);
  const [toggles, setToggles] = useState<Record<string, boolean>>(() =>
    NOTIFICATION_OPTIONS.reduce((acc, o) => ({ ...acc, [o.id]: true }), {})
  );

  const handleToggle = (id: string) => {
    setToggles((prev) => ({ ...prev, [id]: !prev[id] }));
  };

  return (
    <div className="p-4">
      <Link href="/" className="text-sm text-zinc-500 underline mb-4 inline-block">
        ← Dashboard
      </Link>
      <h1 className="text-xl font-semibold">Impostazioni notifiche</h1>
      <p className="text-zinc-500 text-sm mt-1">
        Push notification (placeholder — non collegate al backend)
      </p>
      <Card className="mt-6 max-w-lg">
        <CardHeader>
          <CardTitle className="text-base">Notifiche push</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          {NOTIFICATION_OPTIONS.map((opt) => (
            <label
              key={opt.id}
              className="flex items-center justify-between gap-4 cursor-pointer"
            >
              <span className="text-sm">{opt.label}</span>
              <input
                type="checkbox"
                checked={toggles[opt.id] ?? true}
                onChange={() => handleToggle(opt.id)}
                className="rounded border-zinc-300"
              />
            </label>
          ))}
        </CardContent>
      </Card>
      <p className="text-zinc-500 text-xs mt-4">
        Le preferenze sono solo in memoria; il backend per salvare e inviare push non è incluso in questo task.
      </p>
    </div>
  );
}
