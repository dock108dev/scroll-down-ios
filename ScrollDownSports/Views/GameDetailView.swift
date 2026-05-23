import SwiftUI

struct GameDetailView: View {
    let gameId: Int
    let summary: GameSummary?

    @StateObject private var viewModel: GameDetailViewModel
    @State private var pinToBottom = false
    private let bottomAnchorID = "detail-bottom-anchor"

    init(gameId: Int, summary: GameSummary? = nil) {
        self.gameId = gameId
        self.summary = summary
        _viewModel = StateObject(wrappedValue: GameDetailViewModel(gameId: gameId))
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18, pinnedViews: []) {
                    if let detail = viewModel.detail {
                        GameHeaderView(game: detail.game)
                        PlayByPlaySection(plays: detail.plays)
                        PlayerStatsSection(detail: detail)
                        TeamStatsSection(detail: detail)
                        BoxScoreSection(game: detail.game)
                    } else if viewModel.loading {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 240)
                    } else if let error = viewModel.errorMessage {
                        ContentUnavailableView(
                            "Unable to load game",
                            systemImage: "wifi.exclamationmark",
                            description: Text(error)
                        )
                        .padding(.top, 80)
                    } else if let summary {
                        GameHeaderPlaceholder(summary: summary)
                    }

                    Color.clear
                        .frame(height: 1)
                        .id(bottomAnchorID)
                }
                .padding()
                .padding(.top, 28)
                .padding(.bottom, pinToBottom ? 48 : 0)
            }
            .overlay(alignment: .bottomTrailing) {
                if pinToBottom {
                    PinIndicator()
                        .padding()
                }
            }
            .onChange(of: viewModel.updateToken) { _, _ in
                guard pinToBottom else { return }
                scrollToBottom(proxy)
            }
            .onChange(of: pinToBottom) { _, pinned in
                guard pinned else { return }
                scrollToBottom(proxy)
            }
        }
        .navigationTitle("Catch Up")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard !AppEnvironment.isRunningTests else { return }
            await viewModel.refresh()
            viewModel.startAutoRefresh()
        }
        .onDisappear {
            viewModel.stopAutoRefresh()
        }
        .refreshable {
            await viewModel.refresh()
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    pinToBottom.toggle()
                } label: {
                    Image(systemName: pinToBottom ? "pin.fill" : "pin")
                }
                .accessibilityLabel(pinToBottom ? "Unpin from bottom" : "Pin to bottom")

                Button {
                    Task { await viewModel.refresh() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        DispatchQueue.main.async {
            withAnimation(.snappy(duration: 0.35)) {
                proxy.scrollTo(bottomAnchorID, anchor: .bottom)
            }
        }
    }
}

private struct PinIndicator: View {
    var body: some View {
        Label("Pinned", systemImage: "pin.fill")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.vertical, 7)
            .padding(.horizontal, 10)
            .background(Color(.systemTeal), in: Capsule())
            .shadow(radius: 8, y: 3)
    }
}

private struct GameHeaderView: View {
    let game: Game

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(leagueColor)
                .frame(width: 4)
                .padding(.vertical, 3)

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Text(game.leagueCode.uppercased())
                        .font(.caption.weight(.black))
                        .foregroundStyle(leagueColor)
                    Text(DateFormatters.shortTime.string(from: game.gameDate))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    if game.isLiveGame {
                        Text("LIVE")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.vertical, 3)
                            .padding(.horizontal, 7)
                            .background(Color(.systemRed), in: Capsule())
                    }
                    Spacer()
                }

                DetailTeamLine(abbreviation: game.awayTeamAbbr, name: game.awayTeam)
                DetailTeamLine(abbreviation: game.homeTeamAbbr, name: game.homeTeam)

                if let progressText {
                    Text(progressText)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(game.isLiveGame ? leagueColor : .secondary)
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground).opacity(0.86), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(leagueColor.opacity(0.18), lineWidth: 1)
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var progressText: String? {
        if game.isLiveGame {
            return [game.currentPeriodLabel, game.gameClock].compactMap { $0 }.joined(separator: " ").nilIfEmpty ?? "In progress"
        }
        if game.isPregame {
            return "Scheduled"
        }
        return "Catch up"
    }

    private var leagueColor: Color {
        switch game.leagueCode.uppercased() {
        case "MLB": return Color(.systemGreen)
        case "NBA": return Color(.systemOrange)
        case "NHL": return Color(.systemTeal)
        case "NFL": return Color(.systemIndigo)
        case "NCAAB": return Color(.systemPurple)
        case "NCAAF": return Color(.systemBrown)
        default: return Color(.systemBlue)
        }
    }
}

private struct DetailTeamLine: View {
    let abbreviation: String?
    let name: String

    var body: some View {
        HStack(spacing: 8) {
            Text(abbreviation ?? shortName)
                .font(.subheadline.weight(.black))
                .monospaced()
                .frame(width: 44, alignment: .leading)
            Text(name)
                .font(.title3.weight(.bold))
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
    }

    private var shortName: String {
        String(name.split(separator: " ").last?.prefix(4) ?? "TEAM")
    }
}

private struct GameHeaderPlaceholder: View {
    let summary: GameSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(summary.leagueCode.uppercased())
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.green)
            }
            Text(summary.matchupText)
                .font(.largeTitle.weight(.bold))
            Text(DateFormatters.shortTime.string(from: summary.gameDate))
                .foregroundStyle(.secondary)
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
