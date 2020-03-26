//
//  BLOCKv AG. Copyright (c) 2018, all rights reserved.
//
//  Licensed under the BLOCKv SDK License (the "License"); you may not use this file or
//  the BLOCKv SDK except in compliance with the License accompanying it. Unless
//  required by applicable law or agreed to in writing, the BLOCKv SDK distributed under
//  the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
//  ANY KIND, either express or implied. See the License for the specific language
//  governing permissions and limitations under the License.
//

import UIKit

enum HUDStatus {
    case green
    case orange
    case red
}

/// Controller object that interacts with the web socket.
class SocketInstrument {

    private let pingInterval: TimeInterval = 5

    private var timer: Timer!

    fileprivate var statusHandler: ((_ status: HUDStatus) -> Void)?

    init() {

        // listen to web socket lifecycle events
        BLOCKv.socket.onDisconnected.subscribe(with: self) { [weak self] _ in
            self?.statusHandler?(.red)
        }

        BLOCKv.socket.onConnected.subscribe(with: self) { [weak self] _ in
            self?.statusHandler?(.green)
        }

        DispatchQueue.main.async {
            self.activate(pingInterval: self.pingInterval)
        }
    }

    private func activate(pingInterval: TimeInterval) {

        // create timer
        self.timer = Timer.scheduledTimer(withTimeInterval: pingInterval, repeats: true) { [weak self] _ in

            /*
             Technical:
             A pong must
             */

            var didTimeout = false

            BLOCKv.socket.writePing(completion: {

                if didTimeout {
                    self?.statusHandler?(.red)
                } else {
                    self?.statusHandler?(.green)
                }

            })

            // fire a timeout 0.1 seconds before the next ping
            DispatchQueue.main.asyncAfter(deadline: .now() + pingInterval - 0.1, execute: {
                didTimeout = true
            })

        }

    }

}

// MARK: - Socket Content View

class SocketContentView: RoundedView {

    // MARK: - Properties

    private var didSetupConstraints = false

    lazy var statusDotView: CircleView = {
        let view = CircleView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .red
        return view
    }()

    // controller object to interact with the model
    var socketInstrument: SocketInstrument!

    // MARK: - Initializer

    init() {
        super.init(frame: CGRect.zero)
        self.commonInit()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func commonInit() {
        self.addSubview(statusDotView)
        self.setNeedsUpdateConstraints()
        self.socketInstrument = SocketInstrument()

        socketInstrument.statusHandler = pulse(status:)
    }

    // MARK: - Lifecycle

    override func updateConstraints() {

        if !didSetupConstraints {

            statusDotView.widthAnchor.constraint(equalToConstant: 12).isActive = true
            statusDotView.heightAnchor.constraint(equalToConstant: 12).isActive = true
            statusDotView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 12).isActive = true
            statusDotView.topAnchor.constraint(equalTo: self.topAnchor, constant: 12).isActive = true

            didSetupConstraints = true
        }

        super.updateConstraints()
    }

    // MARK: - Updates

    private func pulse(status: HUDStatus) {
        switch status {
        case .green:
            statusDotView.backgroundColor = .green
        case .orange:
            statusDotView.backgroundColor = .orange
        case .red:
            statusDotView.backgroundColor = .red
        }
        statusDotView.pulse()
    }

}

// MARK: - Helper Views

/// Create a view with rounded edges.
class RoundedView: ContentView {

    var cornerRadius: CGFloat = 0

    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = cornerRadius
    }

}

/// Creates a round UIView.
class CircleView: UIView {

    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = self.bounds.size.width/2
    }

}

extension CircleView: Pulseable { }

protocol Pulseable where Self: UIView {
    func pulse()
}

extension Pulseable {

    func pulse() {
        let pulseAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.opacity))
        pulseAnimation.duration = 1
        pulseAnimation.fromValue = 1
        pulseAnimation.toValue = 0.2
        pulseAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = 1
        self.layer.add(pulseAnimation, forKey: "animateOpacity")
    }

}
