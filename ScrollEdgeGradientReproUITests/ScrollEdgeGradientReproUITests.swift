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

        XCTAssertTrue(app.navigationBars["Color Under Glass"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.cells["experiment.hero.0"].exists)

        let collection = app.collectionViews["research.collection.0"]
        XCTAssertTrue(collection.exists)
        collection.swipeUp()
        XCTAssertTrue(collection.exists)
        XCTAssertTrue(app.navigationBars["Color Under Glass"].exists)
    }

    @MainActor
    func testOnePassControlIsASeparateTab() throws {
        let app = XCUIApplication()
        app.launch()

        let onePassTab = app.tabBars.buttons["One-pass"]
        XCTAssertTrue(onePassTab.waitForExistence(timeout: 5))
        onePassTab.tap()
        XCTAssertTrue(app.navigationBars["One-pass Composite"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.cells["experiment.hero.1"].exists)
        XCTAssertTrue(app.cells["one-pass.specimen"].exists)
    }
}
