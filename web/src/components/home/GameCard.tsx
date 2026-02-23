"use client";

import Link from "next/link";
import type { GameSummary } from "@/lib/types";
import { isLive, isFinal } from "@/lib/types";
import { useReadState } from "@/stores/read-state";
import { useSettings } from "@/stores/settings";
import { TeamColorDot } from "@/components/shared/TeamColorDot";
import { cn } from "@/lib/utils";

interface GameCardProps {
  game: GameSummary;
}

export function GameCard({ game }: GameCardProps) {
  const { isRead, markRead } = useReadState();
  const scoreRevealMode = useSettings((s) => s.scoreRevealMode);

  const read = isRead(game.id);
  const showScore =
    scoreRevealMode === "always" || read || isLive(game.status);
  const final = isFinal(game.status);
  const live = isLive(game.status);

  const handleReveal = (e: React.MouseEvent) => {
    if (!showScore && final) {
      e.preventDefault();
      markRead(game.id, game.status);
    }
  };

  return (
    <Link
      href={`/game/${game.id}`}
      className="block rounded-lg border border-neutral-800 bg-neutral-900 p-3 hover:border-neutral-700 transition"
    >
      <div className="flex items-center justify-between text-xs text-neutral-500 mb-2">
        <span className="uppercase font-medium">{game.leagueCode}</span>
        {live && (
          <span className="text-green-400 font-medium animate-pulse">
            LIVE
          </span>
        )}
        {final && !read && (
          <span className="text-yellow-500 text-[10px]">NEW</span>
        )}
      </div>

      <div className="space-y-1.5">
        {/* Away team */}
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2 min-w-0">
            <TeamColorDot color={game.awayTeamColorDark} />
            <span className="text-sm truncate">
              {game.awayTeamAbbr ?? game.awayTeam}
            </span>
          </div>
          <span
            onClick={handleReveal}
            className={cn(
              "text-sm font-mono tabular-nums",
              !showScore && "blur-md cursor-pointer select-none",
            )}
          >
            {game.awayScore ?? "-"}
          </span>
        </div>

        {/* Home team */}
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2 min-w-0">
            <TeamColorDot color={game.homeTeamColorDark} />
            <span className="text-sm truncate">
              {game.homeTeamAbbr ?? game.homeTeam}
            </span>
          </div>
          <span
            onClick={handleReveal}
            className={cn(
              "text-sm font-mono tabular-nums",
              !showScore && "blur-md cursor-pointer select-none",
            )}
          >
            {game.homeScore ?? "-"}
          </span>
        </div>
      </div>

      {live && game.gameClock && (
        <div className="mt-2 text-xs text-neutral-500 text-center">
          {game.currentPeriod && `Q${game.currentPeriod} `}
          {game.gameClock}
        </div>
      )}
    </Link>
  );
}
