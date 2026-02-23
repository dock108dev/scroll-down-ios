import type { TeamStat } from "@/lib/types";

interface TeamStatsComparisonProps {
  teamStats: TeamStat[];
  homeTeam: string;
  awayTeam: string;
}

export function TeamStatsComparison({
  teamStats,
  homeTeam,
  awayTeam,
}: TeamStatsComparisonProps) {
  const home = teamStats.find((t) => t.isHome);
  const away = teamStats.find((t) => !t.isHome);

  if (!home || !away) return null;

  // Get all stat keys that exist in either team
  const statKeys = Array.from(
    new Set([...Object.keys(home.stats), ...Object.keys(away.stats)]),
  );

  return (
    <div className="rounded-lg border border-neutral-800 bg-neutral-900 overflow-hidden">
      <div className="grid grid-cols-3 px-3 py-2 text-xs font-semibold border-b border-neutral-800 bg-neutral-800/50">
        <span className="text-neutral-300">{awayTeam}</span>
        <span className="text-center text-neutral-500">Stat</span>
        <span className="text-right text-neutral-300">{homeTeam}</span>
      </div>
      {statKeys.map((key) => (
        <div
          key={key}
          className="grid grid-cols-3 px-3 py-1.5 text-xs border-b border-neutral-800/50"
        >
          <span className="text-neutral-300 font-mono">
            {String(away.stats[key] ?? "-")}
          </span>
          <span className="text-center text-neutral-500 capitalize">
            {key.replace(/_/g, " ")}
          </span>
          <span className="text-right text-neutral-300 font-mono">
            {String(home.stats[key] ?? "-")}
          </span>
        </div>
      ))}
    </div>
  );
}
