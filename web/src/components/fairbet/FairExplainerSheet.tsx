"use client";

import { cn } from "@/lib/utils";

interface FairExplainerSheetProps {
  open: boolean;
  onClose: () => void;
}

export function FairExplainerSheet({
  open,
  onClose,
}: FairExplainerSheetProps) {
  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center md:items-center">
      <div className="absolute inset-0 bg-black/60" onClick={onClose} />
      <div
        className={cn(
          "relative z-10 w-full max-w-lg rounded-t-2xl md:rounded-2xl bg-neutral-900 border border-neutral-800 p-6 space-y-4",
        )}
      >
        <div className="flex items-center justify-between">
          <h2 className="text-lg font-semibold">How FairBet Works</h2>
          <button
            onClick={onClose}
            className="text-neutral-500 hover:text-white text-sm"
          >
            Close
          </button>
        </div>

        <div className="text-sm text-neutral-300 space-y-3">
          <p>
            FairBet calculates the <strong>true probability</strong> of each
            outcome by removing the sportsbook&apos;s margin (vig) from sharp
            lines.
          </p>
          <p>
            A bet has <strong>positive expected value (+EV)</strong> when a
            book&apos;s price implies a lower probability than the true
            probability. This means the payout exceeds what the risk
            warrants.
          </p>
          <p>
            <span className="text-green-400 font-medium">Green chips</span>{" "}
            indicate +EV prices.{" "}
            <span className="text-blue-400 font-medium">Blue rings</span>{" "}
            indicate sharp (reference) books.
          </p>
        </div>
      </div>
    </div>
  );
}
