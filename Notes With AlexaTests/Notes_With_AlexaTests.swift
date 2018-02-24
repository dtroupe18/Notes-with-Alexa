//
//  Notes_With_AlexaTests.swift
//  Notes With AlexaTests
//
//  Created by Dave on 1/25/18.
//  Copyright © 2018 High Tree Development. All rights reserved.
//

import XCTest
@testable import Notes_With_Alexa

class Notes_With_AlexaTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testGetTextForNote() {
        
        let vc = NoteViewController()
        let response = vc.getTextForNote(text: "this is one line of text")
        
        XCTAssertTrue(response.count == 1, "Response size of wrong for one line")
        XCTAssertTrue(response[0] == "this is one line of text", "Wrong text returned for one line")
        
        let secondResponse = vc.getTextForNote(text: "First Line\n Second Line")
        XCTAssertTrue(secondResponse.count == 2, "Count wrong for two lines")
        XCTAssertTrue(secondResponse[0] == "First Line")
        XCTAssertTrue(secondResponse[1] == " Second Line")
        
        let thirdResponse = vc.getTextForNote(text: "\nSecond Line")
        XCTAssertTrue(thirdResponse.count == 2, "Returned one line for third response")
        XCTAssertTrue(thirdResponse[0] == "", "First line wrong for third response returned \(thirdResponse[0])")
        XCTAssertTrue(thirdResponse[1] == "Second Line", "Second line wrong for third response")
        
        let fourthResponse = vc.getTextForNote(text: "First Line\nSecond Line\nThird Line")
        XCTAssertTrue(fourthResponse.count == 2, "Returned \(fourthResponse.count) should be 2")
        XCTAssertTrue(fourthResponse[1] == "Second Line\nThird Line", "Returned \(fourthResponse[1]) should have been Second Line\nThird Line")
    }
    
    func testGetFirstLineOfText() {
        
        let testOne = Note(title: "DoesntMatter", firstLine: "", timestamp: Date().millisecondsSinceEpoch, additionalText: "\nShoppingList\n\nEggs")
        let testTwo = Note(title: "DoesntMatter", firstLine: "", timestamp: Date().millisecondsSinceEpoch, additionalText: "\n\nShoppingList\nBread\nCheese")
        let testThree = Note(title: "DoesntMatter", firstLine: "", timestamp: Date().millisecondsSinceEpoch, additionalText: "\nShoppingList")
        let testFour = Note(title: "DoesntMatter", firstLine: "ShoppingList", timestamp: Date().millisecondsSinceEpoch, additionalText: "Additional Text")
        let testFive = Note(title: "DoesntMatter", firstLine: "", timestamp: Date().millisecondsSinceEpoch, additionalText: "ShoppingList")
        
        let resultOne = Helper.getFirstLineOfText(note: testOne)
        let resultTwo = Helper.getFirstLineOfText(note: testTwo)
        let resultThree = Helper.getFirstLineOfText(note: testThree)
        let resultFour = Helper.getFirstLineOfText(note: testFour)
        let resultFive = Helper.getFirstLineOfText(note: testFive)
        
        XCTAssertTrue(resultOne == "ShoppingList", "Failed for test one returned: \(resultOne ?? "NULL")")
        XCTAssertTrue(resultTwo == "ShoppingList", "Failed for test two returned: \(resultTwo ?? "NULL")")
        XCTAssertTrue(resultThree == "ShoppingList", "Failed for test three returned: \(resultThree ?? "NULL")")
        XCTAssertTrue(resultFour == "ShoppingList", "Failed for test four returned: \(resultFour ?? "NULL")")
        XCTAssertTrue(resultFive == "ShoppingList", "Failed for test five returned: \(resultFive ?? "NULL")")
        
    }
    
    func testGetSecondLineOfText() {
        
        let testOne = Note(title: "DoesntMatter", firstLine: "ShoppingList", timestamp: Date().millisecondsSinceEpoch, additionalText: "Additional Text")
        let testTwo = Note(title: "DoesntMatter", firstLine: "Title", timestamp: Date().millisecondsSinceEpoch, additionalText: "\nShoppingList\n\nEggs")
        let testThree = Note(title: "DoesntMatter", firstLine: "Title", timestamp: Date().millisecondsSinceEpoch, additionalText: "\n\nShoppingList\nBread\nCheese")
        let testFour = Note(title: "DoesntMatter", firstLine: "", timestamp: Date().millisecondsSinceEpoch, additionalText: "\nShoppingList")
        let testFive = Note(title: "DoesntMatter", firstLine: "", timestamp: Date().millisecondsSinceEpoch, additionalText: "ShoppingList")
        let testSix = Note(title: "DoesntMatter", firstLine: "", timestamp: Date().millisecondsSinceEpoch, additionalText: "\n\nShoppingList\nBread\nCheese")
        
        let one = Helper.getSecondLineOfText(note: testOne)
        let two = Helper.getSecondLineOfText(note: testTwo)
        let three = Helper.getSecondLineOfText(note: testThree)
        let four = Helper.getSecondLineOfText(note: testFour)
        let five = Helper.getSecondLineOfText(note: testFive)
        let six = Helper.getSecondLineOfText(note: testSix)
        
        XCTAssertTrue(one == "Additional Text", "Failed for test one returned: \(one ?? "NULL")")
        XCTAssertTrue(two == "ShoppingList", "Failed for test two returned: \(two ?? "NULL")")
        XCTAssertTrue(three == "ShoppingList", "Failed for test three returned: \(three ?? "NULL")")
        XCTAssertTrue(four == "", "Failed for test four returned: \(four ?? "NULL")")
        XCTAssertTrue(five == "", "Failed for test five returned: \(five ?? "NULL")")
        XCTAssertTrue(six == "Bread\nCheese", "Failed for test six returned: \(six ?? "NULL")")
    }
    
    func testGetTitle() {
        let vc = NoteViewController()
        
        let arrayOne = vc.getTextForNote(text: "Title\nNot Title")
        let arrayTwo = vc.getTextForNote(text: "\nTitle\nNot Title")
        let arrayThree = vc.getTextForNote(text: "\n\nTitle\nNot Title")
        let arrayFour = vc.getTextForNote(text: "\n\n\n\n\n\nTitle\nNot Title")
        
        let titleOne = Helper.getTitle(lines: arrayOne)
        let titleTwo = Helper.getTitle(lines: arrayTwo)
        let titleThree = Helper.getTitle(lines: arrayThree)
        let titleFour = Helper.getTitle(lines: arrayFour)
        
        XCTAssertTrue(titleOne == "Title", "Failed for test one returned: \(titleOne ?? "NULL")")
        XCTAssertTrue(titleTwo == "Title", "Failed for test four returned: \(titleTwo ?? "NULL")")
        XCTAssertTrue(titleThree == "Title", "Failed for test three returned: \(titleThree ?? "NULL")")
        XCTAssertTrue(titleFour == "Title", "Failed for test three returned: \(titleFour ?? "NULL")")
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
