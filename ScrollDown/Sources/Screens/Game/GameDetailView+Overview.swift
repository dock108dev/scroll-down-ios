import SwiftUI

extension GameDetailView {
    var displayOptionsSection: some View {
        SectionCardView(title: "Recap Style", subtitle: "Choose your flow") {
            Toggle("Compact Mode", isOn: $isCompactMode)
                .tint(GameTheme.accentColor)
        }
        .accessibilityHint("Reduces spacing and typography for denser timeline view")
    }

    var overviewSection: some View {
        CollapsibleSectionCard(
            title: "Overview",
            subtitle: "Recap",
            isExpanded: $isOverviewExpanded
        ) {
            overviewContent
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Game overview")
    }

    var overviewContent: some View {
        VStack(alignment: .leading, spacing: GameDetailLayout.sectionSpacing) {
            // Context section (D1) - why this game matters
            if let context = viewModel.gameContext {
                contextSection(context)
            }
            
            // Recap content
            VStack(alignment: .leading, spacing: GameDetailLayout.textSpacing) {
                summaryView

                VStack(alignment: .leading, spacing: GameDetailLayout.listSpacing) {
                    ForEach(viewModel.recapBullets, id: \.self) { bullet in
                        HStack(alignment: .top, spacing: GameDetailLayout.listSpacing) {
                            Circle()
                                .frame(width: GameDetailLayout.bulletSize, height: GameDetailLayout.bulletSize)
                                .foregroundColor(.secondary)
                                .padding(.top, GameDetailLayout.bulletOffset)
                            Text(bullet)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
            
            // Outcome reveal gate (D3)
            revealGateView
        }
    }
    
    /// Context section explaining why the game matters
    private func contextSection(_ context: String) -> some View {
        VStack(alignment: .leading, spacing: GameDetailLayout.smallSpacing) {
            Label("Context", systemImage: "info.circle")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
            
            Text(context)
                .font(.subheadline)
                .foregroundColor(.primary)
                .padding(GameDetailLayout.contextPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6).opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: GameDetailLayout.contextCornerRadius))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Game context")
        .accessibilityValue(context)
    }
    
    /// Outcome reveal gate - explicit user control
    private var revealGateView: some View {
        VStack(alignment: .leading, spacing: GameDetailLayout.smallSpacing) {
            Divider()
                .padding(.vertical, GameDetailLayout.smallSpacing)
            
            HStack(spacing: GameDetailLayout.listSpacing) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.isOutcomeRevealed ? "Outcome visible" : "Outcome hidden")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                    
                    Text(viewModel.isOutcomeRevealed ? "Final result is shown" : "Final result is hidden")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button {
                    viewModel.toggleOutcomeReveal(for: gameId)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: viewModel.isOutcomeRevealed ? "eye.slash" : "eye")
                        Text(viewModel.isOutcomeRevealed ? "Hide" : "Reveal")
                    }
                    .font(.subheadline.weight(.medium))
                }
                .buttonStyle(.bordered)
                .tint(viewModel.isOutcomeRevealed ? .secondary : GameTheme.accentColor)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(viewModel.isOutcomeRevealed ? "Outcome visible" : "Outcome hidden")
        .accessibilityHint("Tap to \(viewModel.isOutcomeRevealed ? "hide" : "reveal") final result")
    }
}
