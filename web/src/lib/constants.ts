export const LEAGUE_OPTIONS = [
  { code: "nba", label: "NBA" },
  { code: "ncaab", label: "NCAAB" },
  { code: "nfl", label: "NFL" },
  { code: "ncaaf", label: "NCAAF" },
  { code: "mlb", label: "MLB" },
  { code: "nhl", label: "NHL" },
] as const;

export const BOOK_ABBREVIATIONS: Record<string, string> = {
  draftkings: "DK",
  fanduel: "FD",
  betmgm: "MGM",
  caesars: "CZR",
  espnbet: "ESPN",
  fanatics: "FAN",
  "hard rock bet": "HR",
  pinnacle: "PIN",
  bet365: "365",
  betrivers: "BR",
  "william hill": "WH",
  "888sport": "888",
  // legacy
  pointsbet: "PB",
  wynnbet: "WYNN",
  bovada: "BOV",
};

export const BREAKPOINTS = {
  mobile: 0,
  tablet: 768,
  desktop: 1280,
} as const;

export const MAX_CONTENT_WIDTH = {
  mobile: "100%",
  tablet: "900px",
  desktop: "1200px",
} as const;
