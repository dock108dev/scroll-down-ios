import SwiftUI

/// Main flow view container for completed games
struct GameFlowView: View {
    @ObservedObject var viewModel: GameDetailViewModel
    @Binding var isCompactFlowExpanded: Bool
    @State private var showingFullPlayByPlay = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            FlowContainerView(viewModel: viewModel)

            if viewModel.hasUnifiedTimeline {
                ContentBreak()
                viewAllPlaysButton
            }
        }
        .sheet(isPresented: $showingFullPlayByPlay) {
            FullPlayByPlayView(viewModel: viewModel)
        }
    }

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
