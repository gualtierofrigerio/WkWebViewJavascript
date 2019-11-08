//
//  WebViewDelegate.swift
//  WkWebViewJavascript
//
//  Created by Gualtiero Frigerio on 06/11/2019.
//  Copyright © 2019 Gualtiero Frigerio. All rights reserved.
//

import Foundation
import WebKit

/// Alias for a callback in JavascriptFunction
/// The Bool parameter is set to false when there was an error while executing the function
/// and it true when it succeded. In this case the second parameter may contain a value
/// with the response returned by the function call
typealias JavascriptCallback = (Bool, Any?) -> Void

/// Struct used to store function string and their callbacks
/// The string must contain the function name and its parameters
/// as it is executed as is by a WebView
/// The callback returns a Bool with false if the execution failed
/// or true if it succeded and there is a Any parameter with the response
/// from the WebView
struct JavascriptFunction {
    var functionString:String
    var callback: JavascriptCallback
}

/// Implement this protocol to be notified about messages received by the WebView
/// via postMessage or parameters sent by the page via a URL starting with nativeapp://
protocol WebViewHandlerDelegate {
    /// Called when a message is received by the WebView
    /// - Parameter message: the message received
    func didReceiveMessage(message:Any)
    
    /// Called when an URL opened in the WebView returns a set of parameters
    /// The function isn't called when is not possible to decode a dictionary from
    /// an URL
    /// - Parameter parameters: A dictionary with the parameters extracted from the URL
    func didReceiveParameters(parameters:[String:Any])
}

/// This class manages a WKWebView. It creates one at init, becomes its navigationDelegate
/// and configures itself as WKScriptMessageHandler.
/// The WKWebView is accessible so its frame can be set by the caller and the view can be added in the hiearchy.
class WebViewHandler: NSObject {
    let webView:WKWebView
    let messageName = "nativeapp"
    var delegate:WebViewHandlerDelegate?
    
    private var pageLoaded = false
    private var pendingFunctions = [JavascriptFunction]()
    
    override init() {
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        
        webView = WKWebView(frame: CGRect.zero, configuration: configuration)
        
        super.init()
        configuration.userContentController.add(self, name: messageName)
        webView.navigationDelegate = self
    }
    
    /// Immediately calls a function if a page is already loaded otherwise puts it in a queue
    /// and executes it after the page is loaded and ready to execute functions
    /// - Parameters:
    ///   - javascriptString: A string representing a javascript function and its parameters
    ///   - callback: The callback called after the function is executed or fails
    func callJavascript(javascriptString:String, callback:@escaping JavascriptCallback) {
        if pageLoaded {
            callJavascriptFunction(function: makeFunction(withString: javascriptString, andCallback: callback))
        }
        else {
            addFunction(function: makeFunction(withString: javascriptString, andCallback: callback))
        }
    }
    
    /// Loads the request with the associated WebView
    /// - Parameter request: The URLRequest to load
    func load(_ request:URLRequest) {
        pageLoaded = false
        webView.load(request)
    }
}

//MARK: - Private functions

extension WebViewHandler {
    /// Adds a function to the array of pending functions
    /// - Parameter function: the JavascriptFunction struct containing the string and the callback
    private func addFunction(function:JavascriptFunction) {
        pendingFunctions.append(function)
    }
    
    /// Call a function via evaluateJavascript on the WebView
    /// - Parameter function: the Javascript function to execute
    private func callJavascriptFunction(function:JavascriptFunction) {
        webView.evaluateJavaScript(function.functionString) { (response, error) in
            if let _ = error {
                function.callback(false, nil)
            }
            else {
                function.callback(true, response)
            }
        }
    }
    
    /// Call all the pending functions and clears the array afterwards
    private func callPendingFunctions() {
        for function in pendingFunctions {
            callJavascriptFunction(function: function)
        }
        pendingFunctions.removeAll()
    }
    
    /// Convenience method to create a JavascriptFunction object from a string and a callback
    /// - Parameters:
    ///   - withString: A string with a function name and its parameters
    ///   - andCallback: The closure called after the function is executed or fails
    private func makeFunction(withString string:String, andCallback callback:@escaping JavascriptCallback) -> JavascriptFunction {
        JavascriptFunction(functionString: string, callback: callback)
    }
}

//MARK: - WKNavigationDelegate

extension WebViewHandler: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        pageLoaded = true
        callPendingFunctions()
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let url = navigationAction.request.url
        if let urlString = url?.absoluteString,
            urlString.starts(with: messageName),
            let parameters = ParametersHandler.decodeParameters(inString: url!.absoluteString) {
            delegate?.didReceiveParameters(parameters: parameters)
        }
        decisionHandler(.allow)
    }
}

//MARK: - WKScriptMessageHandler

extension WebViewHandler: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == messageName {
            if let body = message.body as? [String:AnyObject] {
                delegate?.didReceiveMessage(message: body)
            }
            else if let body = message.body as? String {
                if let parameters = ParametersHandler.decodeParameters(inString: body) {
                    delegate?.didReceiveParameters(parameters: parameters)
                }
            }
        }
    }
}
