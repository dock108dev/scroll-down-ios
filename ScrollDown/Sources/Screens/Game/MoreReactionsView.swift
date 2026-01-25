import SwiftUI

/// Collapsible section for social posts that couldn't be matched to story sections
/// Hidden when empty, collapsed by default
struct MoreReactionsView: View {
    let posts: [UnifiedTimelineEvent]
    @State private var isExpanded = false

    /// Don't render anything if no posts
    var body: some View {
        if !posts.isEmpty {
            content
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header (always visible, tappable)
            Button(action: toggleExpansion) {
                headerContent
            }
            .buttonStyle(.plain)

            // Expanded content - list of social posts
            if isExpanded {
                expandedContent
                    .transition(.opacity)
            }
        }
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.element))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.element)
                .stroke(DesignSystem.borderColor.opacity(0.3), lineWidth: 0.5)
        )
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }

    // MARK: - Header

    private var headerContent: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("More Reactions")
                    .font(.subheadline.weight(.regular))
                    .foregroundColor(DesignSystem.TextColor.primary)

                Text("\(posts.count) posts")
                    .font(.caption2)
                    .foregroundColor(DesignSystem.TextColor.secondary)
            }

            Spacer()

            // Expansion indicator
            Image(systemName: "chevron.right")
                .font(.caption.weight(.medium))
                .foregroundColor(DesignSystem.TextColor.tertiary)
                .rotationEffect(.degrees(isExpanded ? 90 : 0))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .contentShape(Rectangle())
    }

    // MARK: - Expanded Content

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
                .padding(.horizontal, 12)

            VStack(spacing: DesignSystem.Spacing.list) {
                ForEach(posts) { post in
                    UnifiedTimelineRowView(
                        event: post,
                        homeTeam: "Home",
                        awayTeam: "Away"
                    )
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
    }

    // MARK: - Actions

    private func toggleExpansion() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isExpanded.toggle()
        }
    }
}

// MARK: - Previews

#Preview("More Reactions - Collapsed") {
    MoreReactionsView(posts: [
        UnifiedTimelineEvent(
            from: [
                "event_type": "tweet",
                "tweet_text": "Great game tonight! Thunder looking strong.",
                "source_handle": "sportswriter",
                "posted_at": "2026-01-13T22:00:00Z"
            ],
            index: 200
        ),
        UnifiedTimelineEvent(
            from: [
                "event_type": "tweet",
                "tweet_text": "SGA is playing at an MVP level this season.",
                "source_handle": "nbaanalyst",
                "posted_at": "2026-01-13T22:05:00Z"
            ],
            index: 201
        ),
        UnifiedTimelineEvent(
            from: [
                "event_type": "tweet",
                "tweet_text": "Thunder defense was suffocating in the 4th quarter.",
                "source_handle": "basketballnews",
                "posted_at": "2026-01-13T22:10:00Z"
            ],
            index: 202
        )
    ])
    .padding()
}

#Preview("More Reactions - Empty") {
    MoreReactionsView(posts: [])
        .padding()
}

#Preview("More Reactions - Single Post") {
    MoreReactionsView(posts: [
        UnifiedTimelineEvent(
            from: [
                "event_type": "tweet",
                "tweet_text": "Final: Thunder 112, Spurs 105",
                "source_handle": "okcthunder",
                "posted_at": "2026-01-13T22:30:00Z"
            ],
            index: 300
        )
    ])
    .padding()
}
