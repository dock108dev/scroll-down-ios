"use client";

import { useState } from "react";
import type { Game } from "@/lib/types";
import { isLive, isFinal, isPregame } from "@/lib/types";
import { useReadState } from "@/stores/read-state";
import { useSettings } from "@/stores/settings";
import { TeamColorDot } from "@/components/shared/TeamColorDot";
import { formatDate } from "@/lib/utils";
import { cn } from "@/lib/utils";

interface GameHeaderProps {
  game: Game;
}

export function GameHeader({ game }: GameHeaderProps) {
  const { isRead, markRead, markUnread } = useReadState();
  const scoreRevealMode = useSettings((s) => s.scoreRevealMode);
  // Temporary reveal for live games (not persisted as "read")
  const [tempRevealed, setTempRevealed] = useState(false);

  const read = isRead(game.id);
  const live = isLive(game.status);
  const final = isFinal(game.status);
  const pregame = isPregame(game.status);

  const hasScoreData = game.homeScore != null && game.awayScore != null;

  // Score visibility follows iOS logic:
  // - "always" mode: show if data exists
  // - "onMarkRead" mode: show only if read or temp revealed
  // - Pregame: never
  // - Live: hidden until user clicks (temp reveal)
  const showScore =
    !pregame &&
    hasScoreData &&
    (scoreRevealMode === "always" || read || tempRevealed);

  const handleScoreClick = () => {
    if (showScore) return;
    if (!hasScoreData) return;

    if (final) {
      // Final: permanent reveal (marks as read)
      markRead(game.id, game.status);
    } else if (live) {
      // Live: temporary reveal
      setTempRevealed(true);
    }
  };

  return (
    <div className="px-4 py-6">
      {/* League code + date + status badge row */}
      <div className="flex items-center justify-between mb-4">
        <span className="text-xs uppercase font-medium text-neutral-500 tracking-wide">
          {game.leagueCode.toUpperCase()} &middot; {formatDate(game.gameDate)}
        </span>
        {live && (
          <span className="inline-flex items-center gap-1.5 text-xs font-semibold text-green-400">
            <span className="relative flex h-2 w-2">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75" />
              <span className="relative inline-flex rounded-full h-2 w-2 bg-green-400" />
            </span>
            LIVE
          </span>
        )}
        {final && (
          <span className="text-xs text-neutral-500 uppercase font-medium">
            Final
          </span>
        )}
        {pregame && (
          <span className="text-xs text-neutral-500 uppercase font-medium">
            Upcoming
          </span>
        )}
      </div>

      {/* Away (left) @ Home (right) */}
      <div className="flex items-center justify-between gap-4">
        {/* Away team */}
        <div className="flex-1 text-center">
          <div className="flex justify-center mb-1">
            <TeamColorDot color={game.awayTeamColorDark} size="md" />
          </div>
          <div className="text-lg font-semibold text-neutral-100">
            {game.awayTeamAbbr ?? game.awayTeam}
          </div>
          {showScore ? (
            <div className="text-3xl font-bold font-mono tabular-nums mt-1">
              {game.awayScore}
            </div>
          ) : (
            /* Empty space or "vs" shown in center instead */
            <div className="text-3xl font-bold font-mono tabular-nums mt-1 text-neutral-800">
              &nbsp;
            </div>
          )}
        </div>

        {/* Center: @ or vs */}
        {showScore ? (
          <span className="text-neutral-600 text-sm font-medium">@</span>
        ) : (
          <div className="text-center">
            <span
              onClick={handleScoreClick}
              className={cn(
                "text-2xl font-bold text-neutral-600",
                !pregame && hasScoreData && "cursor-pointer hover:text-neutral-400 transition-colors",
              )}
            >
              vs
            </span>
            {/* Hint text */}
            {!pregame && hasScoreData && (
              <p className="text-[10px] text-neutral-700 mt-1">
                {live ? "Click to check" : "Click to reveal"}
              </p>
            )}
          </div>
        )}

        {/* Home team */}
        <div className="flex-1 text-center">
          <div className="flex justify-center mb-1">
            <TeamColorDot color={game.homeTeamColorDark} size="md" />
          </div>
          <div className="text-lg font-semibold text-neutral-100">
            {game.homeTeamAbbr ?? game.homeTeam}
          </div>
          {showScore ? (
            <div className="text-3xl font-bold font-mono tabular-nums mt-1">
              {game.homeScore}
            </div>
          ) : (
            <div className="text-3xl font-bold font-mono tabular-nums mt-1 text-neutral-800">
              &nbsp;
            </div>
          )}
        </div>
      </div>

      {/* Live update hint */}
      {live && showScore && (
        <p
          onClick={() => setTempRevealed(true)}
          className="mt-2 text-center text-[11px] text-neutral-600 cursor-pointer hover:text-neutral-400"
        >
          Click to update score
        </p>
      )}

      {/* Mark as Read / Unread toggle */}
      {final && (
        <div className="mt-4 text-center">
          <button
            onClick={() =>
              read
                ? markUnread(game.id)
                : markRead(game.id, game.status)
            }
            className="text-xs text-neutral-400 hover:text-white border border-neutral-700 rounded-full px-4 py-1.5 transition-colors"
          >
            {read ? "Mark as Unread" : "Mark as Read"}
          </button>
        </div>
      )}
    </div>
  );
}
