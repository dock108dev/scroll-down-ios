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

            Text("Game flow summaries are AI-generated. They're usually solid, but occasionally a player ends up on the wrong team or a play gets invented. We're working on it — you can help by flagging the weird ones.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Text("FairBet odds are vig-removed estimates based on what the market is pricing. They assume markets are efficient, which mostly holds for major lines. Thin markets, early lines, and niche props can drift. Some games, odds, or socials may be missing entirely — data sources have gaps and timing limits.")
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
