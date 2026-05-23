import Foundation
import SwiftUI

enum AppEnvironment {
    static var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    static var uiTestFixtureName: String? {
        #if DEBUG
        ProcessInfo.processInfo.environment["SDS_UI_TEST_FIXTURE"]?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank
        #else
        nil
        #endif
    }

    static var isRunningUITests: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("--ui-testing") || uiTestFixtureName != nil
        #else
        false
        #endif
    }

    static var uiTestHomeInitialAnchor: String? {
        #if DEBUG
        ProcessInfo.processInfo.environment["SDS_HOME_INITIAL_ANCHOR"]?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank
        #else
        nil
        #endif
    }

    static var uiTestDynamicTypeSize: DynamicTypeSize? {
        #if DEBUG
        guard isRunningUITests else { return nil }
        let value = ProcessInfo.processInfo.environment["SDS_UI_TEST_DYNAMIC_TYPE"]?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        switch value {
        case "xsmall": return .xSmall
        case "small": return .small
        case "medium": return .medium
        case "large": return .large
        case "xlarge": return .xLarge
        case "xxlarge": return .xxLarge
        case "xxxlarge": return .xxxLarge
        case "accessibility1": return .accessibility1
        case "accessibility2": return .accessibility2
        case "accessibility3": return .accessibility3
        case "accessibility4": return .accessibility4
        case "accessibility5": return .accessibility5
        default: return nil
        }
        #else
        nil
        #endif
    }

    static var shouldResetStateForUITests: Bool {
        #if DEBUG
        guard isRunningUITests else { return false }
        let value = ProcessInfo.processInfo.environment["SDS_RESET_STATE"]?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        return value == "1" || value == "true" || value == "yes"
        #else
        false
        #endif
    }
}
