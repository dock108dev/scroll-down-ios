import SnapshotTesting
import UIKit
import XCTest

class SnapshotTestCase: XCTestCase {
    override func invokeTest() {
        withSnapshotTesting(record: SnapshotRecordMode.current) {
            super.invokeTest()
        }
    }

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        UIView.setAnimationsEnabled(false)
    }

    override func tearDown() {
        UIView.setAnimationsEnabled(true)
        super.tearDown()
    }
}

private enum SnapshotRecordMode {
    static var current: SnapshotTestingConfiguration.Record {
        ProcessInfo.processInfo.environment["SNAPSHOT_RECORD"] == "1" ? .all : .never
    }
}
