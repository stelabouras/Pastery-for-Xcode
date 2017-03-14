//
//  AppDelegate.swift
//  Pastery
//
//  Created by Stelios Petrakis on 7/3/17.
//  Copyright © 2017 Stelios Petrakis. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    
    @IBOutlet weak var maxViewsTextField: NSTextField!
    @IBOutlet weak var expiresPullDown: NSPopUpButton!
    @IBOutlet weak var apiKeyTextField: NSTextField!
    @IBOutlet weak var openInBrowserRadioButton: NSButton!
    @IBOutlet weak var copyToClipboardRadioButton: NSButton!
    
    var defaults : UserDefaults!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        defaults = UserDefaults(suiteName: "557NA63EQK.group.pastery.xcode.sharedprefs")!

        let apiKey = defaults.string(forKey: "apikey")
        
        if apiKey != nil {
            
            apiKeyTextField.stringValue = apiKey!
        }

        let expires = defaults.integer(forKey: "duration")

        if !isKeyPresentInUserDefaults(key: "duration") {
            
            expiresPullDown.selectItem(withTag: 1440)
        }
        else {
            
            expiresPullDown.selectItem(withTag: expires)
        }
        
        let maxViews = defaults.integer(forKey: "maxviews")
        
        if maxViews > 0 {
            
            maxViewsTextField.integerValue = maxViews
        }
        
        let copyAfterCreation = defaults.bool(forKey: "copyaftercreation")
        
        if copyAfterCreation {
            
            openInBrowserRadioButton.state = 0;
            copyToClipboardRadioButton.state = 1;
        }
        else {
            openInBrowserRadioButton.state = 1;
            copyToClipboardRadioButton.state = 0;
        }
    }

    @IBAction func updateButtonClicked(_ sender: Any) {
     
        self.apiKeyChanged(NSNull())
        self.expiredChanged(NSNull())
        self.maxViewsChanged(NSNull())
    }
    
    @IBAction func apiKeyChanged(_ sender: Any) {
    
        self.apiKeyTextField.layer?.borderWidth = 0

        let apiKey = apiKeyTextField.stringValue
        
        if apiKey == "" {
            
            return
        }
        
        var request = URLRequest(url: URL(string: "https://www.pastery.net/api/paste/?api_key=\(apiKey)")!)
        request.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            guard error == nil else {

                self.updateAPIkey(isWrong: true)
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {

                self.updateAPIkey(isWrong: true)
                return
            }
            
            self.updateAPIkey(isWrong: false)
            
            self.defaults.set(apiKey, forKey: "apikey")
        }
        
        task.resume()
    }
    
    @IBAction func expiredChanged(_ sender: Any) {

        let expires = expiresPullDown.selectedTag()
        
        if expires >= 0 {
            
            defaults.set(expires, forKey: "duration")
        }
    }


    @IBAction func maxViewsChanged(_ sender: Any) {

        let maxViews = maxViewsTextField.integerValue
        
        if maxViews > 0 {
            
            defaults.set(maxViews, forKey: "maxviews")
        }
    }
    
    @IBAction func copyToClipboardChanged(_ sender: Any) {

        openInBrowserRadioButton.state = 0;

        defaults.set(true, forKey: "copyaftercreation")
    }
    
    @IBAction func openInBrowserChanged(_ sender: Any) {

        copyToClipboardRadioButton.state = 0;
        
        defaults.set(false, forKey: "copyaftercreation")
    }
    
    @IBAction func visitClicked(_ sender: Any) {
        
        if let url = URL(string: "https://pastery.net"), NSWorkspace.shared().open(url) { }
    }
    
    //MARK: - Helper methods
    
    func updateAPIkey(isWrong: Bool) {
        
        DispatchQueue.main.async {
         
            self.apiKeyTextField.layer?.borderWidth = 1.0
            
            if isWrong {
                
                self.apiKeyTextField.layer?.borderColor = NSColor(deviceRed: 0.991, green: 0.675, blue: 0.601, alpha: 1.0).cgColor
                
                let alert = NSAlert()
                alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
                alert.messageText = NSLocalizedString("Wrong API key", comment: "")
                alert.informativeText = NSLocalizedString("The API you entered was wrong. Try again.", comment: "")
                alert.runModal()
            }
            else {
             
                self.apiKeyTextField.layer?.borderColor = NSColor(deviceRed: 0.371, green: 0.726, blue: 0.488, alpha: 1.0).cgColor
            }
        }
    }
    
    func isKeyPresentInUserDefaults(key: String) -> Bool {
        return defaults.object(forKey: key) != nil
    }
}

