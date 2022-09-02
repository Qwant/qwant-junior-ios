// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MessageUI
import Shared

class QwantContentBlockerSettingViewController: QwantSettingsTableViewController {
    let prefs: Prefs
    var currentBlockingStrength: QwantBlockingStrength
    
    private lazy var closeButton = {
        return UIBarButtonItem(barButtonSystemItem: .close) { [weak self] _ in
            self?.dismiss(animated: true, completion: nil)
        }
    }()

    init(prefs: Prefs, showCloseButton: Bool = false) {
        self.prefs = prefs
        currentBlockingStrength = QwantBlockingStrength.currentStrength(from: prefs)
        
        super.init(style: .insetGrouped)
        
        title = .TrackingProtectionOptionProtectionLevelTitle
        
        if showCloseButton {
            navigationItem.setRightBarButton(closeButton, animated: false)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func generateSettings() -> [SettingSection] {
        let protectionLevelSetting: [CheckmarkSetting] = QwantBlockingStrength.allCases.map { option in
            let id = QwantBlockingStrength.accessibilityId(for: option)
            let setting = QwantCheckmarkSetting(title: NSAttributedString(string: option.settingTitle), style: .rightSide, subtitle: NSAttributedString(string: option.settingSubtitle), accessibilityIdentifier: id, isChecked: {
                return option == self.currentBlockingStrength
            }, onChecked: {
                self.currentBlockingStrength = option
                if let strength = option.toBlockingStrength {
                    self.prefs.setString(strength.rawValue, forKey: ContentBlockingConfig.Prefs.StrengthKey)
                }
                self.prefs.setBool(option != .deactivated, forKey: ContentBlockingConfig.Prefs.EnabledKey)
                
                QwantTabContentBlocker.prefsChanged()
                self.tableView.reloadData()
                
                if option == .strict {
                    let alert = UIAlertController(title: .TrackerProtectionAlertTitle, message: .TrackerProtectionAlertDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: .TrackerProtectionAlertButton, style: .default, handler: nil))
                    self.present(alert, animated: true)
                }
            })
            
            return setting
        }
        
        let optionalFooterTitle = NSAttributedString(string: .TrackingProtectionLevelFooter)
        let firstSection = SettingSection(footerTitle: optionalFooterTitle, children: protectionLevelSetting)
        
        return [firstSection]
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let _defaultFooter = super.tableView(tableView, viewForFooterInSection: section) as? ThemedTableSectionHeaderFooterView
        guard let defaultFooter = _defaultFooter else {
            return _defaultFooter
        }
        
        if currentBlockingStrength == .strict {
            return defaultFooter
        }
        
        return nil
    }
    
    override func applyTheme() {
        
        tableView.separatorColor = UIColor.theme.tableView.separator
        tableView.backgroundColor = UIColor.theme.qwantVIP.background
        tableView.separatorInset = UIEdgeInsets(top: 0, left: -QwantUX.Spacing.m, bottom: 0, right: 0);
        tableView.reloadData()
    }
}



class LargeSubtitleCell: ThemedTableViewCell {
    static let Identifier = "LargeSubtitleCell"
    
    var title = UILabel()
    var subtitle = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: LargeSubtitleCell.Identifier)
        selectionStyle = .none
        
        title.translatesAutoresizingMaskIntoConstraints = false
        subtitle.translatesAutoresizingMaskIntoConstraints = false
        
        title.font = QwantUX.Font.Text.xl
        
        subtitle.font = QwantUX.Font.Text.s
        subtitle.numberOfLines = 0
        
        contentView.addSubviews(title, subtitle)
        
        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: contentView.topAnchor, constant: QwantUX.Spacing.m),
            title.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: QwantUX.Spacing.m),
            title.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -QwantUX.Spacing.m),
            
            subtitle.topAnchor.constraint(equalTo: title.bottomAnchor),
            subtitle.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: QwantUX.Spacing.m),
            subtitle.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -QwantUX.Spacing.xxxxl),
            subtitle.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -QwantUX.Spacing.m),
        ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func applyTheme(theme: Theme) {
        backgroundColor = UIColor.theme.qwantVIP.sectionColor
        tintColor = UIColor.theme.general.controlTint
        contentView.backgroundColor = UIColor.theme.qwantVIP.sectionColor
        title.textColor = UIColor.theme.qwantVIP.textColor
        subtitle.textColor = UIColor.theme.qwantVIP.subtextColor
        textLabel?.text = nil
        detailTextLabel?.text = nil
    }
}

