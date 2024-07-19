//
//  findIconUITests.swift
//  findIconUITests
//
//  Created by Diana Tsarkova on 19.07.2024.
//

import XCTest

final class findIconUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        app.launch()
    }

    func testStart() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()
        let searchTextField = app.textFields[.findIcon]
        let searchButton = app.buttons[.find]
        XCTAssert(searchButton.exists)
        XCTAssert(searchTextField.exists)
    }

    func testSearch() {
        let searchTextField = app.textFields[.findIcon]
        searchTextField.tap()
        searchTextField.typeText("arrow")
        let searchButton = app.buttons[.find]
        searchButton.tap()
        let tableView = app.tables["IconTableView"]
        XCTAssertTrue(tableView.waitForExistence(timeout: 5), "Table view does not exist")
        let cell = tableView.cells.element(boundBy: 0)
        let favImage = cell.images["iconImage"]
        XCTAssert(favImage.exists)
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
