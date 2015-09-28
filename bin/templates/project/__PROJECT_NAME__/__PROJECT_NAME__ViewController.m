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

#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

#import <objc/message.h>
#import <objc/runtime.h>
#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import <XWebView/XWebView.h>
#import "__PROJECT_NAME__ViewController.h"

@interface __PROJECT_NAME__ViewController () <CDVWebViewEngineProtocol>
@end

@implementation __PROJECT_NAME__ViewController

- (id<CDVWebViewEngineProtocol>)webViewEngine {
    return self;
}
/*- (UIView *)newCordovaViewWithFrame:(CGRect)bounds {
    return self.engineWebView;
}*/
- (void)parseSettingsWithParser:(NSObject<NSXMLParserDelegate> *)delegate {
    // Parse config.xml which is in this framework instead of main bundle.
    NSBundle *bundle = [NSBundle bundleForClass:__PROJECT_NAME__ViewController.class];
    NSURL *url = [bundle URLForResource:@"config" withExtension:@"xml"];
    NSXMLParser *parser = [[NSXMLParser alloc] initWithContentsOfURL:url];
    if (parser) {
        SEL sel = NSSelectorFromString(@"setConfigParser:");
        struct objc_super s = {self, CDVViewController.class };
        ((void (*)(struct objc_super*, SEL, id))objc_msgSendSuper)(&s, sel, parser);
        parser.delegate = delegate;
        [parser parse];
    } else {
        NSAssert(NO, @"ERROR: config.xml does not exist.");
    }
}

- (void)viewDidLoad {
    struct objc_super s = {self, CDVViewController.superclass };
    ((void (*)(struct objc_super*, SEL))objc_msgSendSuper)(&s, _cmd);
    // TODO: set useragent
}


// CDVWebViewEngineProtocol

- (UIView *)engineWebView {
    return self.scriptObject.channel.webView;
}
- (id)loadRequest:(NSURLRequest *)request {
    return [(WKWebView *)self.engineWebView loadRequest:request];
}
- (id)loadHTMLString:(NSString *)string baseURL:(NSURL *)baseURL {
    return [(WKWebView *)self.engineWebView loadHTMLString:string baseURL:baseURL];
}
- (void)evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^)(id, NSError *))completionHandler {
    return [(WKWebView *)self.engineWebView evaluateJavaScript:javaScriptString completionHandler:completionHandler];
}
- (NSURL *)URL {
    return [(WKWebView *)self.engineWebView URL];
}
- (BOOL) canLoadRequest:(NSURLRequest*)request
{
    return (request != nil);
}
- (instancetype)initWithFrame:(CGRect)frame {
    // for protocol conformance only
    NSAssert(NO, @"Should not reach here!");
    return nil;
}
- (void)updateWithInfo:(NSDictionary *)info {
    // this method seems unused
    NSAssert(NO, @"Not implemented!");
}

@end
