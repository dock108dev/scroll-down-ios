"use client";

import { useRouter } from "next/navigation";
import type { GameSummary } from "@/lib/types";
import { isLive, isFinal, isPregame } from "@/lib/types";
import { useReadState } from "@/stores/read-state";
import { useSettings } from "@/stores/settings";
import { TeamColorDot } from "@/components/shared/TeamColorDot";
import { cn } from "@/lib/utils";
import { useCallback, useRef, useState } from "react";
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
  // Temporary reveal state for live games (not persisted as "read")
  const [tempRevealed, setTempRevealed] = useState(false);
  const savedPosition = useReadingPosition((s) => s.getPosition)(game.id);

  const read = isRead(game.id);
  const final = isFinal(game.status);
  const live = isLive(game.status);
  const pregame = isPregame(game.status);
  const noData = hasNoData(game);

  // Has actual score data from API
  const hasScoreData = game.homeScore != null && game.awayScore != null;

  // Score visibility follows iOS logic exactly:
  // - "always" mode: show if score data exists (any state)
  // - "onMarkRead" mode: show only if game is marked read, OR temporarily revealed
  // - Pregame: never (no scores exist)
  // - Live games in onMarkRead: hidden until long-press to temp-reveal
  const showScore =
    !pregame &&
    hasScoreData &&
    (scoreRevealMode === "always" || read || tempRevealed);

  // For live games with saved reading position, show cached scores
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

  // ── Long-press to toggle score reveal ─────────────────────────
  // Final games: long-press toggles read/unread (persisted)
  // Live games: long-press toggles temporary reveal
  // Pregame: no-op
  const longPressTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const didLongPress = useRef(false);
  const startPos = useRef<{ x: number; y: number } | null>(null);
  const LONG_PRESS_MS = 500;
  const MOVE_THRESHOLD = 10; // px — cancel if finger/cursor moves (scroll)

  const cancelLongPress = useCallback(() => {
    if (longPressTimer.current) {
      clearTimeout(longPressTimer.current);
      longPressTimer.current = null;
    }
  }, []);

  const handleLongPress = useCallback(() => {
    if (final) {
      // Toggle read state — reveals/hides score persistently
      if (read) {
        markUnread(game.id);
      } else {
        markRead(game.id, game.status);
      }
    } else if (live) {
      // Toggle temporary reveal
      setTempRevealed((prev) => !prev);
    }
  }, [final, live, read, game.id, game.status, markRead, markUnread]);

  const handlePointerDown = useCallback(
    (e: React.PointerEvent) => {
      didLongPress.current = false;
      startPos.current = { x: e.clientX, y: e.clientY };
      longPressTimer.current = setTimeout(() => {
        didLongPress.current = true;
        handleLongPress();
      }, LONG_PRESS_MS);
    },
    [handleLongPress],
  );

  const handlePointerMove = useCallback(
    (e: React.PointerEvent) => {
      if (!startPos.current) return;
      const dx = e.clientX - startPos.current.x;
      const dy = e.clientY - startPos.current.y;
      if (Math.abs(dx) > MOVE_THRESHOLD || Math.abs(dy) > MOVE_THRESHOLD) {
        cancelLongPress();
      }
    },
    [cancelLongPress],
  );

  const handlePointerUp = useCallback(() => {
    cancelLongPress();
    startPos.current = null;
  }, [cancelLongPress]);

  const handlePointerLeave = useCallback(() => {
    cancelLongPress();
    startPos.current = null;
  }, [cancelLongPress]);

  // Tap = navigate, long-press = toggle reveal (no <a> tag = no Safari preview hijack)
  const handleClick = useCallback(() => {
    if (didLongPress.current) {
      didLongPress.current = false;
      return;
    }
    if (!noData) {
      router.push(`/game/${game.id}`);
    }
  }, [noData, game.id, router]);

  // Suppress native context menu
  const handleContextMenu = useCallback((e: React.MouseEvent) => {
    e.preventDefault();
  }, []);

  const card = (
    <div
      className={cn(
        "relative rounded-lg border border-neutral-800 bg-neutral-900 p-3 transition select-none",
        noData && "opacity-40 pointer-events-none",
        !noData && "cursor-pointer hover:border-neutral-700",
        read && final && "border-neutral-800/60",
      )}
      onPointerDown={handlePointerDown}
      onPointerMove={handlePointerMove}
      onPointerUp={handlePointerUp}
      onPointerLeave={handlePointerLeave}
      onPointerCancel={handlePointerUp}
      onContextMenu={handleContextMenu}
      onClick={handleClick}
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
          {/* Score column */}
          {pregame ? (
            <span />
          ) : showScore || hasSavedScores ? (
            <span className="text-sm font-mono tabular-nums">
              {displayAwayScore}
            </span>
          ) : hasScoreData ? (
            /* Hidden score - clickable to reveal */
            <span
              className="text-sm font-mono tabular-nums blur-sm select-none"
            >
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
            <span
              className="text-sm font-mono tabular-nums blur-sm select-none"
            >
              {game.homeScore}
            </span>
          ) : (
            <span />
          )}
        </div>
      </div>

      {/* Bottom info */}
      <div className="mt-2 text-[11px] text-neutral-500 text-center">
        {pregame && (
          <span>{formatGameDateTime(game.gameDate)}</span>
        )}
        {live && showScore && (
          <span>
            {getPeriodLabel(game)}
            {game.gameClock ? ` ${game.gameClock}` : ""}
          </span>
        )}
        {live && !showScore && !hasSavedScores && (
          <span className="text-neutral-600">Hold to reveal</span>
        )}
        {live && !showScore && hasSavedScores && savedPosition?.timeLabel && (
          <span>@ {savedPosition.timeLabel}</span>
        )}
        {final && showScore && (
          <span className="text-neutral-600">Final</span>
        )}
        {final && !showScore && (
          <span className="text-neutral-600">Hold to reveal</span>
        )}
      </div>

    </div>
  );

  return card;
}
