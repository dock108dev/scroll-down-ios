import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var readStateStore: ReadStateStore
    @EnvironmentObject var authViewModel: AuthViewModel
    @ObservedObject var oddsViewModel: OddsComparisonViewModel
    @AppStorage("appTheme") private var appTheme = "system"
    @AppStorage("preferredSportsbook") private var preferredSportsbook = ""
    @AppStorage("homeExpandedSections") private var homeExpandedSections = ""
    @AppStorage("gameExpandedSections") private var gameExpandedSections = ""
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

            Section("Score Display") {
                Picker("Score Visibility", selection: $readStateStore.scoreRevealMode) {
                    Text("Spoiler free (hold to reveal)").tag(ScoreRevealMode.onMarkRead)
                    Text("Always show scores").tag(ScoreRevealMode.always)
                }
                .pickerStyle(.inline)
                .labelsHidden()

                Text("Spoiler free hides scores until you long press. \"Always show\" displays live and final scores automatically.")
                    .font(.caption)
                    .foregroundColor(.secondary)
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

                Toggle("Hide Thin Markets", isOn: $oddsViewModel.hideLimitedData)

                Text("Filters out bets where only a few books are posting or they can't agree on a number. If the market is thin, the fair estimate is just one book's opinion.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Account section
            Section("Account") {
                if authViewModel.isAuthenticated {
                    NavigationLink {
                        AccountView(authViewModel: authViewModel)
                    } label: {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundStyle(GameTheme.accentColor)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(authViewModel.displayName)
                                    .font(.subheadline.weight(.medium))
                                Text(authViewModel.role.displayName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } else {
                    NavigationLink("Sign In / Create Account") {
                        LoginView(authViewModel: authViewModel)
                    }
                }
            }

            // Admin features (role-gated)
            if authViewModel.isAdmin {
                Section("Admin") {
                    NavigationLink("Game History") {
                        HistoryView()
                    }
                }
            }
            #if DEBUG
            if !authViewModel.isAdmin {
                Section("Admin (Debug)") {
                    NavigationLink("Game History") {
                        HistoryView()
                    }
                }
            }
            #endif

            Section {
                RealityAndFeedbackView()
            }
        }
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
