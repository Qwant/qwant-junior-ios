// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

protocol QwantVIPBase: NotificationThemeable, Notifiable {
    func setupView()
    func setupConstraints()
    func updateViewDetails()
}

class QwantVIPBaseVC: UIViewController, QwantVIPBase {
    
    internal lazy var closeButton = {
        return UIBarButtonItem(barButtonSystemItem: .close) { [weak self] _ in
            self?.dismiss(animated: true, completion: nil)
        }
    }()
    
    internal var constraints = [NSLayoutConstraint]()
    internal var notificationCenter: NotificationProtocol
    
    // MARK: - View lifecycle
    
    init(notificationCenter: NotificationCenter = NotificationCenter.default) {
        self.notificationCenter = notificationCenter
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        notificationCenter.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupNotifications(forObserver: self, observing: [.DisplayThemeChanged, .ContentBlockerDidBlock])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateViewDetails()
        applyTheme()
    }
    
    func setupView() {
        NSLayoutConstraint.deactivate(constraints)
        constraints.removeAll()
        
        setupConstraints()
        
        NSLayoutConstraint.activate(constraints)
    }
    
    func setupConstraints() {
        // Empty implementation
    }
    
    func updateViewDetails() {
        self.navigationItem.setRightBarButton(closeButton, animated: false)
    }
    
    func applyTheme() {
        overrideUserInterfaceStyle = LegacyThemeManager.instance.userInterfaceStyle
        view.backgroundColor = UIColor.theme.qwantVIP.background
        setNeedsStatusBarAppearanceUpdate()
    }
    
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
            case .DisplayThemeChanged:
                applyTheme()
            case .ContentBlockerDidBlock:
                updateViewDetails()
            default: break
        }
    }
}
