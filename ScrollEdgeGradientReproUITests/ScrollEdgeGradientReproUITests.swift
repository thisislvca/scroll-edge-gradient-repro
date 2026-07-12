import XCTest

final class ScrollEdgeGradientReproUITests: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testSummaryScrollsThroughFiniteGradientDemo() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.navigationBars["Summary"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.cells["mode.card"].exists)
        XCTAssertTrue(app.buttons["mode.menu"].exists)

        let collection = app.collectionViews["research.collection"]
        XCTAssertTrue(collection.exists)
        collection.swipeUp()
        XCTAssertTrue(app.staticTexts["Trends"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testFlattenedBaselineCanLaunchDirectly() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--flattened"]
        app.launch()

        XCTAssertTrue(app.staticTexts["FLATTENED BASELINE"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Gradient Architecture"].exists)
        XCTAssertTrue(app.staticTexts["Pinned"].exists)
    }
}
