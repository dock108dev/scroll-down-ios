"use client";

import { useState } from "react";
import type { Game } from "@/lib/types";
import { isLive, isFinal, isPregame } from "@/lib/types";
import { useReadState } from "@/stores/read-state";
import { useSettings } from "@/stores/settings";
import { formatDate } from "@/lib/utils";
import { cn } from "@/lib/utils";

interface GameHeaderProps {
  game: Game;
}

function getPeriodLabel(game: Game): string {
  const league = game.leagueCode?.toLowerCase();
  const period = game.currentPeriod;
  if (!period) return "";
  if (league === "nhl") return `P${period}`;
  if (league === "nfl" || league === "ncaaf") return `Q${period}`;
  if (league === "mlb") return period <= 9 ? `${period}` : `E${period - 9}`;
  return `Q${period}`;
}

export function GameHeader({ game }: GameHeaderProps) {
  const { isRead, markRead, markUnread } = useReadState();
  const scoreRevealMode = useSettings((s) => s.scoreRevealMode);
  const [tempRevealed, setTempRevealed] = useState(false);

  const read = isRead(game.id);
  const live = isLive(game.status);
  const final = isFinal(game.status);
  const pregame = isPregame(game.status);

  const hasScoreData = game.homeScore != null && game.awayScore != null;

  const showScore =
    !pregame &&
    hasScoreData &&
    (scoreRevealMode === "always" || read || tempRevealed);

  const handleScoreToggle = () => {
    if (!hasScoreData) return;
    if (final) {
      if (read) markUnread(game.id);
      else markRead(game.id, game.status);
    } else if (live) {
      setTempRevealed((prev) => !prev);
    }
  };

  const awayColor = game.awayTeamColorDark || "#888";
  const homeColor = game.homeTeamColorDark || "#888";

  return (
    <div className="px-4 py-6">
      {/* League + date + status */}
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
          <span className="text-xs text-neutral-500 uppercase font-medium">Final</span>
        )}
        {pregame && (
          <span className="text-xs text-neutral-500 uppercase font-medium">Upcoming</span>
        )}
      </div>

      {/* Away (left) @ Home (right) — team colors as text */}
      <div className="flex items-center justify-between gap-4">
        {/* Away team */}
        <div className="flex-1 text-center">
          <div
            className="text-2xl font-bold"
            style={{ color: awayColor }}
          >
            {game.awayTeamAbbr ?? game.awayTeam}
          </div>
          {showScore ? (
            <div className="text-3xl font-bold font-mono tabular-nums mt-1">
              {game.awayScore}
            </div>
          ) : (
            <div className="text-3xl font-bold font-mono tabular-nums mt-1 text-neutral-800">
              &nbsp;
            </div>
          )}
        </div>

        {/* Center: toggle reveal */}
        <div
          onClick={handleScoreToggle}
          className={cn(
            "text-center shrink-0",
            !pregame && hasScoreData && "cursor-pointer",
          )}
        >
          {showScore ? (
            <>
              <span className="text-neutral-600 text-sm font-medium">@</span>
              {live && (game.currentPeriod || game.gameClock) && (
                <p className="text-[11px] text-neutral-500 mt-0.5">
                  {getPeriodLabel(game)}{game.gameClock ? ` ${game.gameClock}` : ""}
                </p>
              )}
              {scoreRevealMode !== "always" && (
                <p className="text-[10px] text-neutral-700 mt-1 hover:text-neutral-500 transition-colors">
                  Hide score
                </p>
              )}
            </>
          ) : (
            <>
              <span
                className={cn(
                  "text-2xl font-bold text-neutral-600",
                  !pregame && hasScoreData && "hover:text-neutral-400 transition-colors",
                )}
              >
                vs
              </span>
              {!pregame && hasScoreData && (
                <p className="text-[10px] text-neutral-700 mt-1">
                  {live ? "Click to update" : "Click to reveal"}
                </p>
              )}
            </>
          )}
        </div>

        {/* Home team */}
        <div className="flex-1 text-center">
          <div
            className="text-2xl font-bold"
            style={{ color: homeColor }}
          >
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
    </div>
  );
}
