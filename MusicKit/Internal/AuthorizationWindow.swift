//
//  AuthorizationWindow.swift
//  MusicKit
//
//  Created by Nate Thompson on 1/4/19.
//  Copyright © 2019 Nate Thompson. All rights reserved.
//

import Cocoa
import WebKit

class AuthorizeWindowController: NSWindowController {
    init(webView: WKWebView) {
        let viewController = AuthorizeViewController(webView: webView)
        let window = NSWindow(contentViewController: viewController)
        window.title = "Sign In"
        window.styleMask = [.titled, .closable]
        
        super.init(window: window)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}





class AuthorizeViewController: NSViewController {
    var webView: WKWebView!
    
    init(webView: WKWebView) {
        super.init(nibName: nil, bundle: nil)
        self.webView = webView
        self.webView.uiDelegate = self
        self.webView.navigationDelegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = webView
        view.frame.size = NSSize(width: 500.0, height: 630.0)
        webView.autoresizingMask = [.width, .height]
    }
}





extension AuthorizeViewController: WKUIDelegate, WKNavigationDelegate {
    func webViewDidClose(_ webView: WKWebView) {
        view.window?.close()
    }
    
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void)
    {
        if navigationAction.navigationType == .linkActivated,
            let url = navigationAction.request.url,
            url.host != "idmsa.apple.com"
        {
            NSWorkspace.shared.open(url)
        }
        decisionHandler(.allow)
    }
}
