//
//  ActionViewController.swift
//  yt-extension
//
//  Created by Mason Phillips on 4/6/21.
//

import UIKit
import MobileCoreServices

class ActionViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    
        let items = (extensionContext?.inputItems.first as? NSExtensionItem)?.attachments ?? []
        
        if(items.count <= 0) {
            // show error in modal
            print("no items passed???")
            return
        }
        
        for attachment in items {
            if attachment.hasItemConformingToTypeIdentifier(kUTTypeURL as String) {
                attachment.loadItem(forTypeIdentifier: kUTTypeURL as String, options: nil) { (data, error) in
                    // show error in modal
                    guard error == nil else { print("error in kUTTypeURL: \(error!)"); return }

                    if let url = data as? URL {
                        self.perform(with: url)
                    } else {
                        // show error in modal
                        print("could not cast from kUTTypeURL to URL???")
                    }
                }
            }
            
            if attachment.hasItemConformingToTypeIdentifier(kUTTypeText as String) {
                attachment.loadItem(forTypeIdentifier: kUTTypeText as String, options: nil) { (data, error) in
                    // show error in modal
                    guard error == nil else { print("error in kUTTypeText: \(error!)"); return }

                    if let str = data as? String, let url = URL(string: str) {
                        self.perform(with: url)
                    } else {
                        // show error in modal
                        print("could not cast from kUTTypeText to URL???")
                    }
                }
            }
        }
    }
    
    func perform(with url: URL) {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        guard let vId = components.queryItems?.filter({ $0.name == "v" }).first?.value else {
            // show error in modal
            print("could not get vId")
            return
        }
        
        let appURL = URL(string: "livetl-translate://translate/\(vId)?full=\(url.absoluteString)")!
        var responder = self as UIResponder?
        let selectorOpenURL = sel_registerName("openURL:")

        while (responder != nil) {
            if (responder?.responds(to: selectorOpenURL))! {
                let _ = responder?.perform(selectorOpenURL, with: appURL)
            }
            
            responder = responder!.next
        }

        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }
    
    @IBAction func done() {
        self.extensionContext!.completeRequest(returningItems: self.extensionContext!.inputItems, completionHandler: nil)
    }

}
