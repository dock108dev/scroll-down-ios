"use client";

import { useState } from "react";
import type { GameSummary } from "@/lib/types";
import { SectionHeader } from "@/components/shared/SectionHeader";
import { GameCard } from "./GameCard";

interface GameSectionProps {
  title: string;
  games: GameSummary[];
  defaultExpanded?: boolean;
}

export function GameSection({
  title,
  games,
  defaultExpanded = true,
}: GameSectionProps) {
  const [expanded, setExpanded] = useState(defaultExpanded);

  if (games.length === 0) return null;

  return (
    <div>
      <SectionHeader
        title={title}
        expanded={expanded}
        onToggle={() => setExpanded(!expanded)}
        count={games.length}
      />
      {expanded && (
        <div className="grid grid-cols-2 md:grid-cols-4 xl:grid-cols-5 gap-3 md:gap-2 px-4 pb-4">
          {games.map((game) => (
            <GameCard key={game.id} game={game} />
          ))}
        </div>
      )}
    </div>
  );
}
