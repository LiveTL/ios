//
//  ConsentViewController.swift
//  ios
//
//  Created by Mason Phillips on 7/17/21.
//

import Neon
import RxCocoa
import RxSwift
import SCLAlertView
import UIKit
import WebKit
import RxFlow

class ConsentViewController: BaseController {
    let webView = WKWebView()
    let acceptanceDone = BehaviorRelay<Void>(value: ())
    let showAlert: Bool
    let services: AppServices
    
    init(_ stepper: Stepper, _ services: AppServices, showAlert: Bool) {
        self.showAlert = showAlert
        self.services = services
        
        super.init(stepper, services)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = rightButton
        
        webView.navigationDelegate = self
        view.addSubview(webView)
        
        acceptanceDone.skip(1)
            .debounce(.milliseconds(500), scheduler: MainScheduler.asyncInstance)
            // Moving to a stream too quickly will cause acceptance to pop back up
            .delay(.seconds(3), scheduler: MainScheduler.asyncInstance)
            .subscribe(onNext: { _ in
                self.stepper.steps.accept(AppStep.consentDone)
            }).disposed(by: bag)
    }
    
    var rightButton: UIBarButtonItem {
        return UIBarButtonItem(title: Bundle.main.localizedString(forKey: "Done", value: "Done", table: "Localizeable"), style: .plain, target: self, action: #selector(cookieDone))
    }
    
    @objc func cookieDone() {
        dismiss(animated: true) {
            self.acceptanceDone.accept(())
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if showAlert == true {
            let alert = SCLAlertView()
            alert.showInfo(Bundle.main.localizedString(forKey: "YouTube Cookies Consent", value: "YouTube Cookies Consent", table: "Localizeable"), subTitle: Bundle.main.localizedString(forKey: "YouTube has noticed that you have not yet accepted their cookies, and has blocked access. In order to get past this warning, you'll need to sign in to your Google account. You should only need to do this once. Once you have signed in, press done.", value: "YouTube has noticed that you have not yet accepted their cookies, and has blocked access. In order to get past this warning, you'll need to sign in to your Google account. You should only need to do this once. Once you have signed in, press done.", table: "Localizeable"), closeButtonTitle: Bundle.main.localizedString(forKey: "OK", value: "OK", table: "Localizeable"))
        }
    }
    
    func consentFunction() {
        let request = URLRequest(url: URL(string: "https://www.youtube.com/feed/library")!)
        webView.load(request)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        webView.fillSuperview()
    }
}

extension ConsentViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if
            let urlString = navigationAction.request.url?.absoluteString,
            (urlString.contains("/accounts/SetSID") || urlString.contains("consent.youtube.com")) {
            self.dismiss(animated: true) {
                self.services.settings.youtubeLogin = true
                self.acceptanceDone.accept(())
            }
        }

        decisionHandler(.allow)
    }
}
