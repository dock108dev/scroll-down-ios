//
//  HomeView+FairBetHeader.swift
//  ScrollDown
//
//  FairBet tab header: explainer text, combined filter bar, controls row.
//

import SwiftUI

struct FairBetHeaderView: View {
    @ObservedObject var viewModel: OddsComparisonViewModel
    @Binding var selectedLeague: FairBetLeague?
    @Binding var selectedMarket: MarketFilter?
    let horizontalPadding: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Explainer
            Text("Bets with a FairBet estimate — compare prices and find value across books.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, horizontalPadding)
                .padding(.top, 4)

            // Combined filter bar: league pills, separator, market pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // League filters
                    oddsLeagueFilterButton(nil, label: HomeStrings.allLeaguesLabel)
                    ForEach(FairBetLeague.allCases) { league in
                        oddsLeagueFilterButton(league, label: league.rawValue)
                    }

                    // Separator
                    Rectangle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: 1, height: 20)

                    // Market filters
                    oddsMarketFilterButton(nil, label: "All")
                    ForEach(MarketKey.mainlineMarkets) { market in
                        oddsMarketFilterButton(.single(market), label: market.displayName)
                    }
                    oddsMarketFilterButton(.playerProps, label: "Player Props")
                    oddsMarketFilterButton(.teamProps, label: "Team Props")
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, HomeLayout.filterVerticalPadding)
            }
            .background(HomeTheme.background)

            // Controls row: search + sort + parlay + refresh
            HStack(spacing: 8) {
                // Search field
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    TextField("Search teams…", text: $viewModel.searchText)
                        .font(.subheadline)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    if !viewModel.searchText.isEmpty {
                        Button {
                            viewModel.searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                // Sort menu
                Menu {
                    ForEach(OddsComparisonViewModel.SortOption.allCases, id: \.self) { option in
                        Button {
                            viewModel.sortOption = option
                        } label: {
                            if viewModel.sortOption == option {
                                Label(option.rawValue, systemImage: "checkmark")
                            } else {
                                Text(option.rawValue)
                            }
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.secondary)
                        .frame(width: 32, height: 32)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // Parlay badge
                if viewModel.parlayCount > 0 {
                    Button {
                        if viewModel.canShowParlay {
                            viewModel.showParlaySheet = true
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "list.bullet.rectangle")
                                .font(.caption2)
                            Text("\(viewModel.parlayCount)")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundColor(viewModel.canShowParlay ? FairBetTheme.info : .secondary)
                        .frame(height: 32)
                        .padding(.horizontal, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(viewModel.canShowParlay ? FairBetTheme.info.opacity(0.12) : Color(.systemGray6))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(viewModel.canShowParlay ? FairBetTheme.info.opacity(0.6) : Color.clear, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!viewModel.canShowParlay)
                }

                // Refresh button
                Button {
                    Task { await viewModel.refresh() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.secondary)
                        .frame(width: 32, height: 32)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isLoading)
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.bottom, 6)
        }
    }

    // MARK: - Filter Buttons

    private func oddsLeagueFilterButton(_ league: FairBetLeague?, label: String) -> some View {
        Button(action: {
            selectedLeague = league
            viewModel.selectLeague(league)
        }) {
            Text(label)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, HomeLayout.filterHorizontalPadding)
                .padding(.vertical, HomeLayout.filterVerticalPadding)
                .background(selectedLeague == league ? HomeTheme.accentColor : Color(.systemGray5))
                .foregroundColor(selectedLeague == league ? .white : .primary)
                .clipShape(Capsule())
        }
    }

    private func oddsMarketFilterButton(_ filter: MarketFilter?, label: String) -> some View {
        Button(action: {
            selectedMarket = filter
            viewModel.selectedMarketFilter = filter
        }) {
            Text(label)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, HomeLayout.filterHorizontalPadding)
                .padding(.vertical, HomeLayout.filterVerticalPadding)
                .background(selectedMarket == filter ? HomeTheme.accentColor : Color(.systemGray5))
                .foregroundColor(selectedMarket == filter ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}
