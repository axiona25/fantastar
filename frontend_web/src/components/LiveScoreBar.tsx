"use client";

export function LiveScoreBar() {
  return (
    <div className="rounded-lg border border-zinc-200 dark:border-zinc-800 p-2 flex items-center gap-2">
      <span className="h-2 w-2 rounded-full bg-red-500 animate-pulse" aria-hidden />
      <span className="text-sm font-medium">Live</span>
      <span className="text-zinc-500 dark:text-zinc-400 text-sm">(placeholder)</span>
    </div>
  );
}
