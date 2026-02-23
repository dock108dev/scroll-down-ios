import type { GameDetailResponse } from "@/lib/types";

interface OverviewSectionProps {
  data: GameDetailResponse;
}

export function OverviewSection({ data }: OverviewSectionProps) {
  const game = data.game;

  return (
    <div className="px-4">
      <div className="rounded-lg border border-neutral-800 bg-neutral-900 p-4 space-y-3">
        <div className="grid grid-cols-2 gap-3 text-sm">
          <div>
            <div className="text-xs text-neutral-500 mb-0.5">Date</div>
            <div className="text-neutral-200">{game.gameDate}</div>
          </div>
          <div>
            <div className="text-xs text-neutral-500 mb-0.5">League</div>
            <div className="text-neutral-200 uppercase">{game.leagueCode}</div>
          </div>
          {game.season && (
            <div>
              <div className="text-xs text-neutral-500 mb-0.5">Season</div>
              <div className="text-neutral-200">
                {game.season} {game.seasonType}
              </div>
            </div>
          )}
        </div>

        {data.odds.length > 0 && (
          <div>
            <div className="text-xs text-neutral-500 mb-1">Opening Lines</div>
            <div className="text-sm text-neutral-300">
              {data.odds.length} odds entries available
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
