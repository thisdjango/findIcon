//
//  findIconTests.swift
//  findIconTests
//
//  Created by Diana Tsarkova on 16.07.2024.
//

import XCTest

final class findIconTests: XCTestCase {

    func testExample() throws {
        let viewModel = SearchViewModel()
        XCTAssertNotNil(viewModel.tableViewModel, "Table view model not exists")
        XCTAssertNotNil(viewModel.tableViewModel.paginationHandler, "Bridge of pagination between table view model and search view model was ruined")
    }
    
    func testAPI() throws {
        let expect = expectation(description: "searchIconRequest")

        let viewModel = SearchViewModel()
        viewModel.tableViewModel.updateHandler = {
            expect.fulfill()
            XCTAssertEqual(viewModel.tableViewModel.iconModels.isEmpty, false)
        }
        viewModel.searchIcon(text: "arrow")
        wait(for: [expect], timeout: 5)
    }

    func testPerformanceExample() throws {
        measure(metrics: [XCTCPUMetric(), XCTClockMetric(), XCTMemoryMetric()]) {
            let viewModel = SearchViewModel()
            viewModel.searchIcon(text: "arrow")
        }
    }

}
