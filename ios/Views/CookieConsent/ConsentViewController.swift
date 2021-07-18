//
//  ConsentViewController.swift
//  ios
//
//  Created by Mason Phillips on 7/17/21.
//

import UIKit
import Neon
import WebKit
import SCLAlertView
import RxSwift
import RxCocoa

class ConsentViewController: BaseController {
    let webView = WKWebView()
    let acceptanceDone = BehaviorRelay<Void>(value: ())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.navigationDelegate = self
        view.addSubview(webView)
        
        acceptanceDone.skip(1)
            .debounce(.milliseconds(500), scheduler: MainScheduler.asyncInstance)
            // Moving to a stream too quickly will cause acceptance to pop back up
            .delay(.seconds(1), scheduler: MainScheduler.asyncInstance)
            .subscribe(onNext: { _ in
                self.stepper.steps.accept(AppStep.consentDone)
            }).disposed(by: bag)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let alert = SCLAlertView()
        alert.showInfo("YouTube Cookies Consent", subTitle: "YouTube has noticed that you have not yet accepted their cookies, and has blocked access. In order to get past this warning, you'll need to sign in to your Google account. You should only need to do this once.", closeButtonTitle: "OK")
    }
    
    func consentFunctionWithHtmlData(htmlData data: String) {
        webView.loadHTMLString(data, baseURL: nil)
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
                self.acceptanceDone.accept(())
            }
        } else if navigationAction.request.url?.host == "www.youtube.com" {
            return decisionHandler(.cancel)
        }
        
        decisionHandler(.allow)
    }
}
