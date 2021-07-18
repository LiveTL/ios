//
//  iosUnitTests.swift
//  iosUnitTests
//
//  Created by Andrew Glaze on 7/8/21.
//

import XCTest
import ios

class IosFilterTests: XCTestCase {
    let services = AppServices()
    
    func testGeneralfilter() {
        services.settings.languages = TranslatedLanguageTag.allCases
            
        let message = InjectedMessage(author: InjectedMessage.Author(id: "00", name: "Test", types: []), messages: [Message.text("(en) Hello There")], showtime: 0.0, timestamp: Date.distantPast)
        if let tl = StreamModel(services).translate(message) as? TranslatedMessage {
            XCTAssertEqual(tl.languageTag, TranslatedLanguageTag.en, "Incorrect Language")
            XCTAssertEqual(tl.message, "Hello There", "Message not formatted correcly")
        }else {
            XCTFail("\"(en) \"is not filtered as a translated message.")
        }
    }
    
    func testTLDash() {
        
        services.settings.languages = TranslatedLanguageTag.allCases
        
        let message = InjectedMessage(author: InjectedMessage.Author(id: "00", name: "Test", types: []), messages: [Message.text("(es) - Hola eso")], showtime: 0.0, timestamp: Date.distantPast)
        if let tl = StreamModel(AppServices()).translate(message) as? TranslatedMessage {
            XCTAssertEqual(tl.languageTag, TranslatedLanguageTag.es, "Incorrect Language")
            XCTAssertEqual(tl.message, "Hola eso", "Message not formatted correcly")
        }else {
            XCTFail("\"(es) - \"is not filtered as a translated message.")
        }
    }
    
    func testFancyBrackets() {
        services.settings.languages = TranslatedLanguageTag.allCases
        
        let message = InjectedMessage(author: InjectedMessage.Author(id: "00", name: "Test", types: []), messages: [Message.text("【jp】 Weird bracket gang")], showtime: 0.0, timestamp: Date.distantPast)
        if let tl = StreamModel(AppServices()).translate(message) as? TranslatedMessage {
            XCTAssertEqual(tl.languageTag, TranslatedLanguageTag.jp, "Incorrect Language")
            XCTAssertEqual(tl.message, "Weird bracket gang", "Message not formatted correcly")
        }else {
            XCTFail("\"【jp】 \"is not filtered as a translated message.")
        }
    }
    
    func testDashWithSpace() {
        services.settings.languages = TranslatedLanguageTag.allCases
        
        let message = InjectedMessage(author: InjectedMessage.Author(id: "00", name: "Test", types: []), messages: [Message.text("jp - リーーーーーーー")], showtime: 0.0, timestamp: Date.distantPast)
        if let tl = StreamModel(AppServices()).translate(message) as? TranslatedMessage {
            XCTAssertEqual(tl.languageTag, TranslatedLanguageTag.jp, "Incorrect Language")
            XCTAssertEqual(tl.message, "リーーーーーーー", "Message not formatted correcly")
        }else {
            XCTFail("\"jp - \"is not filtered as a translated message.")
        }
    }
    
    func testColon() {
        services.settings.languages = TranslatedLanguageTag.allCases
        
        let message = InjectedMessage(author: InjectedMessage.Author(id: "00", name: "Test", types: []), messages: [Message.text("en:Test translation")], showtime: 0.0, timestamp: Date.distantPast)
        if let tl = StreamModel(AppServices()).translate(message) as? TranslatedMessage {
            XCTAssertEqual(tl.languageTag, TranslatedLanguageTag.en, "Incorrect Language")
            XCTAssertEqual(tl.message, "Test translation", "Message not formatted correcly")
        }else {
            XCTFail("\"en:\"is not filtered as a translated message.")
        }
    }
    
    func testBracketsWithColon() {
        services.settings.languages = TranslatedLanguageTag.allCases
        
        let message = InjectedMessage(author: InjectedMessage.Author(id: "00", name: "Test", types: []), messages: [Message.text("[en]: test translation")], showtime: 0.0, timestamp: Date.distantPast)
        if let tl = StreamModel(AppServices()).translate(message) as? TranslatedMessage {
            XCTAssertEqual(tl.languageTag, TranslatedLanguageTag.en, "Incorrect Language")
            XCTAssertEqual(tl.message, "test translation", "Message not formatted correcly")
        }else {
            XCTFail("\"[en]: \"is not filtered as a translated message.")
        }
    }
    
    func testLongLangCode() {
        services.settings.languages = TranslatedLanguageTag.allCases
        
        let message = InjectedMessage(author: InjectedMessage.Author(id: "00", name: "Test", types: []), messages: [Message.text("[eng] test translation")], showtime: 0.0, timestamp: Date.distantPast)
        if let tl = StreamModel(AppServices()).translate(message) as? TranslatedMessage {
            XCTAssertEqual(tl.languageTag, TranslatedLanguageTag.en, "Incorrect Language")
            XCTAssertEqual(tl.message, "test translation", "Message not formatted correcly")
        }else {
            XCTExpectFailure()
            XCTFail("\"[eng] \"is not filtered as a translated message. It should be.")
        }
    }
    
    func testNoTL() {
        let message = InjectedMessage(author: InjectedMessage.Author(id: "00", name: "Test", types: []), messages: [Message.text("No translation")], showtime: 0.0, timestamp: Date.distantPast)
        if let tl = StreamModel(AppServices()).translate(message) as? TranslatedMessage {
            XCTAssertEqual(tl.languageTag, TranslatedLanguageTag.en, "Incorrect Language")
            XCTAssertEqual(tl.message, "test translation", "Message not formatted correcly")
        }else {
            //XCTExpectFailure()
            XCTAssert(true)
        }
    }
}

class IosLangCodeTests: XCTestCase {
    
}
