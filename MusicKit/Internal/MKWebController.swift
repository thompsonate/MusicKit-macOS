//
//  MKWebController.swift
//  MusicKit
//
//  Created by Nate Thompson on 1/5/19.
//  Copyright © 2019 Nate Thompson. All rights reserved.
//

import Cocoa
import WebKit


class MKWebController: NSWindowController {
    private var webView: WKWebView!
    private var contentController = WKUserContentController()
    private var decoder = MKDecoder()
    
    private var promiseDict: [String: (Any) -> Void] = [:]
    private var eventListenerDict: [String: [() -> Void]] = [:]
    
    private static var defaultErrorHandler: (Error) -> Void {
        return { error in
            #if DEBUG
            print(error)
            #else
            NSLog(String(describing: error))
            #endif
        }
    }
    
    var musicKitDidLoad: (() -> Void)?
    
    init() {
        let preferences = WKPreferences()
        
        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        configuration.userContentController = contentController
        
        webView = WKWebView(frame: .zero, configuration: configuration)
        
        let viewController = NSViewController(nibName: nil, bundle: nil)
        viewController.view = webView
        let window = NSWindow(contentViewController: viewController)
        super.init(window: window)
        
        // Clear WKWebView cache so we get an error if the MusicKit script fails to load
        let websiteDataTypes = NSSet(array: [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache])
        let date = Date(timeIntervalSince1970: 0)
        WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes as! Set<String>, modifiedSince: date, completionHandler:{ })
        
        // Adds message handler used in WKScriptMessageHandler extension
        contentController.add(self, name: "musicKitLoaded")
        contentController.add(self, name: "eventListenerCallback")
        contentController.add(self, name: "log")
        
        webView.uiDelegate = self
        webView.navigationDelegate = self
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func loadWebView(
        withDeveloperToken developerToken: String,
        appName: String,
        appBuild: String)
    {
        let musicKitBundle = Bundle(for: MusicKit.self)
        let htmlPath = musicKitBundle.path(forResource: "MusicKit", ofType: "html")!
        do {
            let url = URL(fileURLWithPath: htmlPath)
            let htmlString = try String(contentsOf: url)
                .replacingOccurrences(of: "$DEV_TOKEN", with: developerToken)
                .replacingOccurrences(of: "$APP_NAME", with: appName)
                .replacingOccurrences(of: "$APP_BUILD", with: appBuild)
            
            webView.loadHTMLString(htmlString, baseURL: URL(string: "http://music.natethompson.io"))
        } catch {
            NSLog(error.localizedDescription)
        }
    }
    
    
    override func showWindow(_ sender: Any?) {
        fatalError("Don't do this")
    }
    
    
    func addEventListener(named eventName: String, callback: @escaping () -> Void) {
        if eventListenerDict[eventName] != nil {
            eventListenerDict[eventName]!.append(callback)
        } else {
            eventListenerDict[eventName] = [callback]
        }
        evaluateJavaScript("""
            MusicKit.getInstance().addEventListener('\(eventName)', function() {
                \(postCallback(named: eventName))
            })
            """)
    }
    
    
    
    // MARK: Evaluate JavaScript
    
    /// Evaluates JavaScript String.
    func evaluateJavaScript(_ javaScriptString: String,
                            onSuccess: (() -> Void)? = nil,
                            onError: @escaping (Error) -> Void = defaultErrorHandler)
    {
        webView.evaluateJavaScript(javaScriptString) { (response, error) in
            if let error = error {
                let onErrorFiltered = self.closureFilteringUnsupportedTypeError(errorClosure: onError)
                let errorWithDetails = JSError(underlyingError: error, jsString: javaScriptString, result: response)
                onErrorFiltered(errorWithDetails)
            } else {
                onSuccess?()
            }
        }
    }
    
    
    
    /// Evaluates JavaScript and passes decoded return value to completionHandler.
    func evaluateJavaScript<T: Decodable>(_ javaScriptString: String,
                                          type: T.Type,
                                          decodingStrategy strategy: MKDecoder.Strategy,
                                          onSuccess: ((T) -> Void)?,
                                          onError: @escaping (Error) -> Void = defaultErrorHandler)
    {
        guard let onSuccess = onSuccess else {
            evaluateJavaScript(javaScriptString, onError: onError)
            return
        }
        
        webView.evaluateJavaScript(javaScriptString) { (response, error) in
            self.handleResponse(response,
                                to: javaScriptString,
                                withError: error,
                                decodeTo: type,
                                withStrategy: strategy,
                                onSuccess: onSuccess,
                                onError: onError)
        }
    }
    
    
    
    /// Evaluates JavaScript for void Promise and calls completionHandler when Promise is fulfilled.
    func evaluateJavaScriptWithPromise(_ javaScriptString: String,
                                       onSuccess: (() -> Void)?,
                                       onError: @escaping (Error) -> Void = defaultErrorHandler)
    {
        guard let onSuccess = onSuccess else {
            evaluateJavaScript(javaScriptString, onError: onError)
            return
        }
        
        // Generate unique key for dictionary
        let key = "_\(UUID().uuidString)".replacingOccurrences(of: "-", with: "")
        contentController.add(self, name: key)
        
        // Add completionHandler to dictionary to run after the message handler is called
        promiseDict[key] = { _ in
            onSuccess()
        }
        
        evaluateJavaScript(javaScriptString + promise(named: key, returnsValue: false), onError: onError)
    }
    
    
    
    /// Evaluates JavaScript for Promise and passes decoded response to completionHandler.
    func evaluateJavaScriptWithPromise<T: Decodable>(_ javaScriptString: String,
                                                     type: T.Type,
                                                     decodingStrategy strategy: MKDecoder.Strategy,
                                                     onSuccess: ((T) -> Void)?,
                                                     onError: @escaping (Error) -> Void = defaultErrorHandler)
    {
        guard let onSuccess = onSuccess else {
            evaluateJavaScript(javaScriptString, onError: onError)
            return
        }

        // Generate unique key for dictionary
        let key = "_\(UUID().uuidString)".replacingOccurrences(of: "-", with: "")
        contentController.add(self, name: key)

        // Add completionHandler to dictionary to run after the message handler is called
        promiseDict[key] = { response in
            // handle promise response
            self.handleResponse(response,
                                to: javaScriptString,
                                withError: nil,
                                decodeTo: type,
                                withStrategy: strategy,
                                onSuccess: onSuccess,
                                onError: onError)
        }

        evaluateJavaScript(javaScriptString + promise(named: key, returnsValue: true), onError: onError)
    }
    
    
    
    // MARK: Handle JS Response
    
    private func handleResponse<T: Decodable>(_ response: Any?,
                                              to jsString: String,
                                              withError error: Error?,
                                              decodeTo type: T.Type,
                                              withStrategy strategy: MKDecoder.Strategy,
                                              onSuccess: (T) -> Void,
                                              onError: (Error) -> Void)
    {
        if let error = error {
            onError(JSError(underlyingError: error, jsString: jsString, result: response))
        } else {
            do {
                let decodedResponse = try self.decoder.decodeJSResponse(response!, to: type, withStrategy: strategy)
                onSuccess(decodedResponse)
            } catch {
                // Add JS input string to the error to aid diagnosis
                if error is MKDecoder.DecodingError {
                    var e = error as! MKDecoder.DecodingError
                    e.jsString = jsString
                    onError(e)
                } else {
                    onError(error)
                }
            }
        }
    }

    
    
    /// Filters out error thrown when evaluating JavaScript returns a promise.
    private func closureFilteringUnsupportedTypeError(errorClosure: @escaping (Error) -> Void) -> (Error) -> Void {
        return { error in
            if let error = error as? JSError,
                let underlyingError = error.underlyingError as? WKError,
                underlyingError.code == WKError.javaScriptResultTypeIsUnsupported
            {
                // do nothing
            } else {
                errorClosure(error)
            }
        }
    }
    
    
    
    struct JSError: Error, CustomStringConvertible {
        let underlyingError: Error
        let jsString: String
        let result: Any?

        var description: String {
            return """
            Evaluation of JavaScript string produced an error:
                \(String(describing: underlyingError))
                JavaScript string: \(jsString)
                result: \(String(describing: result))
            """
        }
    }
    
    
    
    // MARK: Boilerplate JavaScript
    
    private func postCallback(named name: String) -> String {
        return """
        try {
            webkit.messageHandlers.eventListenerCallback.postMessage('\(name)');
        } catch(err) {
            console.log(err);
        }
        """
    }
    
    
    
    /// Generates a JS string that will call message handler when promise is run.
    /// promiseName must be valid JS variable name.
    private func promise(named promiseName: String, returnsValue: Bool) -> String {
        let promise = """
        .then(function(response) {
            try {
                webkit.messageHandlers.\(promiseName).postMessage(response);
            } catch(err) {
                console.log(err);
            }
        });
        """
        let voidPromise = """
        .then(function() {
            try {
                webkit.messageHandlers.\(promiseName).postMessage('');
            } catch(err) {
                console.log(err);
            }
        });
        """
        return returnsValue ? promise : voidPromise
    }
}



    
    
extension MKWebController: WKScriptMessageHandler {
    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage)
    {
        // Remember to add message handler for each message in init()
        if message.name == "musicKitLoaded" {
            musicKitDidLoad?()
            
        } else if message.name == "eventListenerCallback" {
            guard let eventName = message.body as? String,
                let callbacks = eventListenerDict[eventName] else
            {
                    NSLog("Error: no callback function for event listener")
                    return
            }
            for callback in callbacks {
                callback()
            }
            
        } else if message.name == "log" {
            NSLog(message.body as? String ?? "Error logging from JS")
            
        } else if let completionHandler = promiseDict[message.name] {
            // is promise callback message
            completionHandler(message.body)
            promiseDict.removeValue(forKey: message.name)
            
        } else {
            NSLog("Unhandled script message: \(message.name) - \(message.body)")
        }
    }
}



// MARK: UI Delegate
extension MKWebController: WKUIDelegate {
    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures) -> WKWebView?
    {
        let authWebView = WKWebView(frame: .zero, configuration: configuration)
        let authWindow = AuthorizeWindowController(webView: authWebView)
        authWindow.showWindow(nil)
        
        return authWebView
    }
}

// MARK: Navigation Delegate
extension MKWebController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        NSLog("didFailProvisionalNavigation \(error.localizedDescription)")
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        NSLog("didFailNavigation \(error.localizedDescription)")
    }
    
    func webView(_ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse,
        decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {

      guard let statusCode
          = (navigationResponse.response as? HTTPURLResponse)?.statusCode else {
        // if there's no http status code to act on, exit and allow navigation
        decisionHandler(.allow)
        return
      }

      if statusCode >= 400 {
        NSLog("http status error \(statusCode)")
      }

      decisionHandler(.allow)
    }
}
