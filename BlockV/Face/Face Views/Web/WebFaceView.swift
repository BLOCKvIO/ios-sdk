//
//  BlockV AG. Copyright (c) 2018, all rights reserved.
//
//  Licensed under the BlockV SDK License (the "License"); you may not use this file or
//  the BlockV SDK except in compliance with the License accompanying it. Unless
//  required by applicable law or agreed to in writing, the BlockV SDK distributed under
//  the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
//  ANY KIND, either express or implied. See the License for the specific language
//  governing permissions and limitations under the License.
//

import Foundation
import WebKit

/// Wraps WKScriptMessageHandler as a weak delegate.
///
/// Context: `WKUserContentController` holds a strong reference to its delegate. This may cause memory leaks.
///
/// - see:
/// https://stackoverflow.com/a/26383032/3589408
class LeakAvoider: NSObject, WKScriptMessageHandler {
    /// Hold a weak reference to the `WKScriptMessageHandler`.
    weak var delegate: WKScriptMessageHandler?
    init(delegate: WKScriptMessageHandler) {
        self.delegate = delegate
        super.init()
    }
    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        self.delegate?.userContentController(
            userContentController, didReceive: message)
    }
}

/// Web face view.
///
/// Displays webage where the url is specified by the display URL of the face model.
class WebFaceView: FaceView {

    class var displayURL: String { return "https://*" }

    // MARK: - Properties

    /// Web view to display remote face code.
    lazy var webView: WKWebView = {

        // config
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.dataDetectorTypes = .all
        webConfiguration.allowsInlineMediaPlayback = true
        webConfiguration.allowsAirPlayForMediaPlayback = true
        webConfiguration.mediaTypesRequiringUserActionForPlayback = []
        webConfiguration.userContentController.add(LeakAvoider(delegate: self), name: "vatomicBridge")
        webConfiguration.userContentController.add(LeakAvoider(delegate: self), name: "blockvBridge")

        // content controller
        let webView = WKWebView(frame: self.bounds, configuration: webConfiguration)
        webView.navigationDelegate = self
        webView.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
        return webView

    }()

    /// Bridge into core
    var coreBridge: CoreBridge?

    // MARK: - Initialization

    required init(vatom: VatomModel, faceModel: FaceModel) {
        super.init(vatom: vatom, faceModel: faceModel)

        self.addSubview(webView)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) should not be called on Face Views. Please use VatomView.")
    }

    // MARK: - Face View Life cycle

    var isLoaded: Bool = false

    var timer: Timer?

    /// Holds the completion handler.
    private var completion: ((Error?) -> Void)?

    func load(completion: ((Error?) -> Void)?) {
        // store the completion
        self.completion = completion
        self.loadFace()
    }

    func vatomChanged(_ vatom: VatomModel) {
        // if the vatom has changed, load the face url again
        if vatom.id != self.vatom.id {
            self.loadFace()
            return
        }
        self.coreBridge?.sendVatom(vatom)
        // fetch first-level children
        let children = self.vatom.listCachedChildren()
        self.coreBridge?.sendVatomChildren(children)
    }

    func unload() {
        self.webView.stopLoading()
    }

    // MARK: - Methods

    private func loadFace() {
        let faceURL = faceModel.properties.displayURL
        guard let url = URL.init(string: faceURL) else {
            printBV(error: "Cannot initialise URL from: \(faceURL)")
            return
        }
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 20)
        self.webView.load(request)
    }

}

// MARK: - WKNavigation Delegate

extension WebFaceView: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.completion?(nil)
    }

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        // inspect link type
        if navigationAction.navigationType == .linkActivated {
            if let url = navigationAction.request.url {
                // open in Safari.app
                UIApplication.shared.open(url,
                                          options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]),
                                          completionHandler: nil)
                return decisionHandler(.cancel)
            }
        }
        // allow
        return decisionHandler(.allow)

    }

}

// Helper function inserted by Swift 4.2 migrator.
private func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any])
    -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in
        (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)
    })
}
