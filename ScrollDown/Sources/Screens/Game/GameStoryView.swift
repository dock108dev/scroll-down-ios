import SwiftUI

/// Main story view container for completed games
/// Displays the narrative story with moments and optional full PBP access
struct GameStoryView: View {
    @ObservedObject var viewModel: GameDetailViewModel
    @Binding var isCompactStoryExpanded: Bool
    @State private var showingFullPlayByPlay = false
    @State private var collapsedMoments: Set<Int> = []

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.list) {
            // Narrative summary at the top
            if let narrative = combinedNarrative {
                compactStorySection(narrative)
            }

            // Story moments
            ForEach(viewModel.momentDisplayModels) { moment in
                MomentCardView(
                    moment: moment,
                    plays: viewModel.unifiedEventsForMoment(moment),
                    homeTeam: viewModel.game?.homeTeam ?? "Home",
                    awayTeam: viewModel.game?.awayTeam ?? "Away",
                    isExpanded: momentExpandedBinding(for: moment)
                )
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

    // MARK: - Combined Narrative

    private var combinedNarrative: String? {
        let moments = Array(viewModel.momentDisplayModels.prefix(2))
        let narratives = moments.map { $0.narrative }
        return narratives.isEmpty ? nil : narratives.joined(separator: " ")
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
            }
            .foregroundColor(DesignSystem.TextColor.secondary)

            Text(story)
                .font(.subheadline)
                .foregroundColor(DesignSystem.TextColor.primary)
                .lineLimit(isCompactStoryExpanded ? nil : 3)

            if story.count > 200 {
                Button(isCompactStoryExpanded ? "Show Less" : "Read More") {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isCompactStoryExpanded.toggle()
                    }
                }
                .font(.caption)
                .foregroundColor(DesignSystem.Colors.accent)
                .buttonStyle(SubtleInteractiveButtonStyle())
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
            .contentShape(Rectangle())
        }
        .buttonStyle(InteractiveRowButtonStyle())
    }

    // MARK: - Moment Expansion Binding

    private func momentExpandedBinding(for moment: MomentDisplayModel) -> Binding<Bool> {
        Binding(
            get: { !collapsedMoments.contains(moment.id) },
            set: { isExpanded in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    if isExpanded {
                        collapsedMoments.remove(moment.id)
                    } else {
                        collapsedMoments.insert(moment.id)
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
            isCompactStoryExpanded: .constant(false)
        )
        .padding()
    }
}
