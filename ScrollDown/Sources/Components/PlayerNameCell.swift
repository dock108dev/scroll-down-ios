import SwiftUI

/// Compact player name cell that shows abbreviated name with tap-to-expand tooltip.
struct PlayerNameCell: View {
    let fullName: String

    @State private var showingFullName = false

    var body: some View {
        Text(fullName.abbreviatedPlayerName)
            .font(.subheadline.weight(.medium))
            .foregroundColor(.primary)
            .lineLimit(1)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeOut(duration: 0.15)) {
                    showingFullName = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeIn(duration: 0.15)) {
                        showingFullName = false
                    }
                }
            }
            .overlay(alignment: .top) {
                if showingFullName {
                    fullNameTooltip
                        .offset(y: -36)
                        .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .bottom)))
                }
            }
    }

    private var fullNameTooltip: some View {
        Text(fullName)
            .font(DesignSystem.Typography.rowMeta.weight(.medium))
            .foregroundColor(.white)
            .fixedSize()
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(.darkGray))
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.small))
            .shadow(color: .black.opacity(0.2), radius: DesignSystem.Shadow.subtleRadius, y: DesignSystem.Shadow.subtleY)
            .zIndex(100)
    }
}
