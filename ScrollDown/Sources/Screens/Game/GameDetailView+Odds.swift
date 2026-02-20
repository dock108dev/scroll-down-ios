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
            } else if selectedOddsCategory == .playerProp {
                oddsGroupedPlayerPropTable(markets: markets, books: books)
            } else if selectedOddsCategory == .mainline {
                oddsGroupedMainlineTable(markets: markets, books: books)
            } else if selectedOddsCategory == .teamProp {
                oddsGroupedTeamPropTable(markets: markets, books: books)
            } else if selectedOddsCategory == .alternate {
                oddsGroupedAlternateTable(markets: markets, books: books)
            } else {
                oddsSortedFlatTable(markets: markets, books: books)
            }
        }
    }

    // MARK: - Grouped Mainline Table (Moneyline / Spread / Total sections)

    private func oddsGroupedMainlineTable(markets: [GameDetailViewModel.OddsMarketKey], books: [String]) -> some View {
        let groups = groupMainlineMarkets(markets)

        return VStack(spacing: 0) {
            ForEach(Array(groups.enumerated()), id: \.offset) { gIdx, group in
                oddsCollapsibleGroup(
                    title: group.title,
                    markets: group.markets,
                    books: books,
                    showHeader: gIdx == 0
                )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.element))
    }

    /// Groups mainline markets into Moneyline, Spread, Total — sorted logically within each
    private func groupMainlineMarkets(_ markets: [GameDetailViewModel.OddsMarketKey]) -> [(title: String, markets: [GameDetailViewModel.OddsMarketKey])] {
        var moneyline: [GameDetailViewModel.OddsMarketKey] = []
        var spread: [GameDetailViewModel.OddsMarketKey] = []
        var total: [GameDetailViewModel.OddsMarketKey] = []
        var other: [GameDetailViewModel.OddsMarketKey] = []

        for market in markets {
            switch market.marketType {
            case .moneyline: moneyline.append(market)
            case .spread: spread.append(market)
            case .total: total.append(market)
            default: other.append(market)
            }
        }

        // Sort spreads: group by absolute line, then home/away
        spread.sort { a, b in
            let aLine = abs(a.line ?? 0)
            let bLine = abs(b.line ?? 0)
            if aLine != bLine { return aLine < bLine }
            return (a.side ?? "") < (b.side ?? "")
        }

        // Sort totals: group by line, over before under
        total.sort { a, b in
            let aLine = a.line ?? 0
            let bLine = b.line ?? 0
            if aLine != bLine { return aLine < bLine }
            let aIsOver = a.side?.lowercased() == "over"
            let bIsOver = b.side?.lowercased() == "over"
            return aIsOver && !bIsOver
        }

        var groups: [(title: String, markets: [GameDetailViewModel.OddsMarketKey])] = []
        if !moneyline.isEmpty { groups.append(("Moneyline", moneyline)) }
        if !spread.isEmpty { groups.append(("Spread", spread)) }
        if !total.isEmpty { groups.append(("Total", total)) }
        if !other.isEmpty { groups.append(("Other", other)) }
        return groups
    }

    // MARK: - Grouped Team Props Table

    private func oddsGroupedTeamPropTable(markets: [GameDetailViewModel.OddsMarketKey], books: [String]) -> some View {
        let groups = groupTeamPropMarkets(markets)

        return VStack(spacing: 0) {
            ForEach(Array(groups.enumerated()), id: \.offset) { gIdx, group in
                oddsCollapsibleGroup(
                    title: group.title,
                    markets: group.markets,
                    books: books,
                    showHeader: gIdx == 0
                )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.element))
    }

    /// Groups team props by team name (from description), sorted by line
    private func groupTeamPropMarkets(_ markets: [GameDetailViewModel.OddsMarketKey]) -> [(title: String, markets: [GameDetailViewModel.OddsMarketKey])] {
        var teamOrder: [String] = []
        var teamGroups: [String: [GameDetailViewModel.OddsMarketKey]] = [:]

        for market in markets {
            let team = market.description ?? "Team"
            if teamGroups[team] == nil {
                teamOrder.append(team)
                teamGroups[team] = []
            }
            teamGroups[team]!.append(market)
        }

        // Sort each team's markets by line, over before under
        for team in teamOrder {
            teamGroups[team]!.sort { a, b in
                let aLine = a.line ?? 0
                let bLine = b.line ?? 0
                if aLine != bLine { return aLine < bLine }
                let aIsOver = a.side?.lowercased() == "over"
                let bIsOver = b.side?.lowercased() == "over"
                return aIsOver && !bIsOver
            }
        }

        return teamOrder.map { team in
            (title: team, markets: teamGroups[team]!)
        }
    }

    // MARK: - Grouped Alternates Table (Alt Spread / Alt Total sections)

    private func oddsGroupedAlternateTable(markets: [GameDetailViewModel.OddsMarketKey], books: [String]) -> some View {
        let groups = groupAlternateMarkets(markets)

        return VStack(spacing: 0) {
            ForEach(Array(groups.enumerated()), id: \.offset) { gIdx, group in
                oddsCollapsibleGroup(
                    title: group.title,
                    markets: group.markets,
                    books: books,
                    showHeader: gIdx == 0
                )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.element))
    }

    /// Groups alternate markets by market type display name, sorted by line within each
    private func groupAlternateMarkets(_ markets: [GameDetailViewModel.OddsMarketKey]) -> [(title: String, markets: [GameDetailViewModel.OddsMarketKey])] {
        var typeOrder: [String] = []
        var typeGroups: [String: [GameDetailViewModel.OddsMarketKey]] = [:]

        for market in markets {
            let typeName = market.marketType.displayName
            if typeGroups[typeName] == nil {
                typeOrder.append(typeName)
                typeGroups[typeName] = []
            }
            typeGroups[typeName]!.append(market)
        }

        // Sort each group by line, then side (over before under)
        for typeName in typeOrder {
            typeGroups[typeName]!.sort { a, b in
                let aLine = a.line ?? 0
                let bLine = b.line ?? 0
                if aLine != bLine { return aLine < bLine }
                let aIsOver = a.side?.lowercased() == "over"
                let bIsOver = b.side?.lowercased() == "over"
                return aIsOver && !bIsOver
            }
        }

        return typeOrder.map { typeName in
            (title: typeName, markets: typeGroups[typeName]!)
        }
    }

    // MARK: - Sorted Flat Table (period, game props, etc.)

    private func oddsSortedFlatTable(markets: [GameDetailViewModel.OddsMarketKey], books: [String]) -> some View {
        let sorted = markets.sorted { a, b in
            // Sort by market type, then line, then side
            if a.marketType.rawValue != b.marketType.rawValue {
                return a.marketType.rawValue < b.marketType.rawValue
            }
            let aLine = a.line ?? 0
            let bLine = b.line ?? 0
            if aLine != bLine { return aLine < bLine }
            let aIsOver = a.side?.lowercased() == "over"
            let bIsOver = b.side?.lowercased() == "over"
            if aIsOver != bIsOver { return aIsOver }
            return (a.side ?? "") < (b.side ?? "")
        }
        return oddsFlatTable(markets: sorted, books: books)
    }

    // MARK: - Collapsible Group (shared by mainline, team props)

    private func oddsCollapsibleGroup(
        title: String,
        markets: [GameDetailViewModel.OddsMarketKey],
        books: [String],
        showHeader: Bool
    ) -> some View {
        let isCollapsed = collapsedOddsGroups.contains(title)

        return VStack(spacing: 0) {
            // Section header — tappable to collapse/expand
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if isCollapsed {
                        collapsedOddsGroups.remove(title)
                    } else {
                        collapsedOddsGroups.insert(title)
                    }
                }
            } label: {
                HStack {
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(DesignSystem.TextColor.secondary)
                        .textCase(.uppercase)
                    Spacer()
                    Text("\(markets.count)")
                        .font(.caption2)
                        .foregroundColor(DesignSystem.TextColor.tertiary)
                    Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                        .font(.caption2)
                        .foregroundColor(DesignSystem.TextColor.tertiary)
                }
                .padding(.horizontal, DesignSystem.Spacing.elementPadding)
                .padding(.vertical, 8)
                .background(DesignSystem.Colors.elevatedBackground)
            }
            .buttonStyle(.plain)

            if !isCollapsed {
                oddsTableRows(markets: markets, books: books, showBookHeader: showHeader || !collapsedOddsGroups.isEmpty)
            }
        }
    }

    // MARK: - Table Rows (shared renderer)

    private func oddsTableRows(
        markets: [GameDetailViewModel.OddsMarketKey],
        books: [String],
        showBookHeader: Bool
    ) -> some View {
        HStack(alignment: .top, spacing: 0) {
            // Frozen label column
            VStack(spacing: 0) {
                if showBookHeader {
                    // Matching header placeholder for alignment
                    Text("MARKET")
                        .font(DesignSystem.Typography.statLabel)
                        .foregroundColor(DesignSystem.TextColor.secondary)
                        .textCase(.uppercase)
                        .frame(width: 120, alignment: .leading)
                        .padding(.vertical, 8)
                        .padding(.leading, DesignSystem.Spacing.elementPadding)
                        .background(DesignSystem.Colors.elevatedBackground)
                }

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

            Rectangle()
                .fill(DesignSystem.borderColor)
                .frame(width: 1)

            // Scrollable book columns
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(spacing: 0) {
                    if showBookHeader {
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
                    }

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
    }

    // MARK: - Flat Odds Table (simple, no grouping)

    private func oddsFlatTable(markets: [GameDetailViewModel.OddsMarketKey], books: [String]) -> some View {
        oddsTableRows(markets: markets, books: books, showBookHeader: true)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.element))
    }

    // MARK: - Grouped Player Prop Table (collapsible per player)

    private func oddsGroupedPlayerPropTable(markets: [GameDetailViewModel.OddsMarketKey], books: [String]) -> some View {
        let grouped = viewModel.groupedPlayerPropMarkets(filtered: markets)

        return VStack(spacing: 12) {
            ForEach(Array(grouped.enumerated()), id: \.offset) { _, playerGroup in
                let collapseKey = "player-\(playerGroup.player)"
                let isCollapsed = collapsedOddsGroups.contains(collapseKey)
                let marketCount = playerGroup.statGroups.reduce(0) { $0 + $1.markets.count }

                VStack(spacing: 0) {
                    // Player name header — tappable to collapse/expand
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if isCollapsed {
                                collapsedOddsGroups.remove(collapseKey)
                            } else {
                                collapsedOddsGroups.insert(collapseKey)
                            }
                        }
                    } label: {
                        HStack {
                            Text(playerGroup.player)
                                .font(.subheadline.weight(.bold))
                                .foregroundColor(DesignSystem.TextColor.primary)
                            Spacer()
                            Text("\(marketCount)")
                                .font(.caption2)
                                .foregroundColor(DesignSystem.TextColor.tertiary)
                            Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                                .font(.caption2)
                                .foregroundColor(DesignSystem.TextColor.tertiary)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, DesignSystem.Spacing.elementPadding)
                        .background(DesignSystem.Colors.elevatedBackground)
                    }
                    .buttonStyle(.plain)

                    if !isCollapsed {
                        // Stat groups for this player
                        ForEach(Array(playerGroup.statGroups.enumerated()), id: \.offset) { sgIdx, statGroup in
                            // Stat type sub-header
                            if playerGroup.statGroups.count > 1 {
                                Text(statGroup.statType.uppercased())
                                    .font(.caption2.weight(.semibold))
                                    .foregroundColor(DesignSystem.TextColor.tertiary)
                                    .tracking(0.5)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, DesignSystem.Spacing.elementPadding)
                                    .background(DesignSystem.Colors.alternateRowBackground)
                            }

                            // Table rows with aligned header + data
                            oddsTableRows(
                                markets: statGroup.markets,
                                books: books,
                                showBookHeader: sgIdx == 0
                            )
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
