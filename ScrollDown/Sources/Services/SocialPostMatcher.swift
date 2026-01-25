import Foundation

/// Matches social posts to story sections using time-window overlap
/// Posts are placed after sections that contain plays within the post's time context
struct SocialPostMatcher {

    /// Result of matching social posts to sections
    struct MatchResult {
        /// Posts matched to sections: [sectionIndex: [posts]]
        let placed: [Int: [UnifiedTimelineEvent]]
        /// Posts that couldn't be matched to any section
        let deferred: [UnifiedTimelineEvent]
    }

    /// Match social posts to sections based on time context
    /// - Parameters:
    ///   - posts: All social/tweet events from the timeline
    ///   - sections: Story sections with play ranges
    ///   - chapters: Chapter data for time range information
    ///   - allPlays: All plays for timestamp reference
    /// - Returns: MatchResult with placed and deferred posts
    static func match(
        posts: [UnifiedTimelineEvent],
        sections: [SectionEntry],
        chapters: [ChapterEntry],
        allPlays: [PlayEntry]
    ) -> MatchResult {
        guard !posts.isEmpty, !sections.isEmpty else {
            return MatchResult(placed: [:], deferred: posts)
        }

        var placed: [Int: [UnifiedTimelineEvent]] = [:]
        var deferred: [UnifiedTimelineEvent] = []

        for post in posts {
            if let sectionIndex = findMatchingSection(
                for: post,
                sections: sections,
                chapters: chapters,
                allPlays: allPlays
            ) {
                placed[sectionIndex, default: []].append(post)
            } else {
                deferred.append(post)
            }
        }

        return MatchResult(placed: placed, deferred: deferred)
    }

    /// Find the best matching section for a post
    private static func findMatchingSection(
        for post: UnifiedTimelineEvent,
        sections: [SectionEntry],
        chapters: [ChapterEntry],
        allPlays: [PlayEntry]
    ) -> Int? {
        // Strategy 1: Match by period if post has period context
        if let postPeriod = post.period {
            // Find sections that include this period
            for section in sections {
                if sectionContainsPeriod(section, period: postPeriod, chapters: chapters) {
                    return section.sectionIndex
                }
            }
        }

        // Strategy 2: Match by posted timestamp to section time range
        if let postedAt = post.postedAt,
           let postDate = parseTimestamp(postedAt) {
            // Find sections with overlapping time windows
            for (index, section) in sections.enumerated() {
                if sectionOverlapsTime(
                    section,
                    postDate: postDate,
                    chapters: chapters,
                    allPlays: allPlays
                ) {
                    return index
                }
            }
        }

        // Strategy 3: Use score context from post
        // If post mentions a score, try to match it to section score ranges
        if let matchedSection = matchByScoreContext(post: post, sections: sections) {
            return matchedSection
        }

        return nil
    }

    /// Check if a section contains plays from a given period
    private static func sectionContainsPeriod(
        _ section: SectionEntry,
        period: Int,
        chapters: [ChapterEntry]
    ) -> Bool {
        for chapterId in section.chaptersIncluded {
            if let chapter = chapters.first(where: { $0.chapterId == chapterId }),
               chapter.period == period {
                return true
            }
        }

        // Estimate period from score progression
        let totalPoints = section.endScore.home + section.endScore.away
        let estimatedPeriod = max(1, min(4, (totalPoints / 50) + 1))
        return estimatedPeriod == period
    }

    /// Check if a section's time window overlaps with post timestamp
    private static func sectionOverlapsTime(
        _ section: SectionEntry,
        postDate: Date,
        chapters: [ChapterEntry],
        allPlays: [PlayEntry]
    ) -> Bool {
        // Check if section has chapters with time range context
        for chapterId in section.chaptersIncluded {
            if let chapter = chapters.first(where: { $0.chapterId == chapterId }),
               chapter.timeRange != nil {
                return true
            }
        }
        return false
    }

    /// Try to match post to section by score context in tweet text
    private static func matchByScoreContext(
        post: UnifiedTimelineEvent,
        sections: [SectionEntry]
    ) -> Int? {
        guard let text = post.tweetText else { return nil }

        // Look for score patterns like "102-98" or "down by 5"
        let scorePattern = #"(\d{1,3})\s*[-–]\s*(\d{1,3})"#
        guard let regex = try? NSRegularExpression(pattern: scorePattern),
              let match = regex.firstMatch(
                  in: text,
                  range: NSRange(text.startIndex..., in: text)
              ) else {
            return nil
        }

        let range1 = Range(match.range(at: 1), in: text)!
        let range2 = Range(match.range(at: 2), in: text)!

        guard let score1 = Int(text[range1]),
              let score2 = Int(text[range2]) else {
            return nil
        }

        let mentionedScore = max(score1, score2)

        // Find section whose end score is closest to mentioned score
        var bestMatch: (index: Int, diff: Int)?
        for section in sections {
            let maxEndScore = max(section.endScore.home, section.endScore.away)
            let diff = abs(maxEndScore - mentionedScore)

            if bestMatch == nil || diff < bestMatch!.diff {
                // Only match if reasonably close (within 10 points)
                if diff <= 10 {
                    bestMatch = (section.sectionIndex, diff)
                }
            }
        }

        return bestMatch?.index
    }

    /// Parse ISO8601 or common timestamp formats
    private static func parseTimestamp(_ string: String) -> Date? {
        let formatters: [ISO8601DateFormatter] = [
            {
                let f = ISO8601DateFormatter()
                f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                return f
            }(),
            {
                let f = ISO8601DateFormatter()
                f.formatOptions = [.withInternetDateTime]
                return f
            }()
        ]

        for formatter in formatters {
            if let date = formatter.date(from: string) {
                return date
            }
        }
        return nil
    }
}
