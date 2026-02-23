"use client";

import { useMemo, useState } from "react";
import { useGames } from "@/hooks/useGames";
import { LeagueFilter } from "@/components/home/LeagueFilter";
import { SearchBar } from "@/components/home/SearchBar";
import { GameSection } from "@/components/home/GameSection";
import { LoadingSkeleton } from "@/components/shared/LoadingSkeleton";
import { classifyDateSection } from "@/lib/utils";

const SECTION_ORDER = ["Earlier", "Yesterday", "Today", "Tomorrow", "Upcoming"];

export default function HomePage() {
  const [league, setLeague] = useState("");
  const [search, setSearch] = useState("");
  const { games, loading, error } = useGames({ league, search });

  const sections = useMemo(() => {
    const grouped: Record<string, typeof games> = {};
    for (const game of games) {
      const section = classifyDateSection(game.gameDate);
      if (!grouped[section]) grouped[section] = [];
      grouped[section].push(game);
    }
    return SECTION_ORDER.filter((s) => grouped[s]?.length).map((s) => ({
      title: s,
      games: grouped[s],
    }));
  }, [games]);

  return (
    <div className="mx-auto max-w-7xl">
      <div className="sticky top-14 z-30 bg-neutral-950 px-4 py-3 space-y-3 border-b border-neutral-800">
        <SearchBar value={search} onChange={setSearch} />
        <LeagueFilter selected={league} onChange={setLeague} />
      </div>

      {loading && (
        <div className="px-4 py-4 space-y-3">
          <LoadingSkeleton count={8} className="h-24" />
        </div>
      )}

      {error && (
        <div className="px-4 py-8 text-center text-red-500 text-sm">
          {error}
        </div>
      )}

      {!loading && !error && sections.length === 0 && (
        <div className="px-4 py-8 text-center text-neutral-500 text-sm">
          No games found
        </div>
      )}

      {sections.map((section) => (
        <GameSection
          key={section.title}
          title={section.title}
          games={section.games}
          defaultExpanded={section.title === "Today" || section.title === "Yesterday"}
        />
      ))}
    </div>
  );
}
