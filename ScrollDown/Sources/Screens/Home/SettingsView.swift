import SwiftUI

struct SettingsView: View {
    @AppStorage("preferredSportsbook") private var preferredSportsbook = "DraftKings"

    private let sportsbooks = [
        "DraftKings",
        "FanDuel",
        "BetMGM",
        "Caesars",
        "bet365"
    ]

    var body: some View {
        List {
            Section("Odds") {
                Picker("Default Book", selection: $preferredSportsbook) {
                    ForEach(sportsbooks, id: \.self) { book in
                        Text(book).tag(book)
                    }
                }
            }
        }
    }
}
