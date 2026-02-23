import type { FlowBlock } from "@/lib/types";
import { MiniBoxScore } from "./MiniBoxScore";
import { cn } from "@/lib/utils";

interface FlowBlockCardProps {
  block: FlowBlock;
  homeTeam?: string;
  awayTeam?: string;
  homeColor?: string;
  awayColor?: string;
}

const ROLE_LABELS: Record<string, string> = {
  setup: "Setup",
  momentum_shift: "Momentum Shift",
  response: "Response",
  decision_point: "Decision Point",
  resolution: "Resolution",
  unknown: "",
};

export function FlowBlockCard({
  block,
  homeTeam,
  awayTeam,
  homeColor,
  awayColor,
}: FlowBlockCardProps) {
  const roleLabel = ROLE_LABELS[block.role] ?? "";
  const scoreChange = block.score_after.join("-");

  return (
    <div className="ml-10 rounded-lg border border-neutral-800 bg-neutral-900 p-4">
      <div className="flex items-center gap-2 mb-2">
        {roleLabel && (
          <span
            className={cn(
              "text-[10px] uppercase tracking-wide font-semibold px-2 py-0.5 rounded",
              block.role === "momentum_shift" &&
                "bg-yellow-500/10 text-yellow-500",
              block.role === "resolution" && "bg-green-500/10 text-green-500",
              block.role === "decision_point" &&
                "bg-blue-500/10 text-blue-500",
              block.role === "setup" && "bg-neutral-700/50 text-neutral-400",
              block.role === "response" &&
                "bg-neutral-700/50 text-neutral-300",
            )}
          >
            {roleLabel}
          </span>
        )}
        <span className="text-xs text-neutral-500 ml-auto font-mono">
          {scoreChange}
        </span>
      </div>

      <p className="text-sm text-neutral-200 leading-relaxed">
        {block.narrative}
      </p>

      {block.mini_box && (
        <MiniBoxScore
          miniBox={block.mini_box}
          homeTeam={homeTeam}
          awayTeam={awayTeam}
          homeColor={homeColor}
          awayColor={awayColor}
        />
      )}
    </div>
  );
}
