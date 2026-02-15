import SwiftUI

extension GameDetailView {
    // MARK: - Pregame Buzz Section (Tier 4: Reference)

    var pregameSection: some View {
        CollapsibleSectionCard(
            title: "Pregame Buzz",
            isExpanded: $isOverviewExpanded
        ) {
            pregameBuzzContent
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Pregame buzz")
    }

    @ViewBuilder
    private var pregameBuzzContent: some View {
        let oddsLines = viewModel.pregameOddsLines
        let posts = viewModel.pregameSocialPosts

        if oddsLines.isEmpty && posts.isEmpty {
            EmptySectionView(text: "No pregame posts available.")
        } else {
            VStack(spacing: GameDetailLayout.listSpacing) {
                // Odds lines card (above posts)
                if !oddsLines.isEmpty {
                    pregameOddsCard(oddsLines)
                }

                // Social posts with pagination
                if !posts.isEmpty {
                    let visible = Array(posts.prefix(pregamePostsShown))
                    ForEach(visible) { post in
                        pregamePostRow(post)
                    }

                    if posts.count > pregamePostsShown {
                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                pregamePostsShown += 5
                            }
                        } label: {
                            Text("Load More (\(posts.count - pregamePostsShown) remaining)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(DesignSystem.TextColor.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(DesignSystem.Colors.cardBackground.opacity(0.4))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Pregame Odds Card

    private func pregameOddsCard(_ lines: [GameDetailViewModel.PregameOddsLine]) -> some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("LINES")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(DesignSystem.TextColor.tertiary)
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(DesignSystem.Colors.elevatedBackground)

            // Rows
            ForEach(Array(lines.enumerated()), id: \.element.id) { index, line in
                HStack(spacing: 0) {
                    Text(line.label)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(DesignSystem.TextColor.primary)
                        .frame(width: 52, alignment: .leading)

                    Text(line.detail)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(DesignSystem.TextColor.secondary)

                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(index % 2 != 0
                    ? DesignSystem.Colors.elevatedBackground.opacity(0.5)
                    : Color.clear)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.element))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.element)
                .stroke(DesignSystem.borderColor, lineWidth: DesignSystem.borderWidth)
        )
    }

    /// Individual pre-game social post row
    private func pregamePostRow(_ post: SocialPostEntry) -> some View {
        SocialPostRow(post: post, displayMode: .standard)
    }
}
