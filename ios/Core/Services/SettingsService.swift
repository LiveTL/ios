//
//  SettingsService.swift
//  ios
//
//  Created by Mason Phillips on 4/6/21.
//

import Foundation
import SwiftyUserDefaults
import Combine

extension DefaultsKeys {
    var languages   : DefaultsKey<[TranslatedLanguageTag]> { .init("languages", defaultValue: [.en]) }
    var mod_messages: DefaultsKey<Bool> { .init("mod_messages_enabled", defaultValue: true) }
    var timestamps  : DefaultsKey<Bool> { .init("timestamps_enabled", defaultValue: true) }
    
    var always_users: DefaultsKey<[String]> { .init("always_shown_users", defaultValue: []) }
    var never_users : DefaultsKey<[String]> { .init("never_shown_users", defaultValue: []) }
}

class SettingsService {
    @SwiftyUserDefault(keyPath: \.languages)
    var languages: [TranslatedLanguageTag]
    
    @SwiftyUserDefault(keyPath: \.mod_messages)
    var modMessages: Bool
    
    @SwiftyUserDefault(keyPath: \.timestamps)
    var timestamps: Bool
    
    @SwiftyUserDefault(keyPath: \.always_users)
    var alwaysUsers: [String]
    
    @SwiftyUserDefault(keyPath: \.never_users)
    var neverUsers: [String]
    
    var singleLanguage: TranslatedLanguageTag {
        get { return languages.first ?? .en }
        set { languages = [newValue] }
    }
}

extension SettingsService: ObservableObject {}

extension TranslatedLanguageTag: DefaultsSerializable, RawRepresentable {}
