"use client";

import { useRouter } from "next/navigation";
import type { GameSummary } from "@/lib/types";
import { isLive, isFinal, isPregame } from "@/lib/types";
import { useReadState } from "@/stores/read-state";
import { useSettings } from "@/stores/settings";
import { TeamColorDot } from "@/components/shared/TeamColorDot";
import { cn } from "@/lib/utils";
import { useRef, useState } from "react";
import { useReadingPosition } from "@/stores/reading-position";

interface GameCardProps {
  game: GameSummary;
}

/** Returns true when a game has no meaningful data at all. */
function hasNoData(game: GameSummary): boolean {
  return !game.hasOdds && !game.hasPbp && !game.hasSocial && !game.hasFlow;
}

/** Format a game date for display on card. E.g. "Feb 23 • 7:10 PM" */
function formatGameDateTime(dateStr: string): string {
  const date = new Date(dateStr);
  const month = date.toLocaleString("en-US", {
    month: "short",
    timeZone: "America/New_York",
  });
  const day = date.toLocaleString("en-US", {
    day: "numeric",
    timeZone: "America/New_York",
  });
  const time = date.toLocaleString("en-US", {
    hour: "numeric",
    minute: "2-digit",
    timeZone: "America/New_York",
  });
  return `${month} ${day} • ${time}`;
}

/** Get period label based on league */
function getPeriodLabel(game: GameSummary): string {
  const league = game.leagueCode?.toLowerCase();
  const period = game.currentPeriod;
  if (!period) return "";
  if (league === "nhl") return `P${period}`;
  if (league === "nfl" || league === "ncaaf") return `Q${period}`;
  if (league === "mlb") return period <= 9 ? `${period}` : `E${period - 9}`;
  return `Q${period}`;
}

export function GameCard({ game }: GameCardProps) {
  const router = useRouter();
  const { isRead, markRead, markUnread } = useReadState();
  const scoreRevealMode = useSettings((s) => s.scoreRevealMode);
  const [tempRevealed, setTempRevealed] = useState(false);
  const savedPosition = useReadingPosition((s) => s.getPosition)(game.id);

  const read = isRead(game.id);
  const final = isFinal(game.status);
  const live = isLive(game.status);
  const pregame = isPregame(game.status);
  const noData = hasNoData(game);

  const hasScoreData = game.homeScore != null && game.awayScore != null;

  const showScore =
    !pregame &&
    hasScoreData &&
    (scoreRevealMode === "always" || read || tempRevealed);

  const displayAwayScore = showScore
    ? game.awayScore
    : savedPosition?.awayScore != null && !pregame
      ? savedPosition.awayScore
      : null;
  const displayHomeScore = showScore
    ? game.homeScore
    : savedPosition?.homeScore != null && !pregame
      ? savedPosition.homeScore
      : null;
  const hasSavedScores = displayAwayScore != null && displayHomeScore != null;

  const cardRef = useRef<HTMLDivElement>(null);

  const handleCardClick = () => {
    if (!noData) {
      router.push(`/game/${game.id}`);
    }
  };

  return (
    <div
      ref={cardRef}
      onClick={handleCardClick}
      className={cn(
        "relative rounded-lg border border-neutral-800 bg-neutral-900 p-3 transition select-none",
        noData && "opacity-40 pointer-events-none",
        !noData && "cursor-pointer hover:border-neutral-700",
        read && final && "border-neutral-800/60",
      )}
    >
      {/* Top bar: league badge + status */}
      <div className="flex items-center justify-between text-xs mb-2">
        <span className="uppercase font-medium text-neutral-500">
          {game.leagueCode}
        </span>
        <div className="flex items-center gap-2">
          {live && (
            <span className="inline-flex items-center gap-1 text-green-400 font-semibold">
              <span className="relative flex h-1.5 w-1.5">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75" />
                <span className="relative inline-flex rounded-full h-1.5 w-1.5 bg-green-400" />
              </span>
              LIVE
            </span>
          )}
          {final && !read && (
            <span className="text-yellow-500 text-[10px] font-medium">NEW</span>
          )}
          {final && read && (
            <span className="text-neutral-600">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                <polyline points="20 6 9 17 4 12" />
              </svg>
            </span>
          )}
        </div>
      </div>

      {/* Teams + Scores */}
      <div className="space-y-1.5">
        {/* Away team */}
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2 min-w-0">
            <TeamColorDot color={game.awayTeamColorDark} />
            <span className="text-sm truncate">
              {game.awayTeamAbbr ?? game.awayTeam}
            </span>
          </div>
          {pregame ? (
            <span />
          ) : showScore || hasSavedScores ? (
            <span className="text-sm font-mono tabular-nums">
              {displayAwayScore}
            </span>
          ) : hasScoreData ? (
            <span className="text-sm font-mono tabular-nums blur-sm select-none">
              {game.awayScore}
            </span>
          ) : (
            <span />
          )}
        </div>

        {/* Home team */}
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2 min-w-0">
            <TeamColorDot color={game.homeTeamColorDark} />
            <span className="text-sm truncate">
              {game.homeTeamAbbr ?? game.homeTeam}
            </span>
          </div>
          {pregame ? (
            <span />
          ) : showScore || hasSavedScores ? (
            <span className="text-sm font-mono tabular-nums">
              {displayHomeScore}
            </span>
          ) : hasScoreData ? (
            <span className="text-sm font-mono tabular-nums blur-sm select-none">
              {game.homeScore}
            </span>
          ) : (
            <span />
          )}
        </div>
      </div>

      {/* Game clock for live games */}
      {live && showScore && (game.currentPeriod || game.gameClock) && (
        <div className="mt-1 text-[10px] text-neutral-500 text-center">
          @ {getPeriodLabel(game)}{game.gameClock ? ` ${game.gameClock}` : ""}
        </div>
      )}

      {/* Bottom info */}
      <div className="mt-2 flex items-center text-[11px] text-neutral-500">
        <div className="flex-1" />
        <div className="flex-1 text-center">
          {pregame && (
            <span>{formatGameDateTime(game.gameDate)}</span>
          )}
          {live && showScore && (
            <span>
              {getPeriodLabel(game)}
              {game.gameClock ? ` ${game.gameClock}` : ""}
            </span>
          )}
          {live && !showScore && hasSavedScores && savedPosition?.timeLabel && (
            <span>@ {savedPosition.timeLabel}</span>
          )}
          {final && showScore && (
            <span className="text-neutral-600">Final</span>
          )}
        </div>
        <div className="flex-1 text-right">
          {final && !read && (
            <button
              onClick={(e) => { e.stopPropagation(); markRead(game.id, game.status); }}
              className="text-[10px] text-neutral-600 hover:text-neutral-400 transition"
            >
              Reveal
            </button>
          )}
          {final && read && (
            <button
              onClick={(e) => { e.stopPropagation(); markUnread(game.id); }}
              className="text-[10px] text-neutral-600 hover:text-neutral-400 transition"
            >
              Hide
            </button>
          )}
          {live && !tempRevealed && (
            <button
              onClick={(e) => { e.stopPropagation(); setTempRevealed(true); }}
              className="text-[10px] text-neutral-600 hover:text-neutral-400 transition"
            >
              Reveal
            </button>
          )}
          {live && tempRevealed && (
            <button
              onClick={(e) => { e.stopPropagation(); setTempRevealed(false); }}
              className="text-[10px] text-neutral-600 hover:text-neutral-400 transition"
            >
              Hide
            </button>
          )}
        </div>
      </div>
    </div>
  );
}
