import type { OddsFormat } from "./types";

export function formatDate(dateStr: string): string {
  const date = new Date(dateStr);
  return date.toLocaleDateString("en-US", {
    weekday: "short",
    month: "short",
    day: "numeric",
  });
}

export function formatTime(dateStr: string): string {
  const date = new Date(dateStr);
  return date.toLocaleTimeString("en-US", {
    hour: "numeric",
    minute: "2-digit",
  });
}

export function formatOdds(price: number, format: OddsFormat): string {
  switch (format) {
    case "american":
      return price > 0 ? `+${price}` : `${price}`;
    case "decimal": {
      const decimal =
        price > 0 ? price / 100 + 1 : 100 / Math.abs(price) + 1;
      return decimal.toFixed(2);
    }
    case "fractional": {
      const decimal =
        price > 0 ? price / 100 + 1 : 100 / Math.abs(price) + 1;
      const frac = decimal - 1;
      const numerator = Math.round(frac * 100);
      const denominator = 100;
      const gcd = greatestCommonDivisor(numerator, denominator);
      return `${numerator / gcd}/${denominator / gcd}`;
    }
  }
}

function greatestCommonDivisor(a: number, b: number): number {
  return b === 0 ? a : greatestCommonDivisor(b, a % b);
}

export function formatEV(ev: number): string {
  const sign = ev > 0 ? "+" : "";
  return `${sign}${ev.toFixed(1)}%`;
}

export function classifyDateSection(dateStr: string): string {
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const date = new Date(dateStr);
  date.setHours(0, 0, 0, 0);

  const diffDays = Math.round(
    (date.getTime() - today.getTime()) / (1000 * 60 * 60 * 24),
  );

  if (diffDays < -1) return "Earlier";
  if (diffDays === -1) return "Yesterday";
  if (diffDays === 0) return "Today";
  if (diffDays === 1) return "Tomorrow";
  return "Upcoming";
}

export function cn(...classes: (string | false | null | undefined)[]): string {
  return classes.filter(Boolean).join(" ");
}
