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
        println("FAILED: pluginJSON = \(message.body)")
    }
}

// XWVScripting
extension __PROJECT_NAME__ViewController : XWVScripting {
    public func javascriptStub(stub: String) -> String {
        setup()

        let bundle = NSBundle(forClass: __PROJECT_NAME__ViewController.self)
        let dir = (bundle.resourcePath ?? bundle.bundlePath).stringByAppendingPathComponent("www")

        var path = dir.stringByAppendingPathComponent("cordova.js")
        var stub = NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: nil) as? String ?? ""
        if stub.isEmpty {
            println("ERROR: Could not find 'cordova.js' file.")
            return ""
        }

        path = dir.stringByAppendingPathComponent("cordova_plugins.js")
        if let plugins = NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: nil) as? String {
            let object: AnyObject?
#if use_javascriptcore
            let context = JSContext()
            let script = "var cordova = { define: function(_, f){f(null, null, cordova);} }; \(plugins); cordova.exports;"
            object = context.evaluateScript(script).toObjectOfClass(NSArray.self)
#else
            let range = Range(start: find(plugins, "=")!.successor(), end: find(plugins, ";")!)
            let data = plugins[range].dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
            object = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions(0), error: nil)
#endif
            if let modules = object as? [AnyObject] {
                stub = modules.reduce(stub + plugins) {
                    (stub: String, object: AnyObject)->String in
                    if let module = object as? [String: AnyObject], let file = module["file"] as? String {
                        path = dir.stringByAppendingPathComponent(file)
                        if let plugin = NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: nil) {
                            return stub + "\n" + (plugin as! String)
                        } else {
                            println("ERROR: Could not find '\(path)' file.")
                        }
                    }
                    return stub
                }
            }
        }
        return stub
    }
    public static func isSelectorExcludedFromScript(selector: Selector) -> Bool {
        return true
    }
    public static func isKeyExcludedFromScript(name: UnsafePointer<Int8>) -> Bool {
        return true
    }
}
