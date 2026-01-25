import SwiftUI

/// Story section block that combines the section card with matched social posts
/// Renders the section content first, then any social posts matched to this section
struct StorySectionBlockView: View {
    let section: SectionEntry
    let plays: [UnifiedTimelineEvent]
    let socialPosts: [UnifiedTimelineEvent]
    let homeTeam: String
    let awayTeam: String
    @Binding var isExpanded: Bool

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.list) {
            // Section card with expandable plays
            StorySectionCardView(
                section: section,
                plays: plays,
                homeTeam: homeTeam,
                awayTeam: awayTeam,
                isExpanded: $isExpanded
            )

            // Social posts matched to this section (rendered after section)
            if !socialPosts.isEmpty {
                socialPostsSection
            }
        }
    }

    // MARK: - Social Posts Section

    private var socialPostsSection: some View {
        VStack(spacing: DesignSystem.Spacing.list) {
            ForEach(socialPosts) { post in
                UnifiedTimelineRowView(
                    event: post,
                    homeTeam: homeTeam,
                    awayTeam: awayTeam
                )
            }
        }
        .padding(.leading, 12) // Indent to show relationship to section
    }
}

// MARK: - Previews

#Preview("Section with Social Posts") {
    StorySectionBlockView(
        section: SectionEntry(
            sectionIndex: 0,
            beatType: .run,
            header: "Thunder go on a 12-0 run to take control.",
            chaptersIncluded: ["ch_001"],
            startScore: ScoreSnapshot(home: 45, away: 42),
            endScore: ScoreSnapshot(home: 57, away: 42),
            notes: ["SGA scores 8 straight", "Spurs call timeout"]
        ),
        plays: [],
        socialPosts: [
            UnifiedTimelineEvent(
                from: [
                    "event_type": "tweet",
                    "tweet_text": "SGA is cooking right now! This run is unreal",
                    "source_handle": "oaborworn",
                    "posted_at": "2026-01-13T19:30:00Z"
                ],
                index: 100
            ),
            UnifiedTimelineEvent(
                from: [
                    "event_type": "tweet",
                    "tweet_text": "Timeout Spurs. Down 12-0 in the last 3 minutes.",
                    "source_handle": "spursnation",
                    "posted_at": "2026-01-13T19:32:00Z"
                ],
                index: 101
            )
        ],
        homeTeam: "Thunder",
        awayTeam: "Spurs",
        isExpanded: .constant(false)
    )
    .padding()
}

#Preview("Section without Social Posts") {
    StorySectionBlockView(
        section: SectionEntry(
            sectionIndex: 1,
            beatType: .backAndForth,
            header: "Teams trade baskets in competitive stretch.",
            chaptersIncluded: ["ch_002"],
            startScore: ScoreSnapshot(home: 57, away: 42),
            endScore: ScoreSnapshot(home: 65, away: 58),
            notes: ["3 lead changes"]
        ),
        plays: [],
        socialPosts: [],
        homeTeam: "Thunder",
        awayTeam: "Spurs",
        isExpanded: .constant(false)
    )
    .padding()
}

#Preview("Expanded Section with Social Posts") {
    StorySectionBlockView(
        section: SectionEntry(
            sectionIndex: 2,
            beatType: .closingSequence,
            header: "Thunder close out the game in final minutes.",
            chaptersIncluded: ["ch_003"],
            startScore: ScoreSnapshot(home: 98, away: 92),
            endScore: ScoreSnapshot(home: 112, away: 105),
            notes: ["Final: 112-105"]
        ),
        plays: [
            UnifiedTimelineEvent(
                from: [
                    "event_type": "pbp",
                    "period": 4,
                    "game_clock": "0:45",
                    "description": "S. Gilgeous-Alexander makes free throw 1 of 2",
                    "home_score": 110,
                    "away_score": 105
                ],
                index: 0
            )
        ],
        socialPosts: [
            UnifiedTimelineEvent(
                from: [
                    "event_type": "tweet",
                    "tweet_text": "SGA with 32 points tonight. What a performance!",
                    "source_handle": "oaborworn",
                    "posted_at": "2026-01-13T21:30:00Z"
                ],
                index: 102
            )
        ],
        homeTeam: "Thunder",
        awayTeam: "Spurs",
        isExpanded: .constant(true)
    )
    .padding()
}
