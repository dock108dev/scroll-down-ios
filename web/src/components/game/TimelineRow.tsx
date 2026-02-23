import type { PlayEntry } from "@/lib/types";
import { cn } from "@/lib/utils";

interface TimelineRowProps {
  play: PlayEntry;
  homeTeamAbbr?: string;
  awayTeamAbbr?: string;
}

export function TimelineRow({ play }: TimelineRowProps) {
  const tier = play.tier ?? 3;

  return (
    <div
      className={cn(
        "flex items-start gap-3 py-1.5 px-2 rounded",
        tier === 1 && "bg-neutral-800/40",
        tier === 2 && "bg-neutral-800/20",
      )}
    >
      <span className="shrink-0 w-12 text-right text-xs text-neutral-500 font-mono">
        {play.timeLabel ?? play.gameClock ?? ""}
      </span>

      <div className="flex-1 min-w-0">
        <p
          className={cn(
            "text-sm leading-snug",
            tier === 1 && "font-semibold text-white",
            tier === 2 && "text-neutral-300",
            tier === 3 && "text-neutral-500 text-xs",
          )}
        >
          {play.description ?? ""}
        </p>
      </div>

      <span className="shrink-0 text-xs text-neutral-500 font-mono tabular-nums">
        {play.awayScore != null && play.homeScore != null
          ? `${play.awayScore}-${play.homeScore}`
          : ""}
      </span>
    </div>
  );
}
