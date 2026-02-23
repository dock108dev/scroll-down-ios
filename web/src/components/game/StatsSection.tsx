"use client";

import type { PlayerStat, TeamStat } from "@/lib/types";
import { PlayerStatsTable } from "./PlayerStatsTable";
import { TeamStatsComparison } from "./TeamStatsComparison";

interface StatsSectionProps {
  playerStats: PlayerStat[];
  teamStats: TeamStat[];
  homeTeam: string;
  awayTeam: string;
}

export function StatsSection({
  playerStats,
  teamStats,
  homeTeam,
  awayTeam,
}: StatsSectionProps) {
  if (playerStats.length === 0 && teamStats.length === 0) {
    return (
      <div className="px-4 py-4 text-sm text-neutral-500">
        No stats available
      </div>
    );
  }

  return (
    <div className="px-4 space-y-4">
      {teamStats.length > 0 && (
        <TeamStatsComparison
          teamStats={teamStats}
          homeTeam={homeTeam}
          awayTeam={awayTeam}
        />
      )}

      {playerStats.length > 0 && (
        <div className="grid grid-cols-1 xl:grid-cols-2 gap-4">
          <PlayerStatsTable
            title={awayTeam}
            players={playerStats.filter((p) => p.team !== homeTeam)}
          />
          <PlayerStatsTable
            title={homeTeam}
            players={playerStats.filter((p) => p.team === homeTeam)}
          />
        </div>
      )}
    </div>
  );
}
