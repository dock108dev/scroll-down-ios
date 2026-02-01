import SwiftUI

/// Main story view container for completed games - NARRATIVE FIRST LAYOUT
/// Reads as a continuous story with expandable footnotes for play details
/// No cards breaking the narrative - this IS the page
struct GameStoryView: View {
    @ObservedObject var viewModel: GameDetailViewModel
    @Binding var isCompactStoryExpanded: Bool
    @State private var showingFullPlayByPlay = false
    @State private var expandedMoments: Set<Int> = []

    var body: some View {
        // Narrative-first layout: continuous story with inline footnotes
        VStack(alignment: .leading, spacing: 0) {
            // The story - continuous, uninterrupted narrative
            NarrativeContainerView(
                viewModel: viewModel,
                expandedMoments: $expandedMoments
            )

            // Transition to secondary content (full play-by-play)
            if viewModel.hasUnifiedTimeline {
                ContentBreak()
                viewAllPlaysButton
            }
        }
        .sheet(isPresented: $showingFullPlayByPlay) {
            FullPlayByPlayView(viewModel: viewModel)
        }
    }

    // MARK: - View All Plays Button

    private var viewAllPlaysButton: some View {
        Button {
            showingFullPlayByPlay = true
        } label: {
            HStack {
                Image(systemName: "list.bullet.rectangle")
                    .font(.caption)
                Text("View Full Play-by-Play")
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
        .padding(.horizontal, NarrativeLayoutConfig.contentLeadingPadding)
    }
}

// MARK: - Previews

#Preview("Game Story View - Narrative First") {
    let viewModel = GameDetailViewModel()
    return ScrollView {
        GameStoryView(
            viewModel: viewModel,
            isCompactStoryExpanded: .constant(false)
        )
        .padding()
    }
}
