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
        return UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(settingsDone))
    }
    
    init(_ services: AppServices, stepper: Stepper) {
        self.services = services
        self.stepper = stepper
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = rightButton
        navigationItem.title = "Settings"
        
        form
            +++ Section("App Settings")
            
            <<< SwitchRow("thumbnails_enabled") { row in
                row.title = "Enable Thumbnail Backgrounds"
                row.value = self.settings.thumbnails
            }.onChange { row in
                if let value = row.value {
                    self.settings.thumbnails = value
                }
            }
            
            <<< SwitchRow("thumbnail_darken_enabled") { row in
                row.title = "Enable Thumbnail Darken Effect"
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
                row.title = "Enable Thumbnail Blur Effect"
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
                row.title = "Allow Clipboard Detection"
                row.value = self.settings.clipboard
            }.onChange { row in
                if let value = row.value {
                    self.settings.clipboard = value
                }
            }
            
            +++ Section("Message Settings")
        
            <<< MultipleSelectorRow<String>("lang_select") { row in
                row.options = TranslatedLanguageTag.allCases.map { $0.description }
                row.value = Set(settings.languages.map { $0.description })
                row.title = "Languages"
                row.noValueDisplayText = "No languages selected"
                row.displayValueFor = { values -> String? in
                    values.map { $0.map { $0.description } }?.joined(separator: ", ")
                }
            }.onChange { row in
                if let value = row.value {
                    self.settings.languages = Array(value).compactMap { TranslatedLanguageTag($0) }
                }
            }
        
            <<< SwitchRow("mod_enabled") { row in
                row.title = "Mod Messages"
                row.value = settings.modMessages
            }.onChange { row in
                if let value = row.value {
                    self.settings.modMessages = value
                }
            }
            
            <<< SwitchRow("timestamps_enabled") { row in
                row.title = "Show Timestamps"
                row.value = settings.timestamps
            }.onChange { row in
                if let value = row.value {
                    self.settings.timestamps = value
                }
            }
            
            <<< SwitchRow("captions_enabled") { row in
                row.title = "Caption Mode"
                row.value = settings.captions
            }.onChange { row in
                if let value = row.value {
                    self.settings.captions = value
                }
            }
        
            +++ MultivaluedSection(multivaluedOptions: [.Insert, .Delete],
                                   header: "Allowed Users",
                                   footer: "These users are always shown, even if they don't translate a message") { section in
                
                section.tag = "always_users_section"
                
                section.addButtonProvider = { section in
                    return ButtonRow(){
                        $0.title = "Tap to Add User"
                    }
                }
                section.multivaluedRowToInsertAt = { index in
                    return AccountRow() {
                        $0.placeholder = "Username"
                    }
                }
                
                for user in settings.alwaysUsers {
                    section <<< AccountRow() {
                        $0.placeholder = "Username"
                        $0.value = user
                    }
                }
                
                section <<< AccountRow() {
                    $0.placeholder = "Username"
                }
            }
        
            +++ MultivaluedSection(multivaluedOptions: [.Insert, .Delete],
                                   header: "Blocked Users",
                                   footer: "These users are never shown, even if they translate a message") { section in
                section.tag = "never_users_section"
                
                section.addButtonProvider = { section in
                    return ButtonRow(){
                        $0.title = "Tap to Add User"
                    }
                }
                section.multivaluedRowToInsertAt = { index in
                    return AccountRow() {
                        $0.placeholder = "Username"
                    }
                }
                
                for user in settings.neverUsers {
                    section <<< AccountRow() {
                        $0.placeholder = "Username"
                        $0.value = user
                    }
                }
                
                section <<< AccountRow() {
                    $0.placeholder = "Username"
                }
            }
            +++ Section("Advanced Settings")
        
            <<< ButtonRow("clear_image_cashe") { row in
                ImageCache.default.calculateDiskStorageSize { result in
                    switch result {
                    case .success(let size):
                        row.title = "Clear Image Cache (\(round((Double(size) / 1024 / 1024) * 100) / 100.0) MB)"
                    case .failure:
                        row.title = "Clear Image Cache"
                    }
                }
            }.onCellSelection() { _ , row  in
                KingfisherManager.shared.cache.clearCache()
                row.title = "Clear Image Cache (0.0 MB)"
                row.updateCell()
            }
        
            <<< ButtonRow("clear_other_cashe") { row in
                row.title = "Clear Other Caches"
            }.onCellSelection() { _ , row  in
                URLCache.shared.removeAllCachedResponses()
            }
    }
    
    
    func getCacheSize() -> String {
        var sizeOut: String = ""
        
        ImageCache.default.calculateDiskStorageSize { result in
            switch result {
            case .success(let size):
                sizeOut = "(\(Double(size) / 1024 / 1024) MB)"
            case .failure(let error):
                print(error)
            }
        }
        
        return sizeOut
    }
    
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
