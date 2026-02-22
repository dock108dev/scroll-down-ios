import SwiftUI

#Preview("PBP Scoring Play") {
    UnifiedTimelineRowView(
        event: UnifiedTimelineEvent(
            from: [
                "event_type": "pbp",
                "period": 1,
                "game_clock": "11:42",
                "description": "S. Curry makes 3-pt shot from 25 ft",
                "team": "GSW",
                "player_name": "S. Curry",
                "home_score": 3,
                "away_score": 0
            ],
            index: 0
        ),
        homeTeam: "Warriors",
        awayTeam: "Lakers"
    )
    .padding()
}

#Preview("PBP Non-Scoring Play") {
    UnifiedTimelineRowView(
        event: UnifiedTimelineEvent(
            from: [
                "event_type": "pbp",
                "period": 1,
                "game_clock": "11:30",
                "description": "L. James misses 3-pt jump shot from 26 ft",
                "team": "LAL"
            ],
            index: 1
        ),
        homeTeam: "Warriors",
        awayTeam: "Lakers"
    )
    .padding()
}

#Preview("Tweet Event") {
    UnifiedTimelineRowView(
        event: UnifiedTimelineEvent(
            from: [
                "event_type": "tweet",
                "tweet_text": "What a shot by Curry! The crowd goes wild!",
                "source_handle": "warriors",
                "posted_at": "2026-01-13T19:30:00Z",
                "image_url": "https://example.com/image.jpg"
            ],
            index: 2
        ),
        homeTeam: "Warriors",
        awayTeam: "Lakers"
    )
    .padding()
}

#Preview("Visual Hierarchy - Basketball") {
    VStack(spacing: 12) {
        // Made shot with stats
        UnifiedTimelineRowView(
            event: UnifiedTimelineEvent(
                from: [
                    "event_type": "pbp",
                    "period": 1,
                    "game_clock": "11:42",
                    "description": "Tatum makes 3PT Jump Shot from 25 ft (3 PTS)",
                    "home_score": 3,
                    "away_score": 0
                ],
                index: 0
            ),
            homeTeam: "Celtics",
            awayTeam: "Heat"
        )

        // Missed shot
        UnifiedTimelineRowView(
            event: UnifiedTimelineEvent(
                from: [
                    "event_type": "pbp",
                    "period": 1,
                    "game_clock": "11:30",
                    "description": "MISS Brown 16' Pullup Jump Shot from the corner"
                ],
                index: 1
            ),
            homeTeam: "Celtics",
            awayTeam: "Heat"
        )

        // Rebound with stats
        UnifiedTimelineRowView(
            event: UnifiedTimelineEvent(
                from: [
                    "event_type": "pbp",
                    "period": 1,
                    "game_clock": "11:28",
                    "description": "Porzingis REBOUND (Off:1 Def:0)"
                ],
                index: 2
            ),
            homeTeam: "Celtics",
            awayTeam: "Heat"
        )

        // Steal
        UnifiedTimelineRowView(
            event: UnifiedTimelineEvent(
                from: [
                    "event_type": "pbp",
                    "period": 2,
                    "game_clock": "5:15",
                    "description": "White STEAL (2 STL)"
                ],
                index: 3
            ),
            homeTeam: "Celtics",
            awayTeam: "Heat"
        )
    }
    .padding()
}

#Preview("Visual Hierarchy - Hockey") {
    VStack(spacing: 12) {
        // Goal
        UnifiedTimelineRowView(
            event: UnifiedTimelineEvent(
                from: [
                    "event_type": "pbp",
                    "period": 1,
                    "game_clock": "14:32",
                    "description": "GOAL MacKinnon Wrist Shot Offensive Zone (1-0)",
                    "home_score": 1,
                    "away_score": 0
                ],
                index: 0
            ),
            homeTeam: "Avalanche",
            awayTeam: "Senators"
        )

        // Shot/Save
        UnifiedTimelineRowView(
            event: UnifiedTimelineEvent(
                from: [
                    "event_type": "pbp",
                    "period": 1,
                    "game_clock": "12:45",
                    "description": "SHOT Tkachuk Slap Shot Offensive Zone - SAVE Georgiev"
                ],
                index: 1
            ),
            homeTeam: "Avalanche",
            awayTeam: "Senators"
        )

        // Hit
        UnifiedTimelineRowView(
            event: UnifiedTimelineEvent(
                from: [
                    "event_type": "pbp",
                    "period": 2,
                    "game_clock": "8:20",
                    "description": "HIT Makar on Batherson Defensive Zone"
                ],
                index: 2
            ),
            homeTeam: "Avalanche",
            awayTeam: "Senators"
        )

        // Penalty
        UnifiedTimelineRowView(
            event: UnifiedTimelineEvent(
                from: [
                    "event_type": "pbp",
                    "period": 2,
                    "game_clock": "3:45",
                    "description": "PENALTY Rantanen Tripping (2 min) Neutral Zone"
                ],
                index: 3
            ),
            homeTeam: "Avalanche",
            awayTeam: "Senators"
        )
    }
    .padding()
}
