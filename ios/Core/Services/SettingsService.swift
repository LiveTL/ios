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
    var captions    : DefaultsKey<Bool> { .init("captions_enabled", defaultValue: true)}
    var clipboard   : DefaultsKey<Bool> { .init("clipboard_enabled", defaultValue: false) }
    var thumbnails  : DefaultsKey<Bool> { .init("thumbnails_enabled", defaultValue: true)}
    var thumbnailBlur: DefaultsKey<Bool> { .init("thumbnail_blur_enabled", defaultValue: false)}
    var thumbnailDarken: DefaultsKey<Bool> { .init("thumbnail_darken_enabled", defaultValue: true)}
    
    var always_users: DefaultsKey<[String]> { .init("always_shown_users", defaultValue: []) }
    var never_users : DefaultsKey<[String]> { .init("never_shown_users", defaultValue: []) }
    var spotlightUser: DefaultsKey<String?> { .init("spotlight_user", defaultValue: nil)}
    
    var orgFilter   : DefaultsKey<Organization> { .init("org_filter", defaultValue: Organization.Hololive)}
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
    
    @SwiftyUserDefault(keyPath: \.clipboard)
    var clipboard: Bool
    
    @SwiftyUserDefault(keyPath: \.orgFilter)
    var orgFilter: Organization
    
    @SwiftyUserDefault(keyPath: \.thumbnails)
    var thumbnails: Bool
    
    @SwiftyUserDefault(keyPath: \.thumbnailBlur)
    var thumbnailBlur: Bool
    
    @SwiftyUserDefault(keyPath: \.thumbnailDarken)
    var thumbnailDarken: Bool
    
    @SwiftyUserDefault(keyPath: \.captions)
    var captions: Bool
    
    @SwiftyUserDefault(keyPath: \.spotlightUser)
    var spotlightUser: String?
    
    var singleLanguage: TranslatedLanguageTag {
        get { return languages.first ?? .en }
        set { languages = [newValue] }
    }
}

extension SettingsService: ObservableObject {}

extension TranslatedLanguageTag: DefaultsSerializable, RawRepresentable {}

extension Organization: DefaultsSerializable, RawRepresentable {}
