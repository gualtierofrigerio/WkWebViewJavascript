//
//  ParametersHandler.swift
//  WkWebViewJavascript
//
//  Created by Gualtiero Frigerio on 01/11/2019.
//  Copyright © 2019 Gualtiero Frigerio. All rights reserved.
//

import Foundation

/// This class has only static function to encode and decode parameters
/// from URLs and to enconde and decode JSON objects from strings
class ParametersHandler {
    static let urlPrefix = "nativeapp://"
    
    
    /// Decode the parameters in a string
    /// The function transforms the encoding characters so the string can be passed
    /// directly from an URL intercepted by a WebView
    /// - Parameter parametersString: the string containing the parameters to decode
    /// - Returns: An optional dictionary of [String:Any] with the parameters names and their values
    class func decodeParameters(inString parametersString:String) -> [String:Any]? {
        if let convertedString = parametersString.removingPercentEncoding,
           let queryItems = URLComponents(string:convertedString)?.queryItems {
            var parameters:[String:Any] = [:]
            for item in queryItems {
                parameters[item.name] = item.value ?? ""
            }
            return parameters
        }
        return nil
    }
    /// Decode the parameters in a string encoded in Base64
    /// The function decodes the Base64 string and tries to decode the parameters in it
    /// - Parameter parametersString: the string containing the parameters to decode
    /// - Returns: An optional dictionary of [String:Any] with the parameters names and their values
    class func decodeParametersBase64(inString parametersString:String) -> [String:Any]? {
        if parametersString.hasPrefix(urlPrefix) {
            let str = parametersString.replacingOccurrences(of: urlPrefix, with: "")
            if let decodedData = Data(base64Encoded: str),
               let decodedString = String(data: decodedData, encoding: .utf8) {
                return ParametersHandler.decodeParameters(inString: decodedString)
            }
        }
        return nil
    }
    
    /// Looks for a particular parameter in a string.
    /// The function transforms the encoding characters so the string can be passed
    /// directly from an URL intercepted by a WebView
    /// - Parameters:
    ///   - parameterName: the name of the parameter to get
    ///   - parametersString: the string to decode
    /// - Returns: an optional value associated to the name requested
    class func getParameter(_ parameterName:String, inString parametersString:String) -> Any? {
        if let decodedString = parametersString.removingPercentEncoding,
           let queryItems = URLComponents(string:decodedString)?.queryItems {
           let parameter = queryItems.filter({$0.name == parameterName}).first
            return parameter?.value
        }
        else {
            return nil
        }
    }
    
    /// Returns a JSON object from a string
    /// The function removed enconding characters from the string if present
    /// - Parameter fromString: the string containing the JSON
    /// - Returns: an optional Any object if it was possible to decode a JSON from the string
    class func getJSON(fromString jsonString:String) -> Any? {
        if let data = jsonString.removingPercentEncoding?.data(using: .utf8),
           let jsonObject = try? JSONSerialization.jsonObject(with:data , options: .allowFragments) {
                return jsonObject
        }
        return nil
    }
    
    /// Builds a string from a JSON object like a dictionary or an array
    /// - Parameter fromObject: the object to encode as string
    /// - Returns: an optional string if it was possible to encode the object as a JSON string
    class func getString(fromObject jsonObject:Any) -> String? {
        if let data = try? JSONSerialization.data(withJSONObject: jsonObject, options: .fragmentsAllowed),
           let string = String(data: data, encoding: .utf8) {
            return string
        }
        return nil
    }
}
