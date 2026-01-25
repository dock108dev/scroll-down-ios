import SwiftUI

/// Full chronological play-by-play view
/// Accessible via "View All Plays" button from GameStoryView
/// Shows all plays in order without section grouping
struct FullPlayByPlayView: View {
    @ObservedObject var viewModel: GameDetailViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: DesignSystem.Spacing.list) {
                    ForEach(viewModel.unifiedTimelineEvents) { event in
                        UnifiedTimelineRowView(
                            event: event,
                            homeTeam: viewModel.game?.homeTeam ?? "Home",
                            awayTeam: viewModel.game?.awayTeam ?? "Away"
                        )
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.cardPadding)
                .padding(.vertical, DesignSystem.Spacing.section)
            }
            .background(GameTheme.background)
            .navigationTitle("Play-by-Play")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Full Play-by-Play") {
    let viewModel = GameDetailViewModel()
    return FullPlayByPlayView(viewModel: viewModel)
}
