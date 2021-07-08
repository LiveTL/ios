//
//  iosUnitTests.swift
//  iosUnitTests
//
//  Created by Andrew Glaze on 7/8/21.
//

import XCTest
import ios

class iosFilterTests: XCTestCase {

    override func setUpWithError() throws {
        
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testGeneralfilter() throws {
        let services = AppServices()
        services.settings.languages = TranslatedLanguageTag.allCases
            
        let message1 = InjectedMessage(author: InjectedMessage.Author(id: "00", name: "Test", types: []), messages: [Message.text("(en) Hello There")], showtime: 0.0, timestamp: Date.now)
        if let tl1 = StreamModel(services).translate(message1) as? TranslatedMessage {
            XCTAssertEqual(tl1.languageTag, TranslatedLanguageTag.en)
            XCTAssertEqual(tl1.message, " Hello There")
        }else {
            XCTFail("(en) failed - not a translated message.")
        }
        
        let message2 = InjectedMessage(author: InjectedMessage.Author(id: "00", name: "Test", types: []), messages: [Message.text("(es) - Hola eso")], showtime: 0.0, timestamp: Date.now)
        if let tl2 = StreamModel(AppServices()).translate(message2) as? TranslatedMessage {
            XCTAssertEqual(tl2.languageTag, TranslatedLanguageTag.es)
            XCTAssertEqual(tl2.message, " - Hola eso")
        }else {
            XCTFail("(es) failed - not a translated message.")
        }
    }

}
