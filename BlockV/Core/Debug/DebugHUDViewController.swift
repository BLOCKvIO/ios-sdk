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

/// UIWindow subclass which is designed to be set at the top-level window.
///
/// All events are passed through to underlying windows expect if the view conforms the `FloatingView` protocol. In
/// this case, the touch events will forwarded to the view itself.
class FloatingHUDWindow: UIWindow {

    init() {
        super.init(frame: UIScreen.main.bounds)
        backgroundColor = nil
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Determine whether the hit test should be
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {

        let hitView = super.hitTest(point, with: event)
        // check if this window should handle this event
        if hitView!.self is FloatingView {
            return hitView
        }
        // indicates this window does not handle this event
        return nil

    }

}

/// A view controller which provides a context for a floating HUD.
///
/// Initialising this view controller will create a floating HUD using an instance of the `FloatingHUDWindow`.
///
/// HUD content should be added as a subview to the view controller's view. If the view's need to capture touch events
/// they should conform to the `FloatingView` protocol.
class DebugHUDViewController: UIViewController {

    // MARK: - Properties

    lazy var socketContentView: SocketContentView = {
        let view = SocketContentView()
        view.cornerRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.gray.withAlphaComponent(0.4)

        return view
    }()

    private let window = FloatingHUDWindow()

    // MARK: - Initializer

    init() {
        super.init(nibName: nil, bundle: nil)
        window.windowLevel = UIWindow.Level(rawValue: CGFloat.greatestFiniteMagnitude)
        window.isHidden = false
        window.rootViewController = self
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow),
                                               name: UIResponder.keyboardDidShowNotification,
                                               object: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setup()
    }

    var socketContentViewCenterXContraint: NSLayoutConstraint?
    var socketContentViewCenterYContraint: NSLayoutConstraint?

    private func setup() {

        // socket content
        self.view.addSubview(socketContentView)

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panDidFire))
        socketContentView.addGestureRecognizer(panGesture)

        // constraints
        socketContentViewCenterXContraint = socketContentView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor,
                                                                                       constant: 0)
        socketContentViewCenterXContraint?.isActive = true

        socketContentViewCenterYContraint = socketContentView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor,
                                                                                       constant: 0)
        socketContentViewCenterYContraint?.isActive = true

        socketContentView.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.25).isActive = true
        socketContentView.widthAnchor.constraint(equalTo: socketContentView.heightAnchor, multiplier: 1).isActive = true

    }

    // MARK: - Section

    @objc func panDidFire(pan: UIPanGestureRecognizer) {

        socketContentView.layoutIfNeeded()

        let offset = pan.translation(in: self.view)
        pan.setTranslation(CGPoint.zero, in: self.view)

        socketContentViewCenterXContraint?.constant += offset.x
        socketContentViewCenterYContraint?.constant += offset.y

    }

    @objc func keyboardDidShow(note: NSNotification) {
        window.windowLevel = UIWindow.Level(rawValue: 0)
        window.windowLevel = UIWindow.Level(rawValue: CGFloat.greatestFiniteMagnitude)
    }

}

// MARK: - Helpers

/// Protocol that indicates a view is a floating view. This allows for hit testing.
protocol FloatingView where Self: UIView { }

/// Simple subclass of UIView that conforms to FloatingView. Use this subsclass to add interactable content on a
/// floating window.
class ContentView: UIView, FloatingView { }
