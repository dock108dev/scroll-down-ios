import type { GameDetailResponse } from "@/lib/types";

interface WrapUpSectionProps {
  data: GameDetailResponse;
}

export function WrapUpSection({ data }: WrapUpSectionProps) {
  const metrics = data.derivedMetrics;

  if (!metrics || Object.keys(metrics).length === 0) {
    return (
      <div className="px-4 py-4 text-sm text-neutral-500">
        No wrap-up data available
      </div>
    );
  }

  return (
    <div className="px-4">
      <div className="rounded-lg border border-neutral-800 bg-neutral-900 p-4 space-y-3">
        {Object.entries(metrics).map(([key, value]) => (
          <div key={key}>
            <div className="text-xs text-neutral-500 capitalize mb-0.5">
              {key.replace(/_/g, " ")}
            </div>
            <div className="text-sm text-neutral-200">
              {typeof value === "string"
                ? value
                : JSON.stringify(value)}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
