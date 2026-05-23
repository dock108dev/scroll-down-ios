import Foundation
import XCTest
@testable import ScrollDownSports

enum JSONFixtureError: Error, Equatable {
    case missing(String)
    case invalidPath(String)
    case invalidPayload(String)
}

enum JSONFixture {
    static func data(
        _ name: String,
        extension fileExtension: String = "json",
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> Data {
        let url = try url(name, extension: fileExtension, file: file, line: line)
        return try Data(contentsOf: url)
    }

    static func decode<T: Decodable>(
        _ type: T.Type,
        from name: String,
        decoder: JSONDecoder = .sda,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> T {
        try decoder.decode(type, from: try data(name, file: file, line: line))
    }

    private static func url(
        _ name: String,
        extension fileExtension: String,
        file: StaticString,
        line: UInt
    ) throws -> URL {
        let normalized = name.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard !normalized.isEmpty else {
            XCTFail("Fixture path cannot be empty", file: file, line: line)
            throw JSONFixtureError.invalidPath(name)
        }

        let nsPath = normalized as NSString
        let directory = nsPath.deletingLastPathComponent
        let resourceName = nsPath.lastPathComponent
        let bundle = Bundle(for: JSONFixtureBundleToken.self)

        if let nestedURL = bundle.url(
            forResource: resourceName,
            withExtension: fileExtension,
            subdirectory: directory.isEmpty ? nil : directory
        ) {
            return nestedURL
        }

        if let flatURL = bundle.url(forResource: resourceName, withExtension: fileExtension) {
            return flatURL
        }

        XCTFail("Missing fixture: \(normalized).\(fileExtension)", file: file, line: line)
        throw JSONFixtureError.missing("\(normalized).\(fileExtension)")
    }
}

enum SDAFixtures {
    static func gameList(_ name: String, file: StaticString = #filePath, line: UInt = #line) throws -> Data {
        try JSONFixture.data("api/v2/game-list/\(name)", file: file, line: line)
    }

    static func gameDetail(_ name: String, file: StaticString = #filePath, line: UInt = #line) throws -> Data {
        try JSONFixture.data("api/v2/game-detail/\(name)", file: file, line: line)
    }

    static func presentation(_ name: String, file: StaticString = #filePath, line: UInt = #line) throws -> Data {
        try JSONFixture.data("api/v2/presentation/\(name)", file: file, line: line)
    }

    static func scoreboard(_ name: String, file: StaticString = #filePath, line: UInt = #line) throws -> Data {
        try JSONFixture.data("api/v2/scoreboard/\(name)", file: file, line: line)
    }

    static func malformed(_ name: String, file: StaticString = #filePath, line: UInt = #line) throws -> Data {
        try JSONFixture.data("api/v2/malformed/\(name)", file: file, line: line)
    }
}

extension MockHTTPResponse {
    static func fixture(_ name: String) throws -> MockHTTPResponse {
        .ok(try JSONFixture.data(name))
    }

    static func gameList(_ name: String) throws -> MockHTTPResponse {
        .ok(try SDAFixtures.gameList(name))
    }

    static func gameDetail(_ name: String) throws -> MockHTTPResponse {
        .ok(try SDAFixtures.gameDetail(name))
    }
}

private final class JSONFixtureBundleToken {}

