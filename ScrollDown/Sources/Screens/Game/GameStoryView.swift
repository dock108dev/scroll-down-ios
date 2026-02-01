import SwiftUI

/// Main story view container for completed games
/// Displays the narrative story with moments grouped by quarter
struct GameStoryView: View {
    @ObservedObject var viewModel: GameDetailViewModel
    @Binding var isCompactStoryExpanded: Bool
    @State private var showingFullPlayByPlay = false
    @State private var collapsedQuarters: Set<Int> = []
    @State private var hasInitializedCollapsed = false

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.list) {
            // Story moments grouped by quarter (no summary block)
            ForEach(groupedMomentsByQuarter, id: \.quarter) { group in
                quarterSection(group)
            }

            // Full Play-by-Play access button
            if viewModel.hasUnifiedTimeline {
                viewAllPlaysButton
            }
        }
        .sheet(isPresented: $showingFullPlayByPlay) {
            FullPlayByPlayView(viewModel: viewModel)
        }
        .onAppear {
            initializeCollapsedQuarters()
        }
    }

    // MARK: - Quarter Grouping

    private var groupedMomentsByQuarter: [QuarterMomentGroup] {
        let moments = viewModel.momentDisplayModels
        var groups: [Int: [MomentDisplayModel]] = [:]

        for moment in moments {
            let period = moment.period
            groups[period, default: []].append(moment)
        }

        return groups.keys.sorted().map { quarter in
            QuarterMomentGroup(quarter: quarter, moments: groups[quarter] ?? [])
        }
    }

    /// Initialize Q1 expanded, Q2+ collapsed
    private func initializeCollapsedQuarters() {
        guard !hasInitializedCollapsed else { return }
        hasInitializedCollapsed = true

        let quarters = groupedMomentsByQuarter.map { $0.quarter }
        for quarter in quarters {
            // Only collapse Q2 and later - keep Q1 expanded
            if quarter > 1 {
                collapsedQuarters.insert(quarter)
            }
        }
    }

    // MARK: - Quarter Section

    private func quarterSection(_ group: QuarterMomentGroup) -> some View {
        CollapsibleQuarterCard(
            title: quarterTitle(group.quarter),
            isExpanded: Binding(
                get: { !collapsedQuarters.contains(group.quarter) },
                set: { isExpanded in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if isExpanded {
                            collapsedQuarters.remove(group.quarter)
                        } else {
                            collapsedQuarters.insert(group.quarter)
                        }
                    }
                }
            )
        ) {
            VStack(spacing: DesignSystem.Spacing.list) {
                ForEach(group.moments) { moment in
                    MomentCardView(
                        moment: moment,
                        plays: viewModel.unifiedEventsForMoment(moment),
                        homeTeam: viewModel.game?.homeTeam ?? "Home",
                        awayTeam: viewModel.game?.awayTeam ?? "Away",
                        isExpanded: .constant(false) // Moments start collapsed within quarter
                    )
                }
            }
        }
    }

    private func quarterTitle(_ quarter: Int) -> String {
        if quarter <= 4 {
            return "Quarter \(quarter)"
        } else {
            return "OT\(quarter - 4)"
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
                    withAnimation(.easeInOut(duration: 0.2)) {
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
}

// MARK: - Quarter Moment Group

private struct QuarterMomentGroup {
    let quarter: Int
    let moments: [MomentDisplayModel]
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
