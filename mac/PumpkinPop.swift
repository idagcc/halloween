import AppKit
import WebKit

// The native shell owns the window. The bundled game owns its fixed 16:9 stage.
final class GameWebView: WKWebView {
    override func menu(for event: NSEvent) -> NSMenu? { nil }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, WKNavigationDelegate, WKScriptMessageHandler {
    private var window: NSWindow!
    private var webView: GameWebView!
    private var hasLaunched = false
    private var gameURL: URL!
    private let windowed = CommandLine.arguments.contains("--windowed")

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        createMenu()
        guard let bundledGame = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "Game") else {
            showError("The bundled game is missing. Please rebuild or reinstall Pumpkin Pop.")
            return
        }
        gameURL = bundledGame

        let controller = WKUserContentController()
        controller.add(self, name: "pumpkinFullscreen")
        controller.addUserScript(WKUserScript(source: """
            window.pumpkinNative = {
                isFullscreen: false,
                toggleFullscreen() { window.webkit.messageHandlers.pumpkinFullscreen.postMessage('toggle'); }
            };
            """, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = controller
        configuration.websiteDataStore = .default()
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
        configuration.mediaTypesRequiringUserActionForPlayback = []
        webView = GameWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = false
        webView.allowsMagnification = false
        webView.autoresizingMask = [.width, .height]

        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1280, height: 720),
                          styleMask: [.titled, .closable, .miniaturizable, .resizable],
                          backing: .buffered, defer: false)
        window.title = "Pumpkin Pop!"
        window.backgroundColor = NSColor(calibratedRed: 0.05, green: 0.03, blue: 0.09, alpha: 1)
        window.contentAspectRatio = NSSize(width: 16, height: 9)
        window.contentMinSize = NSSize(width: 960, height: 540)
        window.collectionBehavior = [.fullScreenPrimary]
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.contentView = webView
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        // Block remote subresources as well as navigation: this app is entirely offline.
        let rules = #"[{"trigger":{"url-filter":"^https?://"},"action":{"type":"block"}},{"trigger":{"url-filter":"^wss?://"},"action":{"type":"block"}}]"#
        WKContentRuleListStore.default().compileContentRuleList(forIdentifier: "OfflineOnly", encodedContentRuleList: rules) { [weak self] list, error in
            guard let self else { return }
            guard let list, error == nil else {
                self.showError("The offline game could not be prepared: \(error?.localizedDescription ?? "unknown error")")
                return
            }
            self.webView.configuration.userContentController.add(list)
            self.webView.loadFileURL(bundledGame, allowingReadAccessTo: bundledGame.deletingLastPathComponent())
        }
    }

    private func createMenu() {
        let main = NSMenu()
        let appItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About Pumpkin Pop", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Hide Pumpkin Pop", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit Pumpkin Pop", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu
        main.addItem(appItem)
        let gameItem = NSMenuItem()
        let gameMenu = NSMenu(title: "Game")
        let fullscreen = NSMenuItem(title: "Toggle Fullscreen", action: #selector(toggleFullscreen(_:)), keyEquivalent: "f")
        fullscreen.keyEquivalentModifierMask = [.command, .control]
        fullscreen.target = self
        gameMenu.addItem(fullscreen)
        gameItem.submenu = gameMenu
        main.addItem(gameItem)
        let windowItem = NSMenuItem()
        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        windowItem.submenu = windowMenu
        main.addItem(windowItem)
        NSApp.mainMenu = main
        NSApp.windowsMenu = windowMenu
    }

    @objc private func toggleFullscreen(_ sender: Any?) { window.toggleFullScreen(sender) }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "pumpkinFullscreen", message.frameInfo.isMainFrame,
              message.frameInfo.request.url?.standardizedFileURL == gameURL.standardizedFileURL,
              message.body as? String == "toggle" else { return }
        toggleFullscreen(nil)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // All game graphics/audio are embedded. There is no reason to open another page.
        guard navigationAction.targetFrame?.isMainFrame == true,
              let url = navigationAction.request.url,
              url.isFileURL, url.standardizedFileURL == gameURL.standardizedFileURL else {
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        updateFullscreenState()
        guard !hasLaunched else { return }
        hasLaunched = true
        if !windowed {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
                guard let self, !self.window.styleMask.contains(.fullScreen) else { return }
                self.window.toggleFullScreen(nil)
            }
        }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        showError("The game could not be opened: \(error.localizedDescription)")
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        showError("The game stopped unexpectedly. Close and reopen Pumpkin Pop to play again. Saved scores remain on this Mac.")
    }

    private func updateFullscreenState() {
        let isFullscreen = window.styleMask.contains(.fullScreen)
        webView.evaluateJavaScript("""
            if (window.pumpkinNative) {
                window.pumpkinNative.isFullscreen = \(isFullscreen);
                document.dispatchEvent(new Event('pumpkinfullscreenchange'));
            }
            """, completionHandler: nil)
    }

    func windowDidEnterFullScreen(_ notification: Notification) { updateFullscreenState() }
    func windowDidExitFullScreen(_ notification: Notification) { updateFullscreenState() }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        window.makeKeyAndOrderFront(nil)
        return true
    }

    private func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Pumpkin Pop"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.runModal()
        NSApp.terminate(nil)
    }
}

@main
enum PumpkinPop {
    @MainActor
    static func main() {
        let application = NSApplication.shared
        let delegate = AppDelegate()
        application.delegate = delegate
        withExtendedLifetime(delegate) { application.run() }
    }
}
