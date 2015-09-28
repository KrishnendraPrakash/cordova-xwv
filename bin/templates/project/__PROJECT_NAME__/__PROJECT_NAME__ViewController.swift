/*
 Copyright 2015 XWebView

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
*/

import Foundation
import WebKit
import XWebView

// WKNavigationDelegate
extension __PROJECT_NAME__ViewController : WKNavigationDelegate {
    public func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        let notification = NSNotification(name: CDVPageDidLoadNotification, object: webView)
        NSNotificationCenter.defaultCenter().postNotification(notification)
    }

    private func setup() {
        // TODO: should not clobber user's delegates
        // TODO: add default implementation for UIDelegate
        let webview = scriptObject!.channel.webView!
        webview.navigationDelegate = self as WKNavigationDelegate
        if let UIDelegate = self as? WKUIDelegate {
            webview.UIDelegate = UIDelegate
        }

        let conf = webview.configuration
        conf.preferences.minimumFontSize = settings.cordovaFloatSettingForKey("MinimumFontSize", defaultValue: 0.0)
        // TODO: A typo of upstream? Should be "AllowsInlineMediaPlayback"?
        conf.allowsInlineMediaPlayback = settings.cordovaBoolSettingForKey("AllowInlineMediaPlayback", defaultValue: false)
        conf.mediaPlaybackRequiresUserAction = settings.cordovaBoolSettingForKey("MediaPlaybackRequiresUserAction", defaultValue: true)
        conf.suppressesIncrementalRendering = settings.cordovaBoolSettingForKey("SuppressesIncrementalRendering", defaultValue: false)
        conf.mediaPlaybackAllowsAirPlay = settings.cordovaBoolSettingForKey("MediaPlaybackAllowsAirPlay", defaultValue: true)
        webview.scrollView.bounces = settings.cordovaBoolSettingForKey("DisallowOverscroll", defaultValue: false)
    }
}

// WKScriptMessageHandler
extension __PROJECT_NAME__ViewController : WKScriptMessageHandler {
    public func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        if let jsonEntry = message.body as? [AnyObject] {
            let command = CDVInvokedUrlCommand(fromJson: jsonEntry)
            if commandQueue.execute(command) {
                return
            }
        }
        print("FAILED: pluginJSON = \(message.body)")
    }
}

// XWVScripting
extension __PROJECT_NAME__ViewController : XWVScripting {
    public func javascriptStub(stub: String) -> String {
        setup()

        let bundle = NSBundle(forClass: __PROJECT_NAME__ViewController.self)
        let dir = (bundle.resourcePath ?? bundle.bundlePath) + "/www"
        guard let stub = stringFromFile(dir + "/cordova.js"),
              let plugins = stringFromFile(dir + "/cordova_plugins.js") else {
            print("ERROR: Could not find 'cordova.js' or 'cordova_plugins.js' file.")
            return ""
        }

        let array: AnyObject?
#if use_javascriptcore
        let script = "var cordova = { define: function(_, f){f(null, null, cordova);} }; \(plugins); cordova.exports;"
        array = JSContext().evaluateScript(script).toObjectOfClass(NSArray.self)
#else
        if let start = plugins.characters.indexOf("=")?.successor(), end = plugins.characters.indexOf(";") {
            let data = plugins[start ..< end].dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
            array = try? NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions(rawValue: 0))
        } else {
            array = nil
        }
#endif
        guard let modules = array as? [AnyObject] else {
            print("ERROR: Could not parse 'cordova_plugins.js' file.")
            return ""
        }

        return modules.reduce(stub + plugins) {
            (stub: String, item: AnyObject)->String in
            if let module = item as? [String: AnyObject], let file = module["file"] as? String {
                let path = "\(dir)/\(file)"
                if let plugin = stringFromFile(path) {
                    return stub + "\n" + plugin
                } else {
                    print("ERROR: Could not find '\(path)' file.")
                }
            }
            return stub
        }
    }
    public static func isSelectorExcludedFromScript(selector: Selector) -> Bool {
        return true
    }
    public static func isKeyExcludedFromScript(name: UnsafePointer<Int8>) -> Bool {
        return true
    }

    private func stringFromFile(name: String, encoding: UInt = NSUTF8StringEncoding) -> String? {
        return try? NSString(contentsOfFile: name, encoding: encoding) as String
    }
}
