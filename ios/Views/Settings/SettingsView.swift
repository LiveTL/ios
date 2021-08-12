//
//  SettingsView.swift
//  ios
//
//  Created by Mason Phillips on 3/25/21.
//

import UIKit
import Eureka
import RxFlow
import RxSwift
import Kingfisher
import SwiftyUserDefaults

class SettingsView: FormViewController {
    let services: AppServices
    let stepper : Stepper
    let bag = DisposeBag()
    
    var settings: SettingsService { services.settings }

    var rightButton: UIBarButtonItem {
        return UIBarButtonItem(title: Bundle.main.localizedString(forKey: "Save", value: "Save", table: "Localizeable"), style: .plain, target: self, action: #selector(settingsDone))
    }
    
    init(_ services: AppServices, stepper: Stepper) {
        self.services = services
        self.stepper = stepper
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = rightButton
        navigationItem.title = Bundle.main.localizedString(forKey: "Settings", value: "Settings", table: "Localizeable")
        
        form
            +++ Section(Bundle.main.localizedString(forKey: "App Settings", value: "App Settings", table: "Localizeable"))
            
            <<< SwitchRow("thumbnails_enabled") { row in
                row.title = Bundle.main.localizedString(forKey: "Enable Thumbnail Backgrounds", value: "Enable Thumbnail Backgrounds", table: "Localizeable")
                row.value = self.settings.thumbnails
            }.onChange { row in
                if let value = row.value {
                    self.settings.thumbnails = value
                }
            }
            
            <<< SwitchRow("thumbnail_darken_enabled") { row in
                row.title = Bundle.main.localizedString(forKey: "Enable Thumbnail Darken Effect", value: "Enable Thumbnail Darken Effect", table: "Localizeable")
                row.value = self.settings.thumbnailDarken
                row.hidden = Condition.function(["thumbnails_enabled"], { form in
                    return !((form.rowBy(tag: "thumbnails_enabled") as? SwitchRow)?.value ?? false)
                })
            }.onChange { row in
                if let value = row.value {
                    self.settings.thumbnailDarken = value
                }
            }
            
            <<< SwitchRow("thumbnail_blur_enabled") { row in
                row.title = Bundle.main.localizedString(forKey: "Enable Thumbnail Blur Effect", value: "Enable Thumbnail Blur Effect", table: "Localizeable")
                row.value = self.settings.thumbnailBlur
                row.hidden = Condition.function(["thumbnails_enabled"], { form in
                    return !((form.rowBy(tag: "thumbnails_enabled") as? SwitchRow)?.value ?? false)
                })
            }.onChange { row in
                if let value = row.value {
                    self.settings.thumbnailBlur = value
                }
            }
            
            <<< SwitchRow("clipboard_enabled") { row in
                row.title = Bundle.main.localizedString(forKey: "Allow Clipboard Detection", value: "Allow Clipboard Detection", table: "Localizeable")
                row.value = self.settings.clipboard
            }.onChange { row in
                if let value = row.value {
                    self.settings.clipboard = value
                }
            }
            
            +++ Section(Bundle.main.localizedString(forKey: "Message Settings", value: "Message Settings", table: "Localizeable"))
        
            <<< MultipleSelectorRow<String>("lang_select") { row in
                row.options = TranslatedLanguageTag.allCases.map { $0.description }
                row.value = Set(settings.languages.map { $0.description })
                row.title = Bundle.main.localizedString(forKey: "Languages", value: "Languages", table: "Localizeable")
                row.noValueDisplayText = Bundle.main.localizedString(forKey: "No languages selected", value: "No languages selected", table: "Localizeable")
                row.displayValueFor = { values -> String? in
                    values.map { $0.map { $0.description } }?.joined(separator: ", ")
                }
            }.onChange { row in
                if let value = row.value {
                    self.settings.languages = Array(value).compactMap { TranslatedLanguageTag($0) }
                }
            }
        
            <<< SwitchRow("mod_enabled") { row in
                row.title = Bundle.main.localizedString(forKey: "Mod Messages", value: "Mod Messages", table: "Localizeable")
                row.value = settings.modMessages
            }.onChange { row in
                if let value = row.value {
                    self.settings.modMessages = value
                }
            }
            
            <<< SwitchRow("timestamps_enabled") { row in
                row.title = Bundle.main.localizedString(forKey: "Show Timestamps", value: "Show Timestamps", table: "Localizeable")
                row.value = settings.timestamps
            }.onChange { row in
                if let value = row.value {
                    self.settings.timestamps = value
                }
            }
            
            <<< SwitchRow("captions_enabled") { row in
                row.title = Bundle.main.localizedString(forKey: "Caption Mode", value: "Caption Mode", table: "Localizeable")
                row.value = settings.captions
            }.onChange { row in
                if let value = row.value {
                    self.settings.captions = value
                }
            }
        
            +++ MultivaluedSection(multivaluedOptions: [.Insert, .Delete],
                                   header: Bundle.main.localizedString(forKey: "Allowed Users", value: "Allowed Users", table: "Localizeable"),
                                   footer: Bundle.main.localizedString(forKey: "These users are always shown, even if they don't translate a message", value: "These users are always shown, even if they don't translate a message", table: "Localizeable")) { section in
                
                section.tag = "always_users_section"
                
                section.addButtonProvider = { section in
                    return ButtonRow(){
                        $0.title = Bundle.main.localizedString(forKey: "Tap to Add User", value: "Tap to Add User", table: "Localizeable")
                    }
                }
                section.multivaluedRowToInsertAt = { index in
                    return AccountRow() {
                        $0.placeholder = Bundle.main.localizedString(forKey: "Username", value: "Username", table: "Localizeable")
                    }
                }
                
                for user in settings.alwaysUsers {
                    section <<< AccountRow() {
                        $0.placeholder = Bundle.main.localizedString(forKey: "Username", value: "Username", table: "Localizeable")
                        $0.value = user
                    }
                }
                
                section <<< AccountRow() {
                    $0.placeholder = Bundle.main.localizedString(forKey: "Username", value: "Username", table: "Localizeable")
                }
            }
        
            +++ MultivaluedSection(multivaluedOptions: [.Insert, .Delete],
                                   header: Bundle.main.localizedString(forKey: "Blocked Users", value: "Blocked Users", table: "Localizeable"),
                                   footer: Bundle.main.localizedString(forKey: "These users are never shown, even if they translate a message", value: "These users are never shown, even if they translate a message", table: "Localizeable")) { section in
                section.tag = "never_users_section"
                
                section.addButtonProvider = { section in
                    return ButtonRow(){
                        $0.title = Bundle.main.localizedString(forKey: "Tap to Add User", value: "Tap to Add User", table: "Localizeable")
                    }
                }
                section.multivaluedRowToInsertAt = { index in
                    return AccountRow() {
                        $0.placeholder = Bundle.main.localizedString(forKey: "Username", value: "Username", table: "Localizeable")
                    }
                }
                
                for user in settings.neverUsers {
                    section <<< AccountRow() {
                        $0.placeholder = Bundle.main.localizedString(forKey: "Username", value: "Username", table: "Localizeable")
                        $0.value = user
                    }
                }
                
                section <<< AccountRow() {
                    $0.placeholder = Bundle.main.localizedString(forKey: "Username", value: "Username", table: "Localizeable")
                }
            }
            +++ Section(Bundle.main.localizedString(forKey: "Advanced Settings", value: "Advanced Settings", table: "Localizeable"))
        
            <<< ButtonRow("clear_image_cashe") { row in
                ImageCache.default.calculateDiskStorageSize { result in
                    switch result {
                    case .success(let size):
                        row.title = Bundle.main.localizedString(forKey: "Clear Image Cache", value: "Clear Image Cache", table: "Localizeable") + " (" + String(round((Double(size) / 1024 / 1024) * 100) / 100.0) + " MB)"
                    case .failure:
                        row.title = Bundle.main.localizedString(forKey: "Clear Image Cache", value: "Clear Image Cache", table: "Localizeable")
                    }
                }
            }.onCellSelection() { _ , row  in
                KingfisherManager.shared.cache.clearCache()
                row.title = Bundle.main.localizedString(forKey: "Clear Image Cache", value: "Clear Image Cache", table: "Localizeable") + " (0.0 MB)"
                row.updateCell()
            }
        
            <<< ButtonRow("clear_other_cashe") { row in
                row.title = Bundle.main.localizedString(forKey: "Clear Other Caches", value: "Clear Other Caches", table: "Localizeable")
            }.onCellSelection() { _ , row  in
                URLCache.shared.removeAllCachedResponses()
            }
    }
    
    
//    func getCacheSize() -> String {
//        var sizeOut: String = ""
//
//        ImageCache.default.calculateDiskStorageSize { result in
//            switch result {
//            case .success(let size):
//                sizeOut = "(\(Double(size) / 1024 / 1024) MB)"
//            case .failure(let error):
//                print(error)
//            }
//        }
//
//        return sizeOut
//    }
    
    @objc func settingsDone() {
        let values = form.values()
        
        if let always = values["always_users_section"] as? Array<String> {
            settings.alwaysUsers = always
        }
        if let never = values["never_users_section"] as? Array<String> {
            settings.neverUsers = never
        }
        
        stepper.steps.accept(AppStep.settingsDone)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
}
