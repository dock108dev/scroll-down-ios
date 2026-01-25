import SwiftUI

/// Main story view container for completed games
/// Displays the narrative story with sections, social posts, and optional full PBP access
struct GameStoryView: View {
    @ObservedObject var viewModel: GameDetailViewModel
    @Binding var collapsedSections: Set<Int>
    @Binding var isCompactStoryExpanded: Bool
    @State private var showingFullPlayByPlay = false

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.list) {
            // Compact story (AI narrative) at the top
            if let story = viewModel.compactStory {
                compactStorySection(story)
            }

            // Story sections with matched social posts
            ForEach(viewModel.sections) { section in
                StorySectionBlockView(
                    section: section,
                    plays: viewModel.unifiedEventsForSection(section),
                    socialPosts: viewModel.socialPostsForSection(section),
                    homeTeam: viewModel.game?.homeTeam ?? "Home",
                    awayTeam: viewModel.game?.awayTeam ?? "Away",
                    isExpanded: sectionExpandedBinding(for: section)
                )
            }

            // Deferred social posts (couldn't be matched to sections)
            if !viewModel.deferredSocialPosts.isEmpty {
                MoreReactionsView(posts: viewModel.deferredSocialPosts)
            }

            // Full Play-by-Play access button
            if viewModel.hasUnifiedTimeline {
                viewAllPlaysButton
            }
        }
        .sheet(isPresented: $showingFullPlayByPlay) {
            FullPlayByPlayView(viewModel: viewModel)
        }
    }

    // MARK: - Compact Story Section

    private func compactStorySection(_ story: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "text.alignleft")
                    .font(.caption)
                Text("Game Story")
                    .font(.caption.weight(.semibold))

                Spacer()

                if let quality = viewModel.storyQuality {
                    Text(quality.displayName)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(DesignSystem.Colors.accent.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
            .foregroundColor(DesignSystem.TextColor.secondary)

            Text(story)
                .font(.subheadline)
                .foregroundColor(DesignSystem.TextColor.primary)
                .lineLimit(isCompactStoryExpanded ? nil : 3)

            if story.count > 200 {
                Button(isCompactStoryExpanded ? "Show Less" : "Read More") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isCompactStoryExpanded.toggle()
                    }
                }
                .font(.caption)
                .foregroundColor(DesignSystem.Colors.accent)
            }
        }
        .padding(DesignSystem.Spacing.cardPadding)
        .background(DesignSystem.Colors.cardBackground.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.element))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.element)
                .stroke(DesignSystem.borderColor.opacity(0.2), lineWidth: 0.5)
        )
    }

    // MARK: - View All Plays Button

    private var viewAllPlaysButton: some View {
        Button {
            showingFullPlayByPlay = true
        } label: {
            HStack {
                Image(systemName: "list.bullet.rectangle")
                    .font(.caption)
                Text("View All Plays")
                    .font(.caption.weight(.medium))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2)
            }
            .foregroundColor(DesignSystem.Colors.accent)
            .padding(DesignSystem.Spacing.elementPadding)
            .background(DesignSystem.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.element))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Section Expansion Binding

    private func sectionExpandedBinding(for section: SectionEntry) -> Binding<Bool> {
        Binding(
            get: { !collapsedSections.contains(section.id) },
            set: { isExpanded in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    if isExpanded {
                        collapsedSections.remove(section.id)
                    } else {
                        collapsedSections.insert(section.id)
                    }
                }
            }
        )
    }
}

// MARK: - Previews

#Preview("Game Story View") {
    let viewModel = GameDetailViewModel()
    return ScrollView {
        GameStoryView(
            viewModel: viewModel,
            collapsedSections: .constant([]),
            isCompactStoryExpanded: .constant(false)
        )
        .padding()
    }
}
