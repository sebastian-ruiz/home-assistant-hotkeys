//
//  AppDelegate.swift
//  home-assistant-hotkeys
//
//  Created by Sebastian Ruiz on 18/08/19.
//  Copyright © 2019 Sebastian Ruiz. All rights reserved.
//

import Cocoa
//import CoreWLAN
import Alamofire
import SwiftyJSON
import HotKey
import Keys
import LaunchAtLogin

extension String: ParameterEncoding {
    
    public func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        var request = try urlRequest.asURLRequest()
        request.httpBody = data(using: .utf8, allowLossyConversion: false)
        return request
    }
    
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    let statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    var currentSsid: String? = nil
    var visible: Bool = true
    var highlightCheckCount: Int = 0
    var isHighlighted: Bool = false
    
    let keys = [Key.f1, Key.f2, Key.f3, Key.f4, Key.f5, Key.f6, Key.f7, Key.f8, Key.f9, Key.f10, Key.f11, Key.f12]
    var keyCombos: Array<KeyCombo> = []
    var lights: Array<String> = []
    var host: String = ""
    
    var headers: HTTPHeaders = [:]
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        constructMenu()
        loadEnv()
        loadLights()
    }
    
    func loadEnv() {
        let keys = HomeAssistantHotkeysKeys()
        print("key value \(keys)")
        self.host = keys.host
        
        self.headers = [
            "Authorization": "Bearer \(keys.secret)",
            "Accept": "application/json",
            "Content-Type": "application/json"]
    }
    
    func loadLights() {
        Alamofire.request("\(host)/api/states/group.all_lights", method: .get, parameters: nil, encoding: URLEncoding.default, headers: self.headers)
            .responseJSON { response in
                print("")
                print("Request: \(String(describing: response.request))")   // original url request
                print("Result: \(response.result)")                         // response serialization result
                
                if let jsonVal = response.result.value {
                    let json = JSON(jsonVal)
                    print("json output:")
                    print(json.rawValue)
                    print(json["attributes"]["entity_id"])
                    self.lights = json["attributes"]["entity_id"].arrayValue.map { $0.stringValue}
                    self.registerLights(lights: self.lights)
                }
        }
    }
    
    func registerLights(lights: Array<String>) {
        for (index, light) in lights.enumerated() {
            print("Item \(index): \(light)")
            self.keyCombos.append(KeyCombo(key: keys[index], modifiers: []))
            hotKey = HotKey(keyCombo: self.keyCombos[index])
        }
    }
    
    func toggleLight(light: String) {
        Alamofire.request("\(host)/api/services/light/toggle", method: .post, parameters: [:], encoding: "{\"entity_id\": \"" + light + "\"}", headers: self.headers)
            .responseJSON { response in
                print("")
                print("Request: \(String(describing: response.request))")   // original url request
                print("Result: \(response.result)")                         // response serialization result
        }
    }
    
    private var hotKey: HotKey? {
        didSet {
            guard let hotKey = hotKey else {
                return
            }
            hotKey.keyDownHandler = {
                print("key combo \(hotKey.keyCombo)")
                
                let indexOfKey = self.keyCombos.firstIndex(of: hotKey.keyCombo)!
                self.toggleLight(light: self.lights[indexOfKey])
            }
        }
    }
    
    func constructMenu() {
        let menu = NSMenu()
        let launchAtLoginItem = NSMenuItem(title: "Launch at Login", action: #selector(AppDelegate.toggleState(_:)), keyEquivalent: "")
        menu.addItem(launchAtLoginItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusBarItem.menu = menu

        // Set the launchAtLoginItem state to the launch at login state
        launchAtLoginItem.state = LaunchAtLogin.isEnabled ? NSControl.StateValue.on : NSControl.StateValue.off
        
        if let button = self.statusBarItem.button {
            button.title = "lights"
        }
    }
    
    @objc func toggleState(_ sender: NSMenuItem) {
        if sender.state == NSControl.StateValue.on {
            sender.state = NSControl.StateValue.off
            LaunchAtLogin.isEnabled = false
        } else {
            sender.state = NSControl.StateValue.on
            LaunchAtLogin.isEnabled = true
        }
        
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {

    }
}
