import type {
  GameListResponse,
  GameDetailResponse,
  GameFlowResponse,
  TimelineArtifactResponse,
  PbpResponse,
  SocialPostListResponse,
  TeamSummary,
  BetsResponse,
} from "./types";

async function fetchApi<T>(path: string): Promise<T> {
  const res = await fetch(path);
  if (!res.ok) throw new Error(`Fetch failed: ${res.status}`);
  return res.json();
}

export const api = {
  games: (params?: URLSearchParams) =>
    fetchApi<GameListResponse>(`/api/games${params ? `?${params}` : ""}`),
  game: (id: number) => fetchApi<GameDetailResponse>(`/api/games/${id}`),
  flow: (id: number) => fetchApi<GameFlowResponse>(`/api/games/${id}/flow`),
  timeline: (id: number) =>
    fetchApi<TimelineArtifactResponse>(`/api/games/${id}/timeline`),
  pbp: (id: number) => fetchApi<PbpResponse>(`/api/games/${id}/pbp`),
  social: (id: number) =>
    fetchApi<SocialPostListResponse>(`/api/games/${id}/social`),
  teams: () => fetchApi<TeamSummary[]>("/api/teams"),
  fairbetOdds: (params?: URLSearchParams) =>
    fetchApi<BetsResponse>(
      `/api/fairbet/odds${params ? `?${params}` : ""}`,
    ),
};
