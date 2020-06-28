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
    
    /// A dictionary containing responses to pending promises. Keyed by the UUID assigned to the
    /// promise, beginning with an underscore.
    private var promiseDict = [String: PromiseResponse]()
    
    /// A dictionary containing listeners to events, keyed by the event.
    private var eventListenerDict = [MKEvent: [() -> Void]]()
    
    private var isMusicKitLoaded = false {
        didSet {
            if isMusicKitLoaded {
                musicKitDidLoad()
            }
        }
    }

    /// For setting up the framework. Guaranteed to be the called first before public
    /// musicKitDidLoad event listeners.
    private var musicKitDidLoad: () -> Void = {
        RemoteCommandController.setup()
        NowPlayingInfoManager.setup()
        QueueManager.setup()
    }
    
    /// Holds the error handler of the configure function while loading.
    private var loadErrorHandler: ((Error) -> Void)? = nil
    
    private static var defaultErrorHandler: (Error) -> Void {
        return { error in
            #if DEBUG
            print(error)
            #else
            NSLog(String(describing: error))
            #endif
        }
    }
    
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
        contentController.add(self, name: "throwLoadingError")
        
        webView.uiDelegate = self
        webView.navigationDelegate = self
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func showWindow(_ sender: Any?) {
        fatalError("Don't do this")
    }
    
    
    // MARK: Loading Webpage
    
    func loadWebView(
        withDeveloperToken developerToken: String,
        appName: String,
        appBuild: String,
        baseURL: URL,
        appIconURL: URL?,
        onError: @escaping (Error) -> Void)
    {
        loadErrorHandler = onError
        
        let htmlString = MKWebpage.html(
            withDeveloperToken: developerToken,
            appName: appName,
            appBuild: appBuild,
            appIconURL: appIconURL)
        
        if baseURL.host == nil {
            onError(MKError.loadingFailed(message: "Invalid appURL"))
            return
        }
        
        webView.loadHTMLString(htmlString, baseURL: baseURL)
        
        // Ensure that MusicKit has loaded after a few seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            self.evaluateJavaScript("MusicKit.getInstance()", onError: { error in
                // only throw error if loadWebView's onError hasn't already been fired
                if self.loadErrorHandler != nil {
                    self.throwLoadingError(.timeoutError(timeout: 10))
                }
            })
        }
    }
    
    
    private func throwLoadingError(_ error: MKError) {
        if let loadError = loadErrorHandler {
            loadError(error)
            loadErrorHandler = nil
        } else {
            MKWebController.defaultErrorHandler(error)
        }
    }
    
    
    
    // MARK: Event Listeners
    
    func addEventListener(for event: MKEvent, callback: @escaping () -> Void) {
        if eventListenerDict[event] != nil {
            eventListenerDict[event]!.append(callback)
        } else {
            eventListenerDict[event] = [callback]
        }
        
        // If MusicKit isn't loaded, we have to wait to add the event listeners
        if isMusicKitLoaded {
            addEventListenerToMKJS(for: event)
        }
    }
    
    private func addEventListenerToMKJS(for event: MKEvent) {
        let eventName = event.rawValue
        evaluateJavaScript("""
            music.addEventListener('\(eventName)', function() {
                \(postCallback(named: eventName))
            })
            """)
    }
    
    
    
    // MARK: Evaluate JavaScript
    
    /// Evaluates JavaScript String.
    func evaluateJavaScript(
        _ javaScriptString: String,
        onSuccess: (() -> Void)? = nil,
        onError: @escaping (Error) -> Void = defaultErrorHandler)
    {
        webView.evaluateJavaScript(javaScriptString) { (response, error) in
            if let error = error {
                let onErrorFiltered = self.closureFilteringUnsupportedTypeError(errorClosure: onError)
                onErrorFiltered(MKError.javaScriptError(underlyingError: error))
                
                EnhancedJSError(underlyingError: error, jsString: javaScriptString).logIfNeeded()
            } else {
                onSuccess?()
            }
        }
    }
    
    
    
    /// Evaluates JavaScript and passes decoded return value to completionHandler.
    func evaluateJavaScript<T: Decodable>(
        _ javaScriptString: String,
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
            self.handleResponse(
                response,
                to: javaScriptString,
                withError: error,
                decodeTo: type,
                withStrategy: strategy,
                onSuccess: onSuccess,
                onError: onError)
        }
    }
    
    
    
    /// Evaluates JavaScript for void Promise and calls onSuccess handler when Promise is fulfilled.
    func evaluateJavaScriptWithPromise(
        _ javaScriptString: String,
        onSuccess: (() -> Void)?,
        onError: @escaping (Error) -> Void = defaultErrorHandler)
    {
        guard let onSuccess = onSuccess else {
            evaluateJavaScript(javaScriptString, onError: onError)
            return
        }
        
        evaluateJavaScriptWithPromise(
            javaScriptString,
            returnsValue: false,
            onSuccess: { response in
            onSuccess()
        }, onError: onError)
    }
    
    /// Evaluates JavaScript for Promise and passes decoded response to onSuccess handler.
    func evaluateJavaScriptWithPromise<T: Decodable>(
        _ javaScriptString: String,
        type: T.Type,
        decodingStrategy strategy: MKDecoder.Strategy,
        onSuccess: ((T) -> Void)?,
        onError: @escaping (Error) -> Void = defaultErrorHandler)
    {
        guard let onSuccess = onSuccess else {
            evaluateJavaScript(javaScriptString, onError: onError)
            return
        }
        
        evaluateJavaScriptWithPromise(
            javaScriptString,
            returnsValue: true,
            onSuccess: { response in
                self.handleResponse(
                    response,
                    to: javaScriptString,
                    withError: nil,
                    decodeTo: type,
                    withStrategy: strategy,
                    onSuccess: onSuccess,
                    onError: onError)
        }, onError: onError)
    }
    
    
    /// Evaluates JavaScript for Promise and passes response to onSuccess handler.
    private func evaluateJavaScriptWithPromise(
        _ javaScriptString: String,
        returnsValue: Bool,
        onSuccess: @escaping (Any) -> Void,
        onError: @escaping (Error) -> Void)
    {
        // Create a PromiseResponse struct, which encapsulates both the success and error handlers.
        let promiseResponse = PromiseResponse(
            onSuccess: { response in
            // handle promise response
            onSuccess(response)
        }, onError: { error in
            if let errorDict = try? self.decoder.decodeJSResponse(
                    error, to: [String: String].self, withStrategy: .jsonString)
            {
                onError(MKError.promiseRejected(context: errorDict))
            } else {
                onError(MKError.promiseRejected(context: ["unknown": String(describing: error)]))
            }
        })

        // Add PromiseResponse to dictionary to run after the message handler is called
        promiseDict[promiseResponse.id] = promiseResponse
        contentController.add(self, name: promiseResponse.successID)
        contentController.add(self, name: promiseResponse.errorID)

        let promiseString = promise(successID: promiseResponse.successID,
                                    errorID: promiseResponse.errorID,
                                    returnsValue: returnsValue)
        evaluateJavaScript(javaScriptString + promiseString, onError: onError)
    }
    
    
    
    // MARK: Handle JS Response
    
    private func handleResponse<T: Decodable>(
        _ response: Any?,
        to jsString: String,
        withError error: Error?,
        decodeTo type: T.Type,
        withStrategy strategy: MKDecoder.Strategy,
        onSuccess: (T) -> Void,
        onError: (Error) -> Void)
    {
        if let error = error {
            onError(MKError.javaScriptError(underlyingError: error))
            EnhancedJSError(underlyingError: error, jsString: jsString).logIfNeeded()
        } else {
            do {
                let decodedResponse = try self.decoder.decodeJSResponse(
                    response!, to: type, withStrategy: strategy)
                onSuccess(decodedResponse)
            } catch {
                onError(error)
                
                EnhancedDecodingError(underlyingError: error,
                                      jsString: jsString,
                                      response: response!,
                                      decodingStrategy: strategy).logIfNeeded()
            }
        }
    }

    
    
    /// Filters out error thrown when evaluating JavaScript returns a promise.
    private func closureFilteringUnsupportedTypeError(
        errorClosure: @escaping (Error) -> Void) -> (Error) -> Void
    {
        return { error in
            if let error = error as? MKError,
                let underlyingError = error.underlyingError as? WKError,
                underlyingError.code == WKError.javaScriptResultTypeIsUnsupported
            {
                // do nothing
            } else {
                errorClosure(error)
            }
        }
    }
    
    
    
    // MARK: Boilerplate JavaScript
    
    private func postCallback(named name: String) -> String {
        return """
        try {
            webkit.messageHandlers.eventListenerCallback.postMessage('\(name)');
        } catch(err) {
            log(err);
        }
        """
    }
    
    
    
    /// Generates a JS string that will call message handler when promise is run.
    /// promiseName must be valid JS variable name.
    private func promise(successID: String, errorID: String, returnsValue: Bool) -> String {
        let promise = """
        .then(function(response) {
            try {
                webkit.messageHandlers.\(successID).postMessage(response);
            } catch(err) {
                log(err);
            }
        })
        """
        let voidPromise = """
        .then(function() {
            try {
                webkit.messageHandlers.\(successID).postMessage('');
            } catch(err) {
                log(err);
            }
        })
        """
        let catchError = """
        .catch(function(error) {
            let errorString = JSON.stringify(error);
            console.log(error);
            try {
                webkit.messageHandlers.\(errorID).postMessage(errorString);
            } catch(err) {
                log(err);
            }
        });
        """
        return (returnsValue ? promise : voidPromise) + catchError
    }
}



// MARK: Script Message Handler

extension MKWebController: WKScriptMessageHandler {
    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage)
    {
        // Remember to add message handler for each message in init()
        if message.name == "musicKitLoaded" {
            isMusicKitLoaded = true

            // Add registered event listeners to MKJS and call musicKitDidLoad listeners
            for eventListeners in eventListenerDict {
                if eventListeners.key == .musicKitDidLoad {
                    for eventListener in eventListeners.value {
                        eventListener()
                    }
                } else {
                    addEventListenerToMKJS(for: eventListeners.key)
                }
            }
            
        } else if message.name == "eventListenerCallback" {
            guard let eventName = message.body as? String,
                let event = MKEvent(rawValue: eventName),
                let callbacks = eventListenerDict[event] else
            {
                    NSLog("Error: no callback function for event listener \(String(describing: message.body))")
                    return
            }
            for callback in callbacks {
                callback()
            }
            
        } else if message.name == "log" {
            NSLog(String(describing: message.body))
            
        } else if message.name == "throwLoadingError" {
            let errorMessage = (message.body as? String ?? "Error loading webpage")
            throwLoadingError(.loadingFailed(message: errorMessage))
            
            // For promise response, message name should contain a UUID, unique to the pair
            // of success and error handlers, in the format "success_<UUID>" and "error_<UUID>".
            // promiseDict is keyed by "_<UUID>".
        } else if let promiseResponse =
            promiseDict[removingPrefixBefore("_", in: message.name)]
        {
            if message.name.hasPrefix("success") {
                promiseResponse.onSuccess(message.body)
                promiseDict.removeValue(forKey: message.name)
            } else if message.name.hasPrefix("error") {
                promiseResponse.onError(message.body)
                promiseDict.removeValue(forKey: message.name)
            }
            
        } else {
            NSLog("Unhandled script message: \(message.name) - \(message.body)")
        }
    }
        
    private func removingPrefixBefore(
        _ character: String.Element,
        in string: String) -> String
    {
        var newString = string
        if let i = newString.firstIndex(of: character) {
            let start = newString.startIndex
            let end = newString.index(before: i)
            newString.removeSubrange(start...end)
            return newString
        } else {
            return string
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
        throwLoadingError(.navigationFailed(withError: error))
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        throwLoadingError(.navigationFailed(withError: error))
    }
}




// MARK: Models
extension MKWebController {
    /// Encapsulates success and error handlers for promise and
    private struct PromiseResponse {
        let onSuccess: (Any) -> Void
        let onError: (Any) -> Void
        
        let id: String
        let successID: String
        let errorID: String
        
        init(onSuccess: @escaping (Any) -> Void,
             onError: @escaping (Any) -> Void)
        {
            self.onSuccess = onSuccess
            self.onError = onError
            
            // Create unique UUID for promise response, and variants for success and error.
            self.id = "_\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))"
            self.successID = "success\(id)"
            self.errorID = "error\(id)"
        }
    }
    
    
    struct EnhancedJSError: Error, CustomStringConvertible {
        let underlyingError: Error
        let jsString: String

        var description: String {
            return """
            Evaluation of JavaScript string produced an error:
                \(String(describing: underlyingError))
                JavaScript string: \(jsString)
            """
        }
        
        func logIfNeeded() {
            if MusicKit.shared.enhancedErrorLogging {
                if let underlyingError = underlyingError as? WKError,
                    underlyingError.code == WKError.javaScriptResultTypeIsUnsupported
                {
                    // Filter out unsupported type errors, which are common when
                    // JavaScript evaluation returns a promise.
                } else {
                    NSLog(self.description)
                }
            }
        }
    }
}
