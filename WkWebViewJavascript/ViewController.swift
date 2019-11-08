//
//  ViewController.swift
//  WkWebViewJavascript
//
//  Created by Gualtiero Frigerio on 01/11/2019.
//  Copyright © 2019 Gualtiero Frigerio. All rights reserved.
//

import UIKit
import WebKit

class ViewController: UIViewController {
    
    private var webViewHandler:WebViewHandler?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createWebView()
        callInitFunction()
    }

    func createWebView() {
        let webViewHandler = WebViewHandler()
        webViewHandler.delegate = self
        webViewHandler.webView.frame = self.view.frame
        self.view.addSubview(webViewHandler.webView)
        self.webViewHandler = webViewHandler
    }
    
    func callInitFunction() {
        guard let webViewHandler = webViewHandler else {return}
        let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "html")
        let request = URLRequest(url: url!)
        webViewHandler.load(request)
        let functionString = "initPage(false)"
        webViewHandler.callJavascript(javascriptString: functionString) { (success, result) in
            if let result = result {
                print(result)
            }
        }
    }
}

extension ViewController: WebViewHandlerDelegate {
    func didReceiveMessage(message: Any) {
        print(message)
        if let messageDictionary = message as? [String:AnyObject] {
            if messageDictionary["parameter1"] != nil {
                let functionName = "receiveJSON"
                let object = ["parameter" : "value"]
                if let objectString = ParametersHandler.getString(fromObject: object) {
                    let functionString = functionName + "(" + objectString + ")"
                    webViewHandler?.callJavascript(javascriptString: functionString, callback: { success,result in
                        print(result)
                    })
                }
            }
        }
    }
    
    func didReceiveParameters(parameters: [String : Any]) {
        print(parameters)
    }
    
    
}

