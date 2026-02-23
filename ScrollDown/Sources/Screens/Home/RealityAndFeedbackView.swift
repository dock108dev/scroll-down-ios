import SwiftUI

/// Fourth-wall-breaking "reality check" at the bottom of Settings.
/// Self-contained so it can evolve (tooltips, links, open-source notes) without redesigning Settings.
struct RealityAndFeedbackView: View {

    private let feedbackEmail = "feedback@scrolldown.app"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Real Talk")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            Text("Game flow summaries are AI generated. They're usually solid but every now and then a player ends up on the wrong team or a play gets made up. We're working on it. Flag the weird ones and it helps us get better.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Text("FairBet estimates are based on what the books are pricing right now with the vig stripped out. The math assumes books know how to set lines, which mostly holds when the market is deep. When it's thin, early, or niche, the numbers can drift. Some games, odds, or socials might be missing too. Data sources have gaps and nothing updates instantly.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Button {
                openFeedback()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "envelope")
                    Text("Report something off")
                }
                .font(.footnote.weight(.medium))
            }
        }
        .padding(.vertical, 4)
    }

    private func openFeedback() {
        guard let url = URL(string: "mailto:\(feedbackEmail)?subject=Scroll%20Down%20Feedback") else { return }
        UIApplication.shared.open(url)
    }
}
