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

class ConsentViewController: BaseController {
    let webView = WKWebView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.navigationDelegate = self
        view.addSubview(webView)
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
        defer { decisionHandler(.allow) }
        
        if let urlString = navigationAction.request.url?.absoluteString {
            if urlString.contains("/accounts/SetSID") {
                self.stepper.steps.accept(AppStep.consentDone)
            }
        }
    }
}
