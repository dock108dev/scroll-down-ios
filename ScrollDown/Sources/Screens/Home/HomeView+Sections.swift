import SwiftUI
import UIKit

// MARK: - Section Rendering

extension HomeView {

    @ViewBuilder
    func sectionHeader(for section: HomeSectionState, isExpanded: Binding<Bool>) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if section.title != HomeStrings.sectionEarlier {
                Divider()
                    .padding(.horizontal, horizontalPadding)
                    .padding(.bottom, HomeLayout.sectionDividerPadding)
            }

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.wrappedValue.toggle()
                }
            } label: {
                HStack {
                    Text(section.title.uppercased())
                        .font(.caption.weight(.bold))
                        .foregroundColor(Color(.secondaryLabel))
                        .tracking(0.8)

                    if !isExpanded.wrappedValue && !section.isLoading && !section.games.isEmpty {
                        let filteredCount: Int = {
                            let query = searchText.trimmingCharacters(in: .whitespaces)
                            guard !query.isEmpty else { return section.games.count }
                            return section.games.filter { game in
                                game.homeTeam.localizedCaseInsensitiveContains(query)
                                || game.awayTeam.localizedCaseInsensitiveContains(query)
                                || (game.homeTeamAbbr?.localizedCaseInsensitiveContains(query) == true)
                                || (game.awayTeamAbbr?.localizedCaseInsensitiveContains(query) == true)
                            }.count
                        }()
                        let readCount = section.readCount(using: readStateStore)
                        Text(readCount > 0
                             ? "\(filteredCount) games \u{00B7} \(readCount) read"
                             : "\(filteredCount) games")
                            .font(.caption2)
                            .foregroundColor(Color(.tertiaryLabel))
                    }

                    Spacer()

                    Image(systemName: isExpanded.wrappedValue ? "chevron.up" : "chevron.down")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(Color(.secondaryLabel))
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.top, HomeLayout.sectionHeaderTopPadding(horizontalSizeClass))
                .padding(.bottom, horizontalSizeClass == .regular ? 6 : 8) // iPad: tighter bottom padding
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    func sectionContent(for section: HomeSectionState, completedOnly: Bool = false) -> some View {
        let gamesToShow: [GameSummary] = {
            let base = completedOnly ? section.completedGames : section.games
            let query = searchText.trimmingCharacters(in: .whitespaces)
            guard !query.isEmpty else { return base }
            return base.filter { game in
                game.homeTeam.localizedCaseInsensitiveContains(query)
                || game.awayTeam.localizedCaseInsensitiveContains(query)
                || (game.homeTeamAbbr?.localizedCaseInsensitiveContains(query) == true)
                || (game.awayTeamAbbr?.localizedCaseInsensitiveContains(query) == true)
            }
        }()

        if section.isLoading {
            // Minimal loading indicator - just a subtle spinner
            HStack {
                Spacer()
                ProgressView()
                    .scaleEffect(0.8)
                Spacer()
            }
            .padding(.vertical, HomeLayout.sectionStatePadding(horizontalSizeClass))
        } else if let error = section.errorMessage {
            EmptySectionView(text: sectionErrorMessage(for: section, error: error))
                .padding(.horizontal, HomeLayout.horizontalPadding)
                .padding(.vertical, HomeLayout.sectionStatePadding(horizontalSizeClass))
                .transition(.opacity)
        } else if gamesToShow.isEmpty {
            EmptySectionView(text: sectionEmptyMessage(for: section))
                .padding(.horizontal, HomeLayout.horizontalPadding)
                .padding(.vertical, HomeLayout.sectionStatePadding(horizontalSizeClass))
                .transition(.opacity)
        } else {
            // iPad: 4 columns, iPhone: 2 columns
            let columnCount = horizontalSizeClass == .regular ? 4 : 2
            let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: columnCount)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(gamesToShow) { game in
                    gameCard(for: game)
                }
            }
            .padding(.horizontal, horizontalPadding)
            .transition(.opacity.animation(.easeIn(duration: 0.2)))
        }
    }

    /// Game card with conditional navigation based on flow availability
    @ViewBuilder
    func gameCard(for game: GameSummary) -> some View {
        let rowView = GameRowView(game: game)

        if rowView.cardState.isTappable {
            // Flow available - enable navigation
            NavigationLink(value: AppRoute.game(id: game.id, league: game.league)) {
                rowView
            }
            .buttonStyle(CardPressButtonStyle())
            .simultaneousGesture(TapGesture().onEnded {
                GameRoutingLogger.logTap(gameId: game.id, league: game.league)
                triggerHapticIfNeeded(for: game)
            })
        } else {
            // Flow pending or upcoming - no navigation, static card
            rowView
                .allowsHitTesting(false)
        }
    }

    // MARK: - Section Messages

    func sectionEmptyMessage(for section: HomeSectionState) -> String {
        switch section.range {
        case .earlier:
            return HomeStrings.earlierEmpty
        case .yesterday:
            return HomeStrings.yesterdayEmpty
        case .current:
            return HomeStrings.todayEmpty
        case .tomorrow:
            return HomeStrings.tomorrowEmpty
        case .next24:
            return HomeStrings.upcomingEmpty
        }
    }

    func sectionErrorMessage(for section: HomeSectionState, error: String) -> String {
        switch section.range {
        case .earlier:
            return String(format: HomeStrings.earlierError, error)
        case .yesterday:
            return String(format: HomeStrings.yesterdayError, error)
        case .current:
            return String(format: HomeStrings.todayError, error)
        case .tomorrow:
            return String(format: HomeStrings.tomorrowError, error)
        case .next24:
            return String(format: HomeStrings.upcomingError, error)
        }
    }

    // MARK: - Feedback

    func triggerHapticIfNeeded(for game: GameSummary) {
        guard game.status?.isCompleted == true else { return }
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
    }
}
