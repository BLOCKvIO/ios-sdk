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
        webConfiguration.userContentController.add(self, name: "vatomicBridge")
        webConfiguration.userContentController.add(self, name: "blockvBridge")

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
        self.webView.backgroundColor = UIColor.red.withAlphaComponent(0.3)
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
        }
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
        print(#function)
        self.completion?(nil)
    }

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        // inspect link type
        if navigationAction.navigationType == .linkActivated {
            if let url = navigationAction.request.url {
                // open in Safari.app
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                return decisionHandler(.cancel)
            }
        }
        // allow
        return decisionHandler(.allow)

    }

}
