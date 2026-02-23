"use client";

import type { PlayEntry } from "@/lib/types";
import { CollapsibleCard } from "@/components/shared/CollapsibleCard";
import { TimelineRow } from "./TimelineRow";

interface TimelineSectionProps {
  plays: PlayEntry[];
  homeTeamAbbr?: string;
  awayTeamAbbr?: string;
}

export function TimelineSection({
  plays,
  homeTeamAbbr,
  awayTeamAbbr,
}: TimelineSectionProps) {
  if (plays.length === 0) {
    return (
      <div className="px-4 py-4 text-sm text-neutral-500">
        No play-by-play data available
      </div>
    );
  }

  // Group plays by periodLabel
  const grouped: Record<string, PlayEntry[]> = {};
  for (const play of plays) {
    const key = play.periodLabel ?? `Period ${play.quarter ?? "?"}`;
    if (!grouped[key]) grouped[key] = [];
    grouped[key].push(play);
  }

  return (
    <div className="px-4 space-y-2">
      {Object.entries(grouped).map(([period, periodPlays]) => (
        <CollapsibleCard key={period} title={period} defaultOpen>
          <div className="space-y-0.5">
            {periodPlays.map((play) => (
              <TimelineRow
                key={play.playIndex}
                play={play}
                homeTeamAbbr={homeTeamAbbr}
                awayTeamAbbr={awayTeamAbbr}
              />
            ))}
          </div>
        </CollapsibleCard>
      ))}
    </div>
  );
}
