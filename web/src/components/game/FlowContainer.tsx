"use client";

import { useFlow } from "@/hooks/useFlow";
import { FlowBlockCard } from "./FlowBlockCard";
import { LoadingSkeleton } from "@/components/shared/LoadingSkeleton";

interface FlowContainerProps {
  gameId: number;
}

export function FlowContainer({ gameId }: FlowContainerProps) {
  const { data, loading, error } = useFlow(gameId);

  if (loading) {
    return (
      <div className="px-4 space-y-3">
        <LoadingSkeleton count={3} className="h-32" />
      </div>
    );
  }

  if (error || !data) {
    return (
      <div className="px-4 py-4 text-sm text-neutral-500">
        {error ?? "No flow data available"}
      </div>
    );
  }

  return (
    <div className="px-4 space-y-0">
      {/* Visual spine */}
      <div className="relative">
        <div className="absolute left-6 top-0 bottom-0 w-px bg-neutral-800" />
        <div className="space-y-4 relative">
          {data.blocks.map((block) => (
            <FlowBlockCard
              key={block.block_index}
              block={block}
              homeTeam={data.home_team}
              awayTeam={data.away_team}
              homeColor={data.home_team_color_dark}
              awayColor={data.away_team_color_dark}
            />
          ))}
        </div>
      </div>
    </div>
  );
}
