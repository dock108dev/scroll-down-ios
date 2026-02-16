import SwiftUI

struct SettingsView: View {
    @ObservedObject var oddsViewModel: OddsComparisonViewModel
    let completedGameIds: [Int]
    @AppStorage("appTheme") private var appTheme = "system"
    @AppStorage("preferredSportsbook") private var preferredSportsbook = ""
    @AppStorage("homeExpandedSections") private var homeExpandedSections = ""
    @AppStorage("gameExpandedSections") private var gameExpandedSections = "timeline"
    @State private var readStateRefreshId = UUID()

    private var sportsbooks: [String] {
        let available = oddsViewModel.booksAvailable
        return available.isEmpty ? ["DraftKings", "FanDuel", "BetMGM", "Caesars", "bet365"] : available
    }

    private let homeSectionItems: [(key: String, label: String)] = [
        ("earlier", "Earlier"),
        ("yesterday", "Yesterday"),
        ("current", "Today"),
        ("tomorrow", "Tomorrow")
    ]

    private let gameSectionItems: [(key: String, label: String)] = [
        ("overview", "Pregame"),
        ("timeline", "Flow"),
        ("playerStats", "Player Stats"),
        ("teamStats", "Team Stats"),
        ("final", "Wrap-up")
    ]

    var body: some View {
        List {
            Section("Appearance") {
                Picker("Theme", selection: $appTheme) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
                .pickerStyle(.segmented)
            }

            Section("Recaps — Default Expanded") {
                ForEach(homeSectionItems, id: \.key) { item in
                    Button {
                        toggleSection(item.key, in: $homeExpandedSections)
                    } label: {
                        HStack {
                            Text(item.label)
                            Spacer()
                            if expandedSet(from: homeExpandedSections).contains(item.key) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }

            Section("Game — Default Expanded") {
                ForEach(gameSectionItems, id: \.key) { item in
                    Button {
                        toggleSection(item.key, in: $gameExpandedSections)
                    } label: {
                        HStack {
                            Text(item.label)
                            Spacer()
                            if expandedSet(from: gameExpandedSections).contains(item.key) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }

            Section("Odds") {
                Picker("Default Book", selection: $preferredSportsbook) {
                    Text("Best available price").tag("")
                    ForEach(sportsbooks, id: \.self) { book in
                        Text(book).tag(book)
                    }
                }

                Picker("Odds Format", selection: $oddsViewModel.oddsFormat) {
                    ForEach(OddsFormat.allCases) { format in
                        Text(format.rawValue).tag(format)
                    }
                }

                Toggle("Hide Limited Data", isOn: $oddsViewModel.hideLimitedData)

                Text("When enabled, only shows bets with reliable fair odds (proper vig removal from multiple books).")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if !completedGameIds.isEmpty {
                Section("Read Status") {
                    Button {
                        for id in completedGameIds {
                            UserDefaults.standard.set(true, forKey: "game.read.\(id)")
                        }
                        readStateRefreshId = UUID()
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle")
                            Text("Mark All Final as Read")
                        }
                    }

                    Button {
                        for id in completedGameIds {
                            UserDefaults.standard.removeObject(forKey: "game.read.\(id)")
                        }
                        readStateRefreshId = UUID()
                    } label: {
                        HStack {
                            Image(systemName: "circle")
                            Text("Mark All Final as Unread")
                        }
                    }

                    Text("\(readCount) of \(completedGameIds.count) final games marked as read.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .id(readStateRefreshId)
                }
            }

            Section {
                RealityAndFeedbackView()
            }
        }
    }

    private var readCount: Int {
        completedGameIds.filter { UserDefaults.standard.bool(forKey: "game.read.\($0)") }.count
    }

    private func expandedSet(from string: String) -> Set<String> {
        Set(string.split(separator: ",").map(String.init))
    }

    private func toggleSection(_ key: String, in storage: Binding<String>) {
        var set = expandedSet(from: storage.wrappedValue)
        if set.contains(key) {
            set.remove(key)
        } else {
            set.insert(key)
        }
        storage.wrappedValue = set.sorted().joined(separator: ",")
    }
}
