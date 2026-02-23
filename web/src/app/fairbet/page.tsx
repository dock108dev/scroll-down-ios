"use client";

import { useState } from "react";
import { useFairBetOdds } from "@/hooks/useFairBetOdds";
import { BetCard } from "@/components/fairbet/BetCard";
import { BookFilters } from "@/components/fairbet/BookFilters";
import { FairExplainerSheet } from "@/components/fairbet/FairExplainerSheet";
import { LoadingSkeleton } from "@/components/shared/LoadingSkeleton";

export default function FairBetPage() {
  const [league, setLeague] = useState("");
  const [book, setBook] = useState("");
  const [category, setCategory] = useState("");
  const [showExplainer, setShowExplainer] = useState(false);

  const { data, loading, error } = useFairBetOdds({ league, book, category });

  return (
    <div className="mx-auto max-w-5xl">
      <div className="px-4 py-4 space-y-4">
        <div className="flex items-center justify-between">
          <h1 className="text-xl font-bold">FairBet</h1>
          <button
            onClick={() => setShowExplainer(true)}
            className="text-xs text-neutral-400 hover:text-white border border-neutral-700 rounded-full px-3 py-1 transition"
          >
            How it works
          </button>
        </div>

        <BookFilters
          books={data?.books_available ?? []}
          selectedBook={book}
          onBookChange={setBook}
          selectedLeague={league}
          onLeagueChange={setLeague}
          categories={data?.market_categories_available ?? []}
          selectedCategory={category}
          onCategoryChange={setCategory}
        />
      </div>

      <div className="px-4 pb-4 space-y-3">
        {loading && <LoadingSkeleton count={6} className="h-28" />}

        {error && (
          <div className="py-8 text-center text-red-500 text-sm">{error}</div>
        )}

        {!loading && !error && data?.bets.length === 0 && (
          <div className="py-8 text-center text-neutral-500 text-sm">
            No +EV bets found with current filters
          </div>
        )}

        {data?.bets.map((bet, i) => (
          <BetCard key={`${bet.game_id}-${bet.market_key}-${bet.selection_key}-${i}`} bet={bet} />
        ))}
      </div>

      <FairExplainerSheet
        open={showExplainer}
        onClose={() => setShowExplainer(false)}
      />
    </div>
  );
}
