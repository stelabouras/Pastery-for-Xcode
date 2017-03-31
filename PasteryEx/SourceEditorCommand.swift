//
//  AppDelegate.swift
//  Pastery
//
//  Created by Stelios Petrakis on 7/3/17.
//  Copyright © 2017 Stelios Petrakis. All rights reserved.
//

import Foundation
import XcodeKit
import AppKit

enum CommandType: String {
    case selection = "SourceEditorCommandFromSelection"
    case file = "SourceEditorCommandFromFile"
}


class SourceEditorCommand: NSObject, XCSourceEditorCommand {
    
    let endpoint = "https://www.pastery.net/api/paste/"
    
    var defaults : UserDefaults!

    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void ) -> Void {
        
        defaults = UserDefaults(suiteName: "557NA63EQK.group.pastery.xcode.sharedprefs")
        
        guard (defaults != nil), let apiKey = defaults?.string(forKey: "apikey") else {
            
            let error = NSError(domain: "No API key provided, please run the Pastery app first!", code: 123, userInfo: nil)
            
            completionHandler(error)
            
            return
        }

        let secondLine = invocation.buffer.lines.object(at: 1) as? String
        let title = fileName(fromFileNameComment: secondLine, commandInvocation: invocation)
        
        let data = requestDataWith(commandInvocation: invocation)
        let language = codeTypeWith(buffer: invocation.buffer)
        
        postCodeToPastery(title: title, data: data, apiKey: apiKey, language: language) { (error) in
            completionHandler(error)
        }
    }
  
    
    //MARK: - Helper Methods
    
    private func openToBrowser(value: String) -> Void {
        if let url = URL(string: value), NSWorkspace.shared().open(url) { }
    }
    
    private func copyToClipBoard(value: String) -> Void {
        let pasteboard = NSPasteboard.general()
        pasteboard.declareTypes([NSPasteboardTypeString], owner: nil)
        pasteboard.setString(value, forType: NSPasteboardTypeString)
    }
    
    private func fileName(fromFileNameComment comment: String?, commandInvocation: XCSourceEditorCommandInvocation) -> String? {
        
        guard comment != nil else { return nil }

        let isSelection = commandInvocation.commandIdentifier.contains(CommandType.selection.rawValue)

        let comment = comment!.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let commentPrefix = "//"
        guard comment.hasPrefix(commentPrefix) else { return nil }
        
        let startIndex = comment.index(comment.startIndex, offsetBy: commentPrefix.characters.count)
        
        return (isSelection ? "A piece of " : "") + comment[startIndex..<comment.endIndex].trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    //MARK: - Data Handling Methods

    private func codeTypeWith(buffer: XCSourceTextBuffer) -> String {
        
        let types = [("objective-c", "objective-c"),
                     ("com.apple.dt.playground", "swift"),
                     ("swift","swift"),
                     ("c-plus-plus-source","cpp"),
                     ("c-source","c"),
                     ("c-header","c"),
                     ("xml", "xml"),
                     ("markdown", "markdown")]
        
        for type in types {
            if buffer.contentUTI.contains(type.0) {
                return type.1
            }
        }
        return ""
    }
    
    private func getTextSelectionFrom(buffer: XCSourceTextBuffer) -> String {
        
        var text = ""
        
        buffer.selections.forEach { selection in
            guard let range = selection as? XCSourceTextRange else { return }
            
            for l in range.start.line...range.end.line {
                if l >= buffer.lines.count {
                    continue
                }
                guard let line = buffer.lines[l] as? String else { continue }
                text.append(line)
            }
        }
        return text
    }
    
    private func requestDataWith(commandInvocation: XCSourceEditorCommandInvocation) -> Data? {
        var string = ""
        
        if commandInvocation.commandIdentifier.contains(CommandType.selection.rawValue) {
            string = getTextSelectionFrom(buffer: commandInvocation.buffer)
        } else if commandInvocation.commandIdentifier.contains(CommandType.file.rawValue) {
            string = commandInvocation.buffer.completeBuffer
        }

        return string.data(using: String.Encoding.utf8)!
    }
    
    
    //MARK: - Network Methods
    
    private func postCodeToPastery(title: String?, data: Data?, apiKey: String, language: String, completion: @escaping (Error?) -> Void) -> Void {
        
        let maxViews = defaults.integer(forKey: "maxviews")
        let duration = defaults.integer(forKey: "duration")
        
        var urlString = "\(endpoint)?api_key=\(apiKey)"
        
        if language != "" {
        
            urlString += "&language=\(language)"
        }
        
        if maxViews >= 0 {
            
            urlString += "&max_views=\(maxViews)"
        }
        
        if duration > 0 {
            
            urlString += "&duration=\(duration)"
        }
        
        if title != nil {
            
            let escapedTitle = title!.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
            
            if escapedTitle != nil {
                
                urlString += "&title=\(escapedTitle!)"
            }
        }
        
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "POST"
        request.httpBody = data
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(error)
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                completion(NSError(domain: "HTTP status", code: httpStatus.statusCode, userInfo: nil))
                return
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data, options: []) as! [String : Any] {
                if let htmlURL = json["url"] as? String {
                    
                    let copyAfterCreation = self.defaults.bool(forKey: "copyaftercreation")

                    if copyAfterCreation {
                     
                        self.copyToClipBoard(value: htmlURL)
                    }
                    else {
                        
                        self.openToBrowser(value: htmlURL)
                    }
                    
                    completion(nil)
                }
            }
        }
        task.resume()
    }
}
