#!/usr/bin/env swift

import Foundation

struct CoveragePolicy: Decodable {
    let version: Int
    let targetName: String
    let reportPath: String
    let targetMinimumLineCoverage: Double
    let defaultFileMinimumLineCoverage: Double
    let tolerancePercentagePoints: Double
    let minimumImprovementPercentagePoints: Double
    let ratchetMilestones: [Double]?
    let excludedPathGlobs: [String]
    let includedPathOverrides: [String]
    let fileMinimumLineCoverageOverrides: [String: Double]
    let scenarioCoverageRequirements: [ScenarioCoverageRequirement]?
}

struct ScenarioCoverageRequirement: Decodable {
    let sourcePath: String
    let testPathGlobs: [String]
    let minimumMatchedFiles: Int?
}

struct CoverageFile {
    let path: String
    let coveredLines: Double?
    let executableLines: Double?
    let lineCoveragePercentage: Double?

    var hasExecutableLines: Bool {
        if let executableLines {
            return executableLines > 0
        }
        return lineCoveragePercentage != nil
    }

    var coveragePercentage: Double {
        if let coveredLines, let executableLines, executableLines > 0 {
            return coveredLines / executableLines * 100
        }
        return lineCoveragePercentage ?? 0
    }
}

struct Arguments {
    var reportPath: String?
    var configPath = "Config/coverage-thresholds.json"
    var repoRoot = FileManager.default.currentDirectoryPath
}

enum CoverageError: Error, CustomStringConvertible {
    case usage(String)
    case invalidJSON(String)
    case missingTarget(String)
    case emptyCoverage(String)
    case scenarioCoverage(String)

    var description: String {
        switch self {
        case .usage(let message),
             .invalidJSON(let message),
             .missingTarget(let message),
             .emptyCoverage(let message),
             .scenarioCoverage(let message):
            return message
        }
    }
}

func parseArguments(_ rawArguments: [String]) throws -> Arguments {
    var arguments = Arguments()
    var index = 0

    while index < rawArguments.count {
        let option = rawArguments[index]
        guard option.hasPrefix("--") else {
            throw CoverageError.usage("Unexpected argument: \(option)")
        }

        guard index + 1 < rawArguments.count else {
            throw CoverageError.usage("Missing value for \(option)")
        }

        let value = rawArguments[index + 1]
        switch option {
        case "--report":
            arguments.reportPath = value
        case "--config":
            arguments.configPath = value
        case "--repo-root":
            arguments.repoRoot = value
        default:
            throw CoverageError.usage("Unknown option: \(option)")
        }
        index += 2
    }

    return arguments
}

func loadJSONDictionary(path: String) throws -> [String: Any] {
    let data = try Data(contentsOf: URL(fileURLWithPath: path))
    let json = try JSONSerialization.jsonObject(with: data)
    guard let dictionary = json as? [String: Any] else {
        throw CoverageError.invalidJSON("Expected a JSON object at \(path)")
    }
    return dictionary
}

func loadPolicy(path: String) throws -> CoveragePolicy {
    let data = try Data(contentsOf: URL(fileURLWithPath: path))
    return try JSONDecoder().decode(CoveragePolicy.self, from: data)
}

func doubleValue(_ value: Any?) -> Double? {
    switch value {
    case let value as Double:
        return value
    case let value as Int:
        return Double(value)
    case let value as NSNumber:
        return value.doubleValue
    case let value as String:
        return Double(value)
    default:
        return nil
    }
}

func stringValue(_ value: Any?) -> String? {
    switch value {
    case let value as String:
        return value
    default:
        return nil
    }
}

func percentageValue(_ value: Any?) -> Double? {
    guard let number = doubleValue(value) else {
        return nil
    }
    return number <= 1 ? number * 100 : number
}

func normalizePath(_ rawPath: String, repoRoot: String) -> String {
    var path = rawPath.replacingOccurrences(of: "\\", with: "/")
    let normalizedRoot = repoRoot.replacingOccurrences(of: "\\", with: "/").trimmingCharacters(in: CharacterSet(charactersIn: "/"))

    if path.hasPrefix(normalizedRoot + "/") {
        path.removeFirst(normalizedRoot.count + 1)
    } else {
        for marker in ["ScrollDownSports/", "ScrollDownSportsTests/", "Config/"] {
            if let range = path.range(of: marker) {
                path = String(path[range.lowerBound...])
                break
            }
        }
    }

    while path.contains("//") {
        path = path.replacingOccurrences(of: "//", with: "/")
    }

    if path.hasPrefix("./") {
        path.removeFirst(2)
    }
    return path
}

func componentMatches(_ pattern: String, _ value: String) -> Bool {
    var regex = "^"
    for character in pattern {
        switch character {
        case "*":
            regex += "[^/]*"
        case ".", "+", "?", "^", "$", "(", ")", "[", "]", "{", "}", "|", "\\":
            regex += "\\\(character)"
        default:
            regex.append(character)
        }
    }
    regex += "$"
    return value.range(of: regex, options: .regularExpression) != nil
}

func pathMatches(glob: String, path: String) -> Bool {
    let patternParts = glob.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
    let pathParts = path.split(separator: "/", omittingEmptySubsequences: false).map(String.init)

    func match(patternIndex: Int, pathIndex: Int) -> Bool {
        if patternIndex == patternParts.count {
            return pathIndex == pathParts.count
        }

        let pattern = patternParts[patternIndex]
        if pattern == "**" {
            if match(patternIndex: patternIndex + 1, pathIndex: pathIndex) {
                return true
            }
            if pathIndex < pathParts.count {
                return match(patternIndex: patternIndex, pathIndex: pathIndex + 1)
            }
            return false
        }

        guard pathIndex < pathParts.count else {
            return false
        }

        return componentMatches(pattern, pathParts[pathIndex])
            && match(patternIndex: patternIndex + 1, pathIndex: pathIndex + 1)
    }

    return match(patternIndex: 0, pathIndex: 0)
}

func matchesAny(_ globs: [String], path: String) -> Bool {
    globs.contains { pathMatches(glob: $0, path: path) }
}

func coverageFiles(report: [String: Any], policy: CoveragePolicy, repoRoot: String) throws -> [CoverageFile] {
    guard let targets = report["targets"] as? [[String: Any]] else {
        throw CoverageError.invalidJSON("Coverage report does not contain a targets array")
    }

    guard let target = targets.first(where: { stringValue($0["name"]) == policy.targetName }) else {
        let names = targets.compactMap { stringValue($0["name"]) }.joined(separator: ", ")
        throw CoverageError.missingTarget("Could not find coverage target \(policy.targetName). Found: \(names)")
    }

    guard let rawFiles = target["files"] as? [[String: Any]] else {
        throw CoverageError.invalidJSON("Coverage target \(policy.targetName) does not contain a files array")
    }

    return rawFiles.compactMap { rawFile in
        guard let rawPath = stringValue(rawFile["path"]) ?? stringValue(rawFile["name"]) else {
            return nil
        }

        return CoverageFile(
            path: normalizePath(rawPath, repoRoot: repoRoot),
            coveredLines: doubleValue(rawFile["coveredLines"]),
            executableLines: doubleValue(rawFile["executableLines"]),
            lineCoveragePercentage: percentageValue(rawFile["lineCoverage"])
        )
    }
}

func threshold(for file: CoverageFile, policy: CoveragePolicy) -> Double {
    for (glob, threshold) in policy.fileMinimumLineCoverageOverrides where pathMatches(glob: glob, path: file.path) {
        return threshold
    }
    return policy.defaultFileMinimumLineCoverage
}

func roundedRatchetValue(measuredCoverage: Double, tolerance: Double) -> Double {
    floor((measuredCoverage - tolerance) * 10) / 10
}

func repositoryFiles(repoRoot: String) -> [String] {
    guard let enumerator = FileManager.default.enumerator(atPath: repoRoot) else {
        return []
    }

    let skippedDirectories: Set<String> = [".build", ".git", ".aidlc"]
    var files: [String] = []
    for entry in enumerator {
        guard let path = entry as? String else { continue }
        var isDirectory: ObjCBool = false
        let fullPath = URL(fileURLWithPath: repoRoot).appendingPathComponent(path).path
        guard FileManager.default.fileExists(atPath: fullPath, isDirectory: &isDirectory) else {
            continue
        }
        if isDirectory.boolValue {
            if skippedDirectories.contains(path.split(separator: "/").first.map(String.init) ?? "") {
                enumerator.skipDescendants()
            }
            continue
        }
        files.append(normalizePath(path, repoRoot: repoRoot))
    }
    return files
}

func validateScenarioCoverage(policy: CoveragePolicy, repoRoot: String) throws -> Int {
    guard let requirements = policy.scenarioCoverageRequirements, !requirements.isEmpty else {
        return 0
    }

    let files = repositoryFiles(repoRoot: repoRoot)
    var failures: [String] = []

    for requirement in requirements {
        let matchedFiles = files.filter { path in
            requirement.testPathGlobs.contains { pathMatches(glob: $0, path: path) }
        }
        let requiredCount = requirement.minimumMatchedFiles ?? 1
        if matchedFiles.count < requiredCount {
            failures.append(
                "\(requirement.sourcePath) matched \(matchedFiles.count)/\(requiredCount) scenario files for \(requirement.testPathGlobs.joined(separator: ", "))"
            )
        }
    }

    if !failures.isEmpty {
        throw CoverageError.scenarioCoverage("Scenario coverage failed:\n  \(failures.joined(separator: "\n  "))")
    }
    return requirements.count
}

func run() throws {
    let arguments = try parseArguments(Array(CommandLine.arguments.dropFirst()))
    let policy = try loadPolicy(path: arguments.configPath)
    let reportPath = arguments.reportPath ?? policy.reportPath
    let report = try loadJSONDictionary(path: reportPath)
    let scenarioRequirementCount = try validateScenarioCoverage(policy: policy, repoRoot: arguments.repoRoot)
    let files = try coverageFiles(report: report, policy: policy, repoRoot: arguments.repoRoot)

    var included: [CoverageFile] = []
    var excluded: [CoverageFile] = []

    for file in files where file.hasExecutableLines {
        let isOverrideIncluded = matchesAny(policy.includedPathOverrides, path: file.path)
        let isExcluded = matchesAny(policy.excludedPathGlobs, path: file.path) && !isOverrideIncluded
        if isExcluded {
            excluded.append(file)
        } else {
            included.append(file)
        }
    }

    guard !included.isEmpty else {
        throw CoverageError.emptyCoverage("Coverage report has no included executable files after filtering")
    }

    let coveredLines = included.compactMap(\.coveredLines).reduce(0, +)
    let executableLines = included.compactMap(\.executableLines).reduce(0, +)
    let aggregateCoverage: Double

    if executableLines > 0 {
        aggregateCoverage = coveredLines / executableLines * 100
    } else {
        aggregateCoverage = included.map(\.coveragePercentage).reduce(0, +) / Double(included.count)
    }

    var failures: [String] = []
    if aggregateCoverage + policy.tolerancePercentagePoints < policy.targetMinimumLineCoverage {
        let deficit = policy.targetMinimumLineCoverage - aggregateCoverage
        failures.append(
            String(
                format: "Project coverage %.2f%% is below threshold %.2f%% (delta -%.2fpp, %.2fpp tolerance).",
                aggregateCoverage,
                policy.targetMinimumLineCoverage,
                deficit,
                policy.tolerancePercentagePoints
            )
        )
    }

    let fileFailures = included.compactMap { file -> String? in
        let required = threshold(for: file, policy: policy)
        guard file.coveragePercentage + policy.tolerancePercentagePoints < required else {
            return nil
        }
        return String(
            format: "%@ %.2f%% < %.2f%% (delta -%.2fpp)",
            file.path,
            file.coveragePercentage,
            required,
            required - file.coveragePercentage
        )
    }.sorted()

    if !failures.isEmpty || !fileFailures.isEmpty {
        print("Coverage failed.")
        if !failures.isEmpty {
            print("")
            print("Project:")
            failures.forEach { print("  \($0)") }
        }
        if !fileFailures.isEmpty {
            print("")
            print("Files:")
            fileFailures.forEach { print("  \($0)") }
        }
        Foundation.exit(1)
    }

    print("Coverage passed.")
    print("Target: \(policy.targetName)")
    print(String(format: "Filtered line coverage: %.2f%% >= %.2f%%", aggregateCoverage, policy.targetMinimumLineCoverage))
    print("Included files: \(included.count)")
    print("Excluded files: \(excluded.count)")
    if scenarioRequirementCount > 0 {
        print("Scenario coverage requirements: \(scenarioRequirementCount)")
    }

    if let nextMilestone = policy.ratchetMilestones?.sorted().first(where: { $0 > policy.targetMinimumLineCoverage }) {
        let remaining = max(0, nextMilestone - aggregateCoverage)
        print(String(format: "Next milestone: %.2f%% (remaining %.2fpp)", nextMilestone, remaining))
    }

    if aggregateCoverage >= policy.targetMinimumLineCoverage + policy.minimumImprovementPercentagePoints {
        let suggested = roundedRatchetValue(
            measuredCoverage: aggregateCoverage,
            tolerance: policy.tolerancePercentagePoints
        )
        print(
            String(
                format: "Coverage can ratchet from %.2f%% to %.1f%%.",
                policy.targetMinimumLineCoverage,
                suggested
            )
        )
    }
}

do {
    try run()
} catch {
    fputs("Coverage check failed: \(error)\n", stderr)
    Foundation.exit(1)
}
