import SwiftUI

/// Main flow view container for completed games
struct GameFlowView: View {
    @ObservedObject var viewModel: GameDetailViewModel
    @Binding var isCompactFlowExpanded: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            FlowContainerView(viewModel: viewModel)
        }
    }
}
