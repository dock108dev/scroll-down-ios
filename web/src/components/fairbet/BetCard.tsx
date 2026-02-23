"use client";

import type { APIBet } from "@/lib/types";
import { useSettings } from "@/stores/settings";
import { formatOdds, formatEV } from "@/lib/utils";
import { MiniBookChip } from "./MiniBookChip";
import { cn } from "@/lib/utils";

interface BetCardProps {
  bet: APIBet;
}

export function BetCard({ bet }: BetCardProps) {
  const oddsFormat = useSettings((s) => s.oddsFormat);

  const bestBook = bet.books.reduce(
    (best, b) => ((b.ev_percent ?? 0) > (best.ev_percent ?? 0) ? b : best),
    bet.books[0],
  );

  return (
    <div className="rounded-lg border border-neutral-800 bg-neutral-900 p-3 space-y-2">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="min-w-0">
          <div className="text-xs text-neutral-500 uppercase">
            {bet.league_code} &middot; {bet.away_team} @ {bet.home_team}
          </div>
          <div className="text-sm font-medium text-neutral-200 truncate">
            {bet.bet_description ?? bet.selection_key}
          </div>
        </div>
        {bestBook?.ev_percent != null && bestBook.ev_percent > 0 && (
          <span
            className={cn(
              "shrink-0 ml-2 px-2 py-0.5 rounded text-xs font-bold",
              bestBook.ev_percent >= 5
                ? "bg-green-500/20 text-green-400"
                : "bg-green-500/10 text-green-500",
            )}
          >
            {formatEV(bestBook.ev_percent)}
          </span>
        )}
      </div>

      {/* Line */}
      {bet.line_value != null && (
        <div className="text-xs text-neutral-500">
          Line: {bet.line_value > 0 ? "+" : ""}
          {bet.line_value}
        </div>
      )}

      {/* Book chips */}
      <div className="flex flex-wrap gap-1.5">
        {bet.books.map((book) => (
          <MiniBookChip
            key={book.book}
            book={book.book}
            price={formatOdds(book.price, oddsFormat)}
            ev={book.ev_percent}
            isSharp={book.is_sharp}
          />
        ))}
      </div>
    </div>
  );
}
