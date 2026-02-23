"use client";

import { use, useRef, useState } from "react";
import { useGame } from "@/hooks/useGame";
import { isFinal, isPregame } from "@/lib/types";
import { GameHeader } from "@/components/game/GameHeader";
import { SectionNav } from "@/components/game/SectionNav";
import { FlowContainer } from "@/components/game/FlowContainer";
import { TimelineSection } from "@/components/game/TimelineSection";
import { StatsSection } from "@/components/game/StatsSection";
import { OddsSection } from "@/components/game/OddsSection";
import { WrapUpSection } from "@/components/game/WrapUpSection";
import { OverviewSection } from "@/components/game/OverviewSection";
import { LoadingSkeleton } from "@/components/shared/LoadingSkeleton";

export default function GameDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = use(params);
  const gameId = Number(id);
  const { data, loading, error } = useGame(gameId);
  const [activeSection, setActiveSection] = useState("Flow");
  const contentRef = useRef<HTMLDivElement>(null);

  if (loading) {
    return (
      <div className="mx-auto max-w-5xl px-4 py-6 space-y-4">
        <LoadingSkeleton className="h-40" />
        <LoadingSkeleton count={3} className="h-24" />
      </div>
    );
  }

  if (error || !data) {
    return (
      <div className="mx-auto max-w-5xl px-4 py-8 text-center text-red-500 text-sm">
        {error ?? "Game not found"}
      </div>
    );
  }

  const game = data.game;
  const final = isFinal(game.status);
  const pregame = isPregame(game.status);

  const sections = pregame
    ? ["Overview", "Odds"]
    : final
      ? ["Flow", "Timeline", "Stats", "Odds", "Wrap-Up"]
      : ["Timeline", "Stats", "Odds"];

  return (
    <div className="mx-auto max-w-5xl">
      <GameHeader game={game} />

      <SectionNav
        sections={sections}
        active={activeSection}
        onSelect={setActiveSection}
      />

      <div ref={contentRef} className="py-4 space-y-6">
        {activeSection === "Overview" && <OverviewSection data={data} />}

        {activeSection === "Flow" && <FlowContainer gameId={gameId} />}

        {activeSection === "Timeline" && (
          <TimelineSection
            plays={data.plays}
            homeTeamAbbr={game.homeTeamAbbr}
            awayTeamAbbr={game.awayTeamAbbr}
          />
        )}

        {activeSection === "Stats" && (
          <StatsSection
            playerStats={data.playerStats}
            teamStats={data.teamStats}
            homeTeam={game.homeTeam}
            awayTeam={game.awayTeam}
          />
        )}

        {activeSection === "Odds" && <OddsSection odds={data.odds} />}

        {activeSection === "Wrap-Up" && <WrapUpSection data={data} />}
      </div>
    </div>
  );
}
