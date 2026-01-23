import SwiftUI

/// Expandable card view for a story section - shows beat type, header, and notes
struct StorySectionCardView: View {
    let section: SectionEntry
    let plays: [UnifiedTimelineEvent]
    let homeTeam: String
    let awayTeam: String
    @Binding var isExpanded: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header (always visible, tappable)
            Button(action: toggleExpansion) {
                headerContent
            }
            .buttonStyle(.plain)

            // Expanded content
            if isExpanded {
                expandedContent
                    .transition(.opacity)
            }
        }
        .background(DesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.element))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.element)
                .stroke(DesignSystem.borderColor.opacity(0.3), lineWidth: 0.5)
        )
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }

    // MARK: - Header Content

    private var headerContent: some View {
        HStack(alignment: .center, spacing: 12) {
            // Left edge accent (only for highlight beat types)
            if section.isHighlight {
                RoundedRectangle(cornerRadius: 2)
                    .fill(DesignSystem.Colors.accent)
                    .frame(width: 3)
            }

            VStack(alignment: .leading, spacing: 4) {
                // Primary: Header text (deterministic anchor)
                Text(section.header)
                    .font(.subheadline.weight(section.isHighlight ? .semibold : .regular))
                    .foregroundColor(DesignSystem.TextColor.primary)
                    .lineLimit(2)

                // Secondary: Beat type badge + score
                HStack(spacing: 6) {
                    beatTypeBadge

                    Text("·")
                        .font(.caption)
                        .foregroundColor(DesignSystem.TextColor.tertiary)

                    scoreLabel
                }

                // Tertiary: First note preview (collapsed only)
                if !section.notes.isEmpty && !isExpanded {
                    Text(section.notes.first ?? "")
                        .font(.caption2)
                        .foregroundColor(DesignSystem.TextColor.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Right: Expansion indicator
            Image(systemName: "chevron.right")
                .font(.caption.weight(.medium))
                .foregroundColor(DesignSystem.TextColor.tertiary)
                .rotationEffect(.degrees(isExpanded ? 90 : 0))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, section.isHighlight ? 8 : 12)
        .contentShape(Rectangle())
    }

    // MARK: - Expanded Content

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
                .padding(.horizontal, 12)

            // Notes list
            if !section.notes.isEmpty {
                notesSection
                    .padding(.horizontal, 12)
            }

            // Plays list
            if !plays.isEmpty {
                VStack(spacing: 8) {
                    ForEach(plays) { event in
                        UnifiedTimelineRowView(
                            event: event,
                            homeTeam: homeTeam,
                            awayTeam: awayTeam
                        )
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
        }
    }

    // MARK: - Helper Views

    private var beatTypeBadge: some View {
        HStack(spacing: 3) {
            Image(systemName: section.beatType.iconName)
                .font(.system(size: 9))
            Text(section.beatType.displayName)
                .font(.caption)
        }
        .foregroundColor(section.isHighlight ? DesignSystem.Colors.accent : DesignSystem.TextColor.tertiary)
    }

    private var scoreLabel: some View {
        HStack(spacing: 4) {
            Text("\(section.startScore.away)-\(section.startScore.home)")
                .font(.caption.monospacedDigit())
                .foregroundColor(DesignSystem.TextColor.tertiary)

            Image(systemName: "arrow.right")
                .font(.system(size: 8))
                .foregroundColor(DesignSystem.TextColor.tertiary)

            Text("\(section.endScore.away)-\(section.endScore.home)")
                .font(.caption.weight(.medium).monospacedDigit())
                .foregroundColor(DesignSystem.TextColor.secondary)
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(section.notes, id: \.self) { note in
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 4))
                        .foregroundColor(DesignSystem.TextColor.tertiary)
                        .padding(.top, 5)

                    Text(note)
                        .font(.caption)
                        .foregroundColor(DesignSystem.TextColor.secondary)
                }
            }
        }
    }

    // MARK: - Actions

    private func toggleExpansion() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isExpanded.toggle()
        }
    }
}

// MARK: - Previews

#Preview("Highlight - Scoring Run") {
    StorySectionCardView(
        section: SectionEntry(
            sectionIndex: 0,
            beatType: .run,
            header: "Thunder go on a 12-0 run to take control.",
            chaptersIncluded: ["ch_001", "ch_002"],
            startScore: ScoreSnapshot(home: 45, away: 42),
            endScore: ScoreSnapshot(home: 57, away: 42),
            notes: ["SGA scores 8 straight", "Spurs call timeout"]
        ),
        plays: [],
        homeTeam: "Thunder",
        awayTeam: "Spurs",
        isExpanded: .constant(false)
    )
    .padding()
}

#Preview("Normal - Back and Forth") {
    StorySectionCardView(
        section: SectionEntry(
            sectionIndex: 1,
            beatType: .backAndForth,
            header: "Teams trade baskets in competitive stretch.",
            chaptersIncluded: ["ch_003"],
            startScore: ScoreSnapshot(home: 57, away: 42),
            endScore: ScoreSnapshot(home: 65, away: 58),
            notes: ["3 lead changes", "Spurs respond"]
        ),
        plays: [],
        homeTeam: "Thunder",
        awayTeam: "Spurs",
        isExpanded: .constant(false)
    )
    .padding()
}

#Preview("Expanded - Closing Sequence") {
    StorySectionCardView(
        section: SectionEntry(
            sectionIndex: 2,
            beatType: .closingSequence,
            header: "Thunder close out the game in final minutes.",
            chaptersIncluded: ["ch_004", "ch_005"],
            startScore: ScoreSnapshot(home: 98, away: 92),
            endScore: ScoreSnapshot(home: 112, away: 105),
            notes: ["Final: 112-105", "SGA with 32 points"]
        ),
        plays: [],
        homeTeam: "Thunder",
        awayTeam: "Spurs",
        isExpanded: .constant(true)
    )
    .padding()
}

#Preview("Crunch Time Setup") {
    StorySectionCardView(
        section: SectionEntry(
            sectionIndex: 3,
            beatType: .crunchSetup,
            header: "Game tightens in the final five minutes.",
            chaptersIncluded: ["ch_006"],
            startScore: ScoreSnapshot(home: 88, away: 85),
            endScore: ScoreSnapshot(home: 95, away: 92),
            notes: ["Within 3 points", "Both teams in bonus"]
        ),
        plays: [],
        homeTeam: "Thunder",
        awayTeam: "Spurs",
        isExpanded: .constant(false)
    )
    .padding()
}
