import SwiftUI

// MARK: - Odds Section Extension

extension GameDetailView {

    // MARK: - Odds Section (Tier 3: Supporting, collapsed by default)

    var oddsSection: some View {
        CollapsibleSectionCard(
            title: "Odds",
            isExpanded: $isOddsExpanded
        ) {
            oddsContent
        }
    }

    // MARK: - Odds Content

    @ViewBuilder
    private var oddsContent: some View {
        let categories = viewModel.availableOddsCategories
        let books = viewModel.oddsBooks

        if categories.isEmpty {
            EmptySectionView(text: "Odds data is not yet available.")
        } else {
            VStack(spacing: GameDetailLayout.listSpacing) {
                // Category tabs
                oddsCategoryTabs(categories)

                // Player search (only on Player Props tab)
                if selectedOddsCategory == .playerProp {
                    oddsPlayerSearchField
                }

                // Cross-book comparison table
                oddsCrossBookTable(books: books)
            }
            .onAppear {
                // Default to first available category if current selection has no data
                if !categories.contains(selectedOddsCategory), let first = categories.first {
                    selectedOddsCategory = first
                }
            }
        }
    }

    // MARK: - Category Tabs

    private func oddsCategoryTabs(_ categories: [MarketCategory]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories) { category in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedOddsCategory = category
                        }
                    } label: {
                        Text(category.displayTitle)
                            .font(DesignSystem.Typography.rowMeta.weight(.medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedOddsCategory == category ? GameTheme.accentColor : DesignSystem.Colors.elevatedBackground)
                            .foregroundColor(selectedOddsCategory == category ? .white : .primary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Player Search

    private var oddsPlayerSearchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.caption)
            TextField("Search players...", text: $oddsPlayerSearch)
                .font(.subheadline)
                .textFieldStyle(.plain)
            if !oddsPlayerSearch.isEmpty {
                Button {
                    oddsPlayerSearch = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(DesignSystem.Colors.elevatedBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.small))
    }

    // MARK: - Cross-Book Table

    private func oddsCrossBookTable(books: [String]) -> some View {
        let markets = filteredOddsMarkets

        return Group {
            if markets.isEmpty {
                Text("No odds available for this category.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            } else {
                HStack(alignment: .top, spacing: 0) {
                    // Frozen label column
                    VStack(spacing: 0) {
                        // Header
                        Text("Market")
                            .font(DesignSystem.Typography.statLabel)
                            .foregroundColor(DesignSystem.TextColor.secondary)
                            .textCase(.uppercase)
                            .frame(width: 120, alignment: .leading)
                            .padding(.vertical, 8)
                            .padding(.leading, DesignSystem.Spacing.elementPadding)
                            .background(DesignSystem.Colors.elevatedBackground)

                        // Market rows
                        ForEach(Array(markets.enumerated()), id: \.element.id) { index, market in
                            Text(market.displayLabel)
                                .font(DesignSystem.Typography.statValue)
                                .foregroundColor(DesignSystem.TextColor.primary)
                                .lineLimit(2)
                                .frame(width: 120, alignment: .leading)
                                .frame(height: 36)
                                .padding(.leading, DesignSystem.Spacing.elementPadding)
                                .background(index.isMultiple(of: 2) ? DesignSystem.Colors.alternateRowBackground : DesignSystem.Colors.rowBackground)
                                .overlay(alignment: .bottom) {
                                    if !index.isMultiple(of: 2) {
                                        Rectangle()
                                            .fill(DesignSystem.borderColor.opacity(0.4))
                                            .frame(height: DesignSystem.borderWidth)
                                    }
                                }
                        }
                    }

                    // Divider
                    Rectangle()
                        .fill(DesignSystem.borderColor)
                        .frame(width: 1)

                    // Scrollable book columns
                    ScrollView(.horizontal, showsIndicators: false) {
                        VStack(spacing: 0) {
                            // Book headers
                            HStack(spacing: 6) {
                                ForEach(books, id: \.self) { book in
                                    Text(BookNameHelper.abbreviated(book))
                                        .font(DesignSystem.Typography.statLabel)
                                        .foregroundColor(DesignSystem.TextColor.secondary)
                                        .textCase(.uppercase)
                                        .frame(width: 48)
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 8)
                            .background(DesignSystem.Colors.elevatedBackground)

                            // Data rows
                            ForEach(Array(markets.enumerated()), id: \.element.id) { index, market in
                                HStack(spacing: 6) {
                                    ForEach(books, id: \.self) { book in
                                        oddsPriceCell(for: market, book: book)
                                            .frame(width: 48)
                                    }
                                }
                                .frame(height: 36)
                                .padding(.horizontal, 8)
                                .background(index.isMultiple(of: 2) ? DesignSystem.Colors.alternateRowBackground : DesignSystem.Colors.rowBackground)
                                .overlay(alignment: .bottom) {
                                    if !index.isMultiple(of: 2) {
                                        Rectangle()
                                            .fill(DesignSystem.borderColor.opacity(0.4))
                                            .frame(height: DesignSystem.borderWidth)
                                    }
                                }
                            }
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.element))
            }
        }
    }

    // MARK: - Price Cell

    private func oddsPriceCell(for market: GameDetailViewModel.OddsMarketKey, book: String) -> some View {
        Group {
            if let price = viewModel.oddsPrice(for: market, book: book) {
                let intPrice = Int(price)
                Text(intPrice > 0 ? "+\(intPrice)" : "\(intPrice)")
                    .font(DesignSystem.Typography.statValue)
                    .fontWeight(.medium)
                    .foregroundColor(DesignSystem.TextColor.primary)
            } else {
                Text("--")
                    .font(DesignSystem.Typography.statValue)
                    .foregroundColor(DesignSystem.TextColor.secondary)
            }
        }
    }

    // MARK: - Filtered Markets

    private var filteredOddsMarkets: [GameDetailViewModel.OddsMarketKey] {
        var markets = viewModel.oddsMarkets(for: selectedOddsCategory)

        // Apply player search filter
        if selectedOddsCategory == .playerProp && !oddsPlayerSearch.isEmpty {
            let query = oddsPlayerSearch.lowercased()
            markets = markets.filter { market in
                market.playerName?.lowercased().contains(query) ?? false
            }
        }

        return markets
    }
}
