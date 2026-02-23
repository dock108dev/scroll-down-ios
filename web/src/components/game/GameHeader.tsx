"use client";

import type { Game } from "@/lib/types";
import { isLive, isFinal } from "@/lib/types";
import { useReadState } from "@/stores/read-state";
import { useSettings } from "@/stores/settings";
import { TeamColorDot } from "@/components/shared/TeamColorDot";
import { cn } from "@/lib/utils";

interface GameHeaderProps {
  game: Game;
}

export function GameHeader({ game }: GameHeaderProps) {
  const { isRead, markRead, markUnread } = useReadState();
  const scoreRevealMode = useSettings((s) => s.scoreRevealMode);

  const read = isRead(game.id);
  const showScore =
    scoreRevealMode === "always" || read || isLive(game.status);
  const final = isFinal(game.status);

  return (
    <div className="px-4 py-6">
      <div className="flex items-center justify-between mb-4">
        <span className="text-xs uppercase font-medium text-neutral-500">
          {game.leagueCode} &middot; {game.gameDate}
        </span>
        {isLive(game.status) && (
          <span className="text-xs text-green-400 font-medium animate-pulse">
            LIVE
          </span>
        )}
        {final && (
          <span className="text-xs text-neutral-500 uppercase">Final</span>
        )}
      </div>

      <div className="flex items-center justify-between gap-4">
        {/* Away */}
        <div className="flex-1 text-center">
          <TeamColorDot color={game.awayTeamColorDark} size="md" />
          <div className="text-lg font-semibold mt-1">
            {game.awayTeamAbbr ?? game.awayTeam}
          </div>
          <div
            className={cn(
              "text-3xl font-bold font-mono tabular-nums mt-1",
              !showScore && "blur-lg select-none",
            )}
          >
            {game.awayScore ?? "-"}
          </div>
        </div>

        <span className="text-neutral-600 text-sm">@</span>

        {/* Home */}
        <div className="flex-1 text-center">
          <TeamColorDot color={game.homeTeamColorDark} size="md" />
          <div className="text-lg font-semibold mt-1">
            {game.homeTeamAbbr ?? game.homeTeam}
          </div>
          <div
            className={cn(
              "text-3xl font-bold font-mono tabular-nums mt-1",
              !showScore && "blur-lg select-none",
            )}
          >
            {game.homeScore ?? "-"}
          </div>
        </div>
      </div>

      {/* Mark as Read / Unread toggle */}
      {final && (
        <div className="mt-4 text-center">
          <button
            onClick={() =>
              read
                ? markUnread(game.id)
                : markRead(game.id, game.status)
            }
            className="text-xs text-neutral-400 hover:text-white border border-neutral-700 rounded-full px-4 py-1.5 transition"
          >
            {read ? "Mark as Unread" : "Mark as Read"}
          </button>
        </div>
      )}
    </div>
  );
}
