# Cordova XWebView

# Introduction

Cordova XWebView is a customized platform of [Cordova](http://cordova.apache.org/) for [XWebView](https://github.com/XWebView/XWebView). It helps to reuse existing Cordova plugins with XWebView. You can easily create an XWebView plugin project which includes Cordova plugins by using Corodova CLI commands.

Cordova XWebView is based on Cordova iOS 4.0.x which is a developement branch currently. Some Cordova plugins may not work well with it.

## Quick Start

1. [Install the Cordova CLI](http://http://cordova.apache.org/docs/en/edge/guide_cli_index.md.html#The%20Command-Line%20Interface_installing_the_cordova_cli)

2. [Creat a Cordova project](http://http://cordova.apache.org/docs/en/edge/guide_cli_index.md.html#The%20Command-Line%20Interface_create_the_app)

   It should not include HTML files in XWebView plugin, so use the `--copy-from` with an empty directory is recommended.
   ```
   cordova create Hello com.example.hello HelloWorld --copy-from=/an/empty/dir
   ```

3. Add the Cordova XWebView platform

   ```
   cordova platform add https://github.com/xwebview/cordova-xwv.git#4.0.x
   ```

4. [Add Cordova plugins](http://http://cordova.apache.org/docs/en/edge/guide_cli_index.md.html#The%20Command-Line%20Interface_add_plugin_features)

5. [Build the plugin]

   Open the Xcode project in `platform/ios` directory or use CLI:
   ```
   cordova build ios
   ```
   Becuase the target is a dynamic library, you can't run it on emulator.
