# Beta Phase B — Real Feeds (iOS)

## Environment handling

- The app now uses a single source of truth for mock vs. live data: `AppConfig.environment`.
- Switching environments updates both the data provider and the API base URL via `APIConfiguration.baseURL(for:)`.
- Mock mode remains available for development and is explicitly labeled in the home toolbar.
- Live mode uses backend snapshot APIs without falling back to mock data.

## Home feed structure (time-windowed)

The home feed is split into three backend-defined windows, fetched independently:

1. **Earlier** — `/games?range=last2`
2. **Today** — `/games?range=current`
3. **Coming Up** — `/games?range=next24`

Each section renders on its own with dedicated loading, empty, and error states. No data is merged across ranges, and the visible order is fixed: Earlier → Today → Coming Up.

## Status rendering rules

Game cards display status strictly from backend fields:

- `scheduled` → `Starts at <time>`
- `in_progress` → `Live`
- `completed` → `Final — recap available`
- `postponed` → `Postponed`
- `canceled` → `Canceled`

If a backend status is missing, the UI shows **“Status unavailable”** and logs the issue for diagnostics. The client does not infer status from scores or timestamps.
