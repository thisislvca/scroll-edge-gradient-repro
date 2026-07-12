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
    func testSeparatedExperimentScrollsThroughTheExplainer() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.navigationBars["Scroll Edge Lab"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["The gradient remains visible"].exists)

        let scrollView = app.scrollViews["research.scroll.0"]
        XCTAssertTrue(scrollView.exists)
        scrollView.swipeUp()
        XCTAssertTrue(scrollView.exists)
        XCTAssertTrue(app.navigationBars["Scroll Edge Lab"].exists)
    }

    @MainActor
    func testInScrollControlIsASeparateTab() throws {
        let app = XCUIApplication()
        app.launch()

        let inScrollTab = app.tabBars.buttons["In-scroll"]
        XCTAssertTrue(inScrollTab.waitForExistence(timeout: 5))
        inScrollTab.tap()
        XCTAssertTrue(app.navigationBars["Scroll Edge Lab"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["The gradient shares the scroll source"].exists)
        XCTAssertTrue(app.scrollViews["research.scroll.1"].exists)
    }
}
