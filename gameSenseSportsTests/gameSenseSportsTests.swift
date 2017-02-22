//
//  gameSenseSportsTests.swift
//  gameSenseSportsTests
//
//  Created by Ra on 11/15/16.
//  Copyright © 2016 gameSenseSports. All rights reserved.
//

import XCTest

@testable import gameSenseSports

class gameSenseSportsTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testDrillListParser() {
        let jsonString = JsonTestString.readJsonFile(fileName: "drillList", bundle: Bundle(for: type(of: self)))
        let data = jsonString.data(using: String.Encoding.utf8, allowLossyConversion: false)!
        let json = try? JSONSerialization.jsonObject(with: data, options: [])
        if let dictionary = json as? [String: Any] {
            let drillListItem = DrillListItem(json: dictionary)
            let expectedID = 224
            let expectedCount = 72
            XCTAssert(drillListItem?.drillID == expectedID)
            XCTAssert(drillListItem?.questionCount == expectedCount)
        }
        else
        {
            XCTAssert(false)
        }
    }

    func testDrillQuestionParser() {
        let expectedRecordCount = 72
        let drillQuestionsJsonString = JsonTestString.readJsonFile(fileName: "drillQuestions", bundle: Bundle(for: type(of: self)))
        let drillQuestionsParser = DrillQuestionParser(jsonString: drillQuestionsJsonString)
        let drillQuestionArray = drillQuestionsParser?.getDrillQuestionArray()
        XCTAssert(expectedRecordCount == drillQuestionArray?.count)
        XCTAssert(expectedRecordCount == drillQuestionsParser?.recordCount)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
