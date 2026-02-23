"use client";

import { useState } from "react";
import type { OddsEntry } from "@/lib/types";
import { OddsTable } from "./OddsTable";
import { cn } from "@/lib/utils";

interface OddsSectionProps {
  odds: OddsEntry[];
}

const CATEGORY_LABELS: Record<string, string> = {
  mainline: "Game Lines",
  player_prop: "Player Props",
  team_prop: "Team Props",
  alternate: "Alternates",
};

export function OddsSection({ odds }: OddsSectionProps) {
  const categories = Array.from(
    new Set(odds.map((o) => o.marketCategory ?? "mainline")),
  );
  const [activeCategory, setActiveCategory] = useState<string>(
    categories[0] ?? "mainline",
  );

  if (odds.length === 0) {
    return (
      <div className="px-4 py-4 text-sm text-neutral-500">
        No odds data available
      </div>
    );
  }

  const filtered = odds.filter(
    (o) => (o.marketCategory ?? "mainline") === activeCategory,
  );

  return (
    <div className="px-4 space-y-3">
      {categories.length > 1 && (
        <div className="flex gap-2 overflow-x-auto scrollbar-none">
          {categories.map((cat) => (
            <button
              key={cat}
              onClick={() => setActiveCategory(cat)}
              className={cn(
                "shrink-0 rounded-full px-3 py-1 text-xs font-medium transition",
                activeCategory === cat
                  ? "bg-white text-black"
                  : "bg-neutral-800 text-neutral-400 hover:text-white",
              )}
            >
              {CATEGORY_LABELS[cat] ?? cat}
            </button>
          ))}
        </div>
      )}
      <OddsTable odds={filtered} />
    </div>
  );
}
