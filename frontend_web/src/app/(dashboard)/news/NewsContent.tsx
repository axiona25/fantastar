"use client";

import { useAuth } from "@/hooks/useAuth";
import { useApi } from "@/hooks/useApi";
import { Card, CardContent } from "@/components/ui/card";
import type { NewsItem } from "@/types";
import { useMemo, useState } from "react";

export function NewsContent() {
  useAuth(true);
  const [sourceFilter, setSourceFilter] = useState<string>("");
  const { data: sources } = useApi<string[] | null>("/news/sources");
  const newsPath = useMemo(
    () => (sourceFilter ? `/news?source=${encodeURIComponent(sourceFilter)}` : "/news"),
    [sourceFilter]
  );
  const { data: articles, isLoading, isError } = useApi<NewsItem[] | null>(newsPath);
  const list = articles ?? [];

  return (
    <div className="p-4">
      <h1 className="text-xl font-semibold">News</h1>
      <p className="text-zinc-500 text-sm mt-1">Feed da RSS (calcio italiano)</p>

      {Array.isArray(sources) && sources.length > 0 && (
        <div className="mt-4 flex items-center gap-2">
          <label htmlFor="source-filter" className="text-sm">Filtro fonte:</label>
          <select
            id="source-filter"
            className="border border-zinc-300 dark:border-zinc-600 rounded px-2 py-1 bg-white dark:bg-zinc-900 text-sm"
            value={sourceFilter}
            onChange={(e) => setSourceFilter(e.target.value)}
          >
            <option value="">Tutte</option>
            {sources.map((s) => (
              <option key={s} value={s}>{s}</option>
            ))}
          </select>
        </div>
      )}

      <div className="mt-4 space-y-3">
        {isLoading && <p className="text-zinc-500">Caricamento...</p>}
        {isError && <p className="text-red-600">Errore nel caricamento del feed.</p>}
        {!isLoading && !isError && list.length === 0 && (
          <p className="text-zinc-500">Nessun articolo (avvia sync news sul backend).</p>
        )}
        {list.map((a) => (
          <NewsCard key={a.id} item={a} />
        ))}
      </div>
    </div>
  );
}

function NewsCard({ item }: { item: NewsItem }) {
  return (
    <Card>
      <CardContent className="pt-4">
        <div className="flex gap-3">
          {item.image_url && (
            <a
              href={item.url ?? "#"}
              target="_blank"
              rel="noopener noreferrer"
              className="shrink-0"
            >
              <img
                src={item.image_url}
                alt=""
                className="w-20 h-20 object-cover rounded"
              />
            </a>
          )}
          <div className="min-w-0 flex-1">
            <a
              href={item.url ?? "#"}
              target="_blank"
              rel="noopener noreferrer"
              className="font-medium hover:underline block"
            >
              {item.title}
            </a>
            {item.source && (
              <p className="text-xs text-zinc-500 mt-0.5">{item.source}</p>
            )}
            {item.summary && (() => {
              const plain = item.summary.replace(/<[^>]+>/g, "").slice(0, 200);
              return (
                <p className="text-sm text-zinc-600 dark:text-zinc-400 mt-1 line-clamp-2">
                  {plain}{plain.length >= 200 ? "…" : ""}
                </p>
              );
            })()}
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
