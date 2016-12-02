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
        let expectedRecordCount = 81
        let drillListJsonString = JsonTestString.readJsonFile(fileName: "drillList", bundle: Bundle(for: type(of: self)))
        let drillListParser = DrillListParser(jsonString: drillListJsonString)
        let drillListItemArray = drillListParser?.getDrillListArray()
        XCTAssert(expectedRecordCount == drillListItemArray?.count)
        XCTAssert(expectedRecordCount == drillListParser?.recordCount)
    }

    func testDrillQuestionParser() {
        let expectedRecordCount = 12
        let drillQuestionsJsonString = JsonTestString.readJsonFile(fileName: "drillQuestions", bundle: Bundle(for: type(of: self)))
        let drillQuestionsParser = DrillQuestionParser(jsonString: drillQuestionsJsonString)
        let drillQuestionArray = drillQuestionsParser?.getDrillQuestionArray()
        XCTAssert(expectedRecordCount == drillQuestionArray?.count)
        XCTAssert(expectedRecordCount == drillQuestionsParser?.recordCount)
    }
    
    func testDrillVideoParser()
    {
        let drillVideoJsonString = JsonTestString.readJsonFile(fileName: "drillVideo", bundle: Bundle(for: type(of: self)))
        let drillVideoParser = DrillVideoParser(jsonString: drillVideoJsonString)
        let drillVideoItem = drillVideoParser?.getDrillVideoItem()
        XCTAssert(drillVideoItem?.drillVideoID == 134)
        XCTAssert(drillVideoItem?.file == "https://gamesense-videos.s3.amazonaws.com/Robles-13.mp4")
        XCTAssert(drillVideoItem?.pitchTypeID == 1)
        XCTAssert(drillVideoItem?.pitchLocationID == 2)
    }
    
    func testDrillVideoPitchLocations()
    {
        let expectedRecordCount = 4
        let drillPitchLocationString = JsonTestString.readJsonFile(fileName: "drillQuestionPitchLocations", bundle: Bundle(for: type(of: self)))
        let drillPitchLocationParser = DrillPitchLocationParser(jsonString: drillPitchLocationString)
        let drillPitchItemArray = drillPitchLocationParser?.getDrillVideoPitchLocationArray()
        XCTAssert(expectedRecordCount == drillPitchItemArray?.count)
        XCTAssert(expectedRecordCount == drillPitchLocationParser?.recordCount)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
