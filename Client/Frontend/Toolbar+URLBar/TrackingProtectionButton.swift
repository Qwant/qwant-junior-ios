// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit

class TrackingProtectionButton: UIButton, NotificationThemeable {
    
    private lazy var badgeLabel: UILabel = .build { label in
        label.font = .systemFont(ofSize: 10, weight: .bold)
        label.layer.zPosition = 1
        label.layer.masksToBounds = false
        label.textAlignment = .center
    }
    
    // MARK: - Initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        applyTheme()
        
        addSubview(badgeLabel)
        
        NSLayoutConstraint.activate([
            badgeLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            badgeLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        
        setImage(UIImage(imageLiteralResourceName: "tracking_protection_on"), for: .normal)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func applyTheme() {
        badgeLabel.textColor = UIColor.theme.qwantVIP.blackText
        badgeLabel.layer.backgroundColor = UIColor.clear.cgColor
    }
    
    func setBadgeValue(value: Int) {
        guard value > 0 else {
            badgeLabel.isHidden = true
            return
        }
        badgeLabel.isHidden = false
        badgeLabel.text = value < 100 ? String(describing: value) : "99+"
    }
    
    func animateIfNeeded() {
        let value = Int(badgeLabel.text ?? "") ?? 0
        if value > 0 {
            increaseAnimation()
        }
    }
}
