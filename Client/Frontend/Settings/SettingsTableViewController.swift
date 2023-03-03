// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Account
import Shared
import UIKit

struct SettingsUX {
    static let TableViewHeaderFooterHeight = CGFloat(44)
}

extension UILabel {
    // iOS bug: NSAttributed string color is ignored without setting font/color to nil
    func assign(attributed: NSAttributedString?, theme: Theme) {
        guard let attributed = attributed else { return }
        let attribs = attributed.attributes(at: 0, effectiveRange: nil)
        if attribs[NSAttributedString.Key.foregroundColor] == nil {
            // If the text color attribute isn't set, use textPrimary
            textColor = theme.colors.textPrimary
        } else {
            textColor = nil
        }
        attributedText = attributed
    }

    func heightForLabel(_ label: UILabel, width: CGFloat, text: String?) -> CGFloat {
        guard let text = text else { return 0 }

        let size = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        let attrs = [NSAttributedString.Key.font: label.font as Any]
        let boundingRect = NSString(string: text).boundingRect(
            with: size,
            options: .usesLineFragmentOrigin,
            attributes: attrs,
            context: nil)
        return boundingRect.height
    }
}

// A base setting class that shows a title. You probably want to subclass this, not use it directly.
class Setting: NSObject {
    fileprivate var _title: NSAttributedString?
    fileprivate var _footerTitle: NSAttributedString?
    fileprivate var _cellHeight: CGFloat?
    fileprivate var _image: UIImage?
    var theme: Theme!

    weak var delegate: SettingsDelegate?

    // The url the SettingsContentViewController will show, e.g. Licenses and Privacy Policy.
    var url: URL? { return nil }

    // The title shown on the pref.
    var title: NSAttributedString? { return _title }
    var footerTitle: NSAttributedString? { return _footerTitle }
    var cellHeight: CGFloat? { return _cellHeight}
    fileprivate(set) var accessibilityIdentifier: String?

    // An optional second line of text shown on the pref.
    var status: NSAttributedString? { return nil }

    // Whether or not to show this pref.
    var hidden: Bool { return false }

    var style: UITableViewCell.CellStyle { return .subtitle }

    var accessoryType: UITableViewCell.AccessoryType { return .none }

    var accessoryView: UIImageView? { return nil }

    var textAlignment: NSTextAlignment { return .natural }

    var image: UIImage? { return _image }

    var enabled: Bool = true

    func accessoryButtonTapped() { onAccessoryButtonTapped?() }
    var onAccessoryButtonTapped: (() -> Void)?

    // Called when the cell is setup. Call if you need the default behaviour.
    func onConfigureCell(_ cell: UITableViewCell, theme: Theme) {
        self.theme = theme
        cell.detailTextLabel?.assign(attributed: status, theme: theme)
        cell.detailTextLabel?.attributedText = status
        cell.detailTextLabel?.numberOfLines = 0
        cell.textLabel?.assign(attributed: title, theme: theme)
        cell.textLabel?.textAlignment = textAlignment
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.lineBreakMode = .byTruncatingTail
        cell.accessoryType = accessoryType
        cell.accessoryView = accessoryView
        cell.selectionStyle = enabled ? .default : .none
        cell.accessibilityIdentifier = accessibilityIdentifier
        cell.imageView?.image = _image
        if let title = title?.string {
            if let detailText = cell.detailTextLabel?.text {
                cell.accessibilityLabel = "\(title), \(detailText)"
            } else if let status = status?.string {
                cell.accessibilityLabel = "\(title), \(status)"
            } else {
                cell.accessibilityLabel = title
            }
        }
        cell.accessibilityTraits = UIAccessibilityTraits.button
        cell.indentationWidth = 0
        cell.layoutMargins = .zero

        let backgroundView = UIView()
        backgroundView.backgroundColor = theme.colors.layer5Hover
        backgroundView.bounds = cell.bounds
        cell.selectedBackgroundView = backgroundView

        // So that the separator line goes all the way to the left edge.
        cell.separatorInset = .zero
        if let cell = cell as? ThemedTableViewCell {
            cell.applyTheme(theme: theme)
        }
    }

    // Called when the pref is tapped.
    func onClick(_ navigationController: UINavigationController?) { return }

    // Called when the pref is long-pressed.
    func onLongPress(_ navigationController: UINavigationController?) { return }

    // Helper method to set up and push a SettingsContentViewController
    func setUpAndPushSettingsContentViewController(_ navigationController: UINavigationController?, _ url: URL? = nil) {
        if let url = self.url {
            let viewController = SettingsContentViewController()
            viewController.settingsTitle = self.title
            viewController.url = url
            navigationController?.pushViewController(viewController, animated: true)
        }
    }

    init(title: NSAttributedString? = nil, footerTitle: NSAttributedString? = nil, cellHeight: CGFloat? = nil, delegate: SettingsDelegate? = nil, enabled: Bool? = nil) {
        self._title = title
        self._footerTitle = footerTitle
        self._cellHeight = cellHeight
        self.delegate = delegate
        self.enabled = enabled ?? true
    }
}

// A setting in the sections panel. Contains a sublist of Settings
class SettingSection: Setting {
    fileprivate let children: [Setting]

    init(title: NSAttributedString? = nil, footerTitle: NSAttributedString? = nil, cellHeight: CGFloat? = nil, children: [Setting]) {
        self.children = children
        super.init(title: title, footerTitle: footerTitle, cellHeight: cellHeight)
    }

    var count: Int {
        var count = 0
        for setting in children where !setting.hidden {
            count += 1
        }
        return count
    }

    subscript(val: Int) -> Setting? {
        var i = 0
        for setting in children where !setting.hidden {
            if i == val {
                return setting
            }
            i += 1
        }
        return nil
    }
}

private class PaddedSwitch: UIView {
    fileprivate static let Padding: CGFloat = 8

    init(switchView: UISwitch) {
        super.init(frame: .zero)

        addSubview(switchView)

        frame.size = CGSize(width: switchView.frame.width + PaddedSwitch.Padding, height: switchView.frame.height)
        switchView.frame.origin = CGPoint(x: PaddedSwitch.Padding, y: 0)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// A helper class for settings with a UISwitch.
// Takes and optional settingsDidChange callback and status text.
class BoolSetting: Setting, FeatureFlaggable {
    let prefKey: String? // Sometimes a subclass will manage its own pref setting. In that case the prefkey will be nil

    fileprivate let prefs: Prefs?
    fileprivate let defaultValue: Bool?
    fileprivate let settingDidChange: ((Bool) -> Void)?
    fileprivate let statusText: NSAttributedString?
    fileprivate let featureFlagName: NimbusFeatureFlagID?

    init(
        prefs: Prefs?,
        prefKey: String? = nil,
        defaultValue: Bool?,
        attributedTitleText: NSAttributedString,
        attributedStatusText: NSAttributedString? = nil,
        featureFlagName: NimbusFeatureFlagID? = nil,
        settingDidChange: ((Bool) -> Void)? = nil
    ) {
        self.prefs = prefs
        self.prefKey = prefKey
        self.defaultValue = defaultValue
        self.settingDidChange = settingDidChange
        self.statusText = attributedStatusText
        self.featureFlagName = featureFlagName
        super.init(title: attributedTitleText)
    }

    convenience init(
        prefs: Prefs,
        theme: Theme,
        prefKey: String? = nil,
        defaultValue: Bool,
        titleText: String,
        statusText: String? = nil,
        settingDidChange: ((Bool) -> Void)? = nil
    ) {
        var statusTextAttributedString: NSAttributedString?
        if let statusTextString = statusText {
            let attributes = [NSAttributedString.Key.foregroundColor: theme.colors.textSecondary]
            statusTextAttributedString = NSAttributedString(string: statusTextString,
                                                            attributes: attributes)
        }
        self.init(
            prefs: prefs,
            prefKey: prefKey,
            defaultValue: defaultValue,
            attributedTitleText: NSAttributedString(
                string: titleText,
                attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary]),
            attributedStatusText: statusTextAttributedString,
            settingDidChange: settingDidChange)
    }

    convenience init(
        with featureFlagID: NimbusFeatureFlagID,
        titleText: NSAttributedString,
        settingDidChange: ((Bool) -> Void)? = nil
    ) {
        self.init(
            prefs: nil,
            defaultValue: nil,
            attributedTitleText: titleText,
            featureFlagName: featureFlagID,
            settingDidChange: settingDidChange)
    }

    override var status: NSAttributedString? {
        return statusText
    }

    override func onConfigureCell(_ cell: UITableViewCell, theme: Theme) {
        super.onConfigureCell(cell, theme: theme)

        let control = UISwitch()
        control.onTintColor = theme.colors.actionPrimary
        control.addTarget(self, action: #selector(switchValueChanged), for: .valueChanged)
        control.accessibilityIdentifier = prefKey
        control.isEnabled = enabled

        displayBool(control)
        if let title = title {
            if let status = status {
                control.accessibilityLabel = "\(title.string), \(status.string)"
            } else {
                control.accessibilityLabel = title.string
            }
            cell.accessibilityLabel = nil
        }
        cell.accessoryView = PaddedSwitch(switchView: control)
        cell.selectionStyle = .none

        if !enabled {
            cell.subviews.forEach { $0.alpha = 0.5 }
        }
    }

    @objc func switchValueChanged(_ control: UISwitch) {
        writeBool(control)
        settingDidChange?(control.isOn)

        if let featureFlagName = featureFlagName {
            TelemetryWrapper.recordEvent(category: .action,
                                         method: .change,
                                         object: .setting,
                                         extras: ["pref": featureFlagName.rawValue as Any,
                                                  "to": control.isOn])
        } else {
            TelemetryWrapper.recordEvent(category: .action,
                                         method: .change,
                                         object: .setting,
                                         extras: ["pref": prefKey as Any, "to": control.isOn])
        }
    }

    // These methods allow a subclass to control how the pref is saved
    func displayBool(_ control: UISwitch) {
        if let featureFlagName = featureFlagName {
            control.isOn = featureFlags.isFeatureEnabled(featureFlagName, checking: .userOnly)
        } else {
            guard let key = prefKey, let defaultValue = defaultValue else { return }
            control.isOn = prefs?.boolForKey(key) ?? defaultValue
        }
    }

    func writeBool(_ control: UISwitch) {
        if let featureFlagName = featureFlagName {
            featureFlags.set(feature: featureFlagName, to: control.isOn)
        } else {
            guard let key = prefKey else { return }
            prefs?.setBool(control.isOn, forKey: key)
        }
    }
}

class PrefPersister: SettingValuePersister {
    fileprivate let prefs: Prefs
    let prefKey: String

    init(prefs: Prefs, prefKey: String) {
        self.prefs = prefs
        self.prefKey = prefKey
    }

    func readPersistedValue() -> String? {
        return prefs.stringForKey(prefKey)
    }

    func writePersistedValue(value: String?) {
        if let value = value {
            prefs.setString(value, forKey: prefKey)
        } else {
            prefs.removeObjectForKey(prefKey)
        }
    }
}

class StringPrefSetting: StringSetting {
    init(
        prefs: Prefs,
        prefKey: String,
        defaultValue: String? = nil,
        placeholder: String,
        accessibilityIdentifier: String,
        settingIsValid isValueValid: ((String?) -> Bool)? = nil,
        settingDidChange: ((String?) -> Void)? = nil
    ) {
        super.init(defaultValue: defaultValue,
                   placeholder: placeholder,
                   accessibilityIdentifier: accessibilityIdentifier,
                   persister: PrefPersister(prefs: prefs, prefKey: prefKey),
                   settingIsValid: isValueValid,
                   settingDidChange: settingDidChange)
    }
}

class WebPageSetting: StringPrefSetting {
    let isChecked: () -> Bool

    init(
        prefs: Prefs,
        prefKey: String,
        defaultValue: String? = nil,
        placeholder: String,
        accessibilityIdentifier: String,
        isChecked: @escaping () -> Bool = { return false },
        settingDidChange: ((String?) -> Void)? = nil
    ) {
        self.isChecked = isChecked
        super.init(prefs: prefs,
                   prefKey: prefKey,
                   defaultValue: defaultValue,
                   placeholder: placeholder,
                   accessibilityIdentifier: accessibilityIdentifier,
                   settingIsValid: WebPageSetting.isURLOrEmpty,
                   settingDidChange: settingDidChange)
        textField.keyboardType = .URL
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
    }

    override func prepareValidValue(userInput value: String?) -> String? {
        guard let value = value else { return nil }
        return URIFixup.getURL(value)?.absoluteString
    }

    override func onConfigureCell(_ cell: UITableViewCell, theme: Theme) {
        super.onConfigureCell(cell, theme: theme)
        cell.accessoryType = isChecked() ? .checkmark : .none
        textField.textAlignment = .left
    }

    static func isURLOrEmpty(_ string: String?) -> Bool {
        guard let string = string, !string.isEmpty else {
            return true
        }
        return URL(string: string)?.isWebPage() ?? false
    }
}

protocol SettingValuePersister {
    func readPersistedValue() -> String?
    func writePersistedValue(value: String?)
}

/// A helper class for a setting backed by a UITextField.
/// This takes an optional settingIsValid and settingDidChange callback
/// If settingIsValid returns false, the Setting will not change and the text remains red.
class StringSetting: Setting, UITextFieldDelegate {
    var Padding: CGFloat = 15

    fileprivate let defaultValue: String?
    fileprivate let placeholder: String
    fileprivate let settingDidChange: ((String?) -> Void)?
    fileprivate let settingIsValid: ((String?) -> Bool)?
    fileprivate let persister: SettingValuePersister

    let textField = UITextField()

    init(
        defaultValue: String? = nil,
        placeholder: String,
        accessibilityIdentifier: String,
        persister: SettingValuePersister,
        settingIsValid isValueValid: ((String?) -> Bool)? = nil,
        settingDidChange: ((String?) -> Void)? = nil
    ) {
        self.defaultValue = defaultValue
        self.settingDidChange = settingDidChange
        self.settingIsValid = isValueValid
        self.placeholder = placeholder
        self.persister = persister

        super.init()
        self.accessibilityIdentifier = accessibilityIdentifier
    }

    override func onConfigureCell(_ cell: UITableViewCell, theme: Theme) {
        super.onConfigureCell(cell, theme: theme)
        if let id = accessibilityIdentifier {
            textField.accessibilityIdentifier = id + "TextField"
        }
        let placeholderColor = theme.colors.textSecondary
        textField.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [NSAttributedString.Key.foregroundColor: placeholderColor])

        cell.tintColor = self.persister.readPersistedValue() != nil ? theme.colors.actionPrimary : UIColor.clear
        textField.textAlignment = .center
        textField.delegate = self
        textField.tintColor = theme.colors.actionPrimary
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        cell.isUserInteractionEnabled = true
        cell.accessibilityTraits = UIAccessibilityTraits.none
        cell.contentView.addSubview(textField)

        textField.font = DynamicFontHelper.defaultHelper.DefaultStandardFont

        textField.snp.makeConstraints { make in
            make.height.equalTo(44)
            make.trailing.equalTo(cell.contentView).offset(-Padding)
            make.leading.equalTo(cell.contentView).offset(Padding)
        }
        if let value = self.persister.readPersistedValue() {
            textField.text = value
            textFieldDidChange(textField)
        }
    }

    override func onClick(_ navigationController: UINavigationController?) {
        textField.becomeFirstResponder()
    }

    fileprivate func isValid(_ value: String?) -> Bool {
        guard let test = settingIsValid else {
            return true
        }
        return test(prepareValidValue(userInput: value))
    }

    /// This gives subclasses an opportunity to treat the user input string
    /// before it is saved or tested.
    /// Default implementation does nothing.
    func prepareValidValue(userInput value: String?) -> String? {
        return value
    }

    @objc func textFieldDidChange(_ textField: UITextField) {
        let color = isValid(textField.text) ? theme.colors.textPrimary : theme.colors.textWarning
        textField.textColor = color
    }

    @objc func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return isValid(textField.text)
    }

    @objc func textFieldDidEndEditing(_ textField: UITextField) {
        let text = textField.text
        if !isValid(text) {
            return
        }
        self.persister.writePersistedValue(value: prepareValidValue(userInput: text))
        // Call settingDidChange with text or nil.
        settingDidChange?(text)
    }
}

enum CheckmarkSettingStyle {
    case leftSide
    case rightSide
}

class QwantCheckmarkSetting: CheckmarkSetting {
    override func onConfigureCell(_ cell: UITableViewCell, theme: Theme) {
        super.onConfigureCell(cell, theme: theme)
        cell.accessoryView = UIImageView(image: UIImage(named: "icon_checkmark"))
        cell.accessoryView?.isHidden = !isChecked()
        cell.textLabel?.text = nil
        cell.detailTextLabel?.text = nil
    }
}

class CheckmarkSetting: Setting {
    let onChecked: () -> Void
    let isChecked: () -> Bool
    private let subtitle: NSAttributedString?
    let checkmarkStyle: CheckmarkSettingStyle

    override var status: NSAttributedString? {
        return subtitle
    }

    init(
        title: NSAttributedString,
        style: CheckmarkSettingStyle = .rightSide,
        subtitle: NSAttributedString?,
        accessibilityIdentifier: String? = nil,
        isChecked: @escaping () -> Bool,
        onChecked: @escaping () -> Void
    ) {
        self.subtitle = subtitle
        self.onChecked = onChecked
        self.isChecked = isChecked
        self.checkmarkStyle = style
        super.init(title: title)
        self.accessibilityIdentifier = accessibilityIdentifier
    }

    override func onConfigureCell(_ cell: UITableViewCell, theme: Theme) {
        super.onConfigureCell(cell, theme: theme)

        if checkmarkStyle == .rightSide {
            cell.accessoryType = isChecked() ? .checkmark : .none
        } else {
            let window = UIWindow.keyWindow
            let safeAreaInsets = window?.safeAreaInsets.left ?? 0
            cell.indentationWidth = 42 + safeAreaInsets
            cell.indentationLevel = 1

            cell.accessoryType = .detailButton

            let checkColor = isChecked() ? theme.colors.actionPrimary : UIColor.clear
            let check = UILabel()
            cell.contentView.addSubview(check)
            check.snp.makeConstraints { make in
                make.height.equalTo(20)
                make.width.equalTo(24)
                make.top.equalToSuperview().offset(10)
                make.leading.equalToSuperview().offset(20)
            }
            check.text = "\u{2713}"
            check.font = UIFont.systemFont(ofSize: 20)
            check.textColor = checkColor

            let result = NSMutableAttributedString()
            if let str = title?.string {
                result.append(NSAttributedString(string: str,
                                                 attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary]))
            }
            cell.textLabel?.assign(attributed: result, theme: theme)
        }

        if !enabled {
            cell.subviews.forEach { $0.alpha = 0.5 }
        }
    }

    override func onClick(_ navigationController: UINavigationController?) {
        // Force editing to end for any focused text fields so they can finish up validation first.
        navigationController?.view.endEditing(true)
        if !isChecked() {
            onChecked()
        }
    }
}

/// A helper class for a setting backed by a UITextField.
/// This takes an optional isEnabled and mandatory onClick callback
/// isEnabled is called on each tableview.reloadData. If it returns
/// false then the 'button' appears disabled.
class ButtonSetting: Setting {
    var Padding: CGFloat = 8

    let onButtonClick: (UINavigationController?) -> Void
    let destructive: Bool
    let isEnabled: (() -> Bool)?

    init(title: NSAttributedString?, destructive: Bool = false, accessibilityIdentifier: String, isEnabled: (() -> Bool)? = nil, onClick: @escaping (UINavigationController?) -> Void) {
        self.onButtonClick = onClick
        self.destructive = destructive
        self.isEnabled = isEnabled
        super.init(title: title)
        self.accessibilityIdentifier = accessibilityIdentifier
    }

    override func onConfigureCell(_ cell: UITableViewCell, theme: Theme) {
        super.onConfigureCell(cell, theme: theme)

        if isEnabled?() ?? true {
            cell.textLabel?.textColor = destructive ? theme.colors.textWarning : theme.colors.actionPrimary
        } else {
            cell.textLabel?.textColor = theme.colors.textDisabled
        }
        cell.textLabel?.snp.makeConstraints({ make in
            make.height.equalTo(44)
            make.trailing.equalTo(cell.contentView).offset(-Padding)
            make.leading.equalTo(cell.contentView).offset(Padding)
        })
        cell.textLabel?.textAlignment = .center
        cell.accessibilityTraits = UIAccessibilityTraits.button
        cell.selectionStyle = .none
    }

    override func onClick(_ navigationController: UINavigationController?) {
        // Force editing to end for any focused text fields so they can finish up validation first.
        navigationController?.view.endEditing(true)
        if isEnabled?() ?? true {
            onButtonClick(navigationController)
        }
    }
}

// A helper class for prefs that deal with sync. Handles reloading the tableView data if changes to
// the fxAccount happen.
class AccountSetting: Setting {
    unowned var settings: SettingsTableViewController

    var profile: Profile {
        return settings.profile
    }

    override var title: NSAttributedString? { return nil }

    init(settings: SettingsTableViewController) {
        self.settings = settings
        super.init(title: nil)
    }

    override func onConfigureCell(_ cell: UITableViewCell, theme: Theme) {
        super.onConfigureCell(cell, theme: theme)
        if settings.profile.rustFxA.userProfile != nil {
            cell.selectionStyle = .none
        }
    }

    override var accessoryType: UITableViewCell.AccessoryType { return .none }
}

class WithAccountSetting: AccountSetting {
    override var hidden: Bool { return !profile.hasAccount() }
}

class WithoutAccountSetting: AccountSetting {
    override var hidden: Bool { return profile.hasAccount() }
}

@objc
protocol SettingsDelegate: AnyObject {
    func settingsOpenURLInNewTab(_ url: URL)
}

// The base settings view controller.
class QwantSettingsTableViewController: SettingsTableViewController {
    
    fileprivate let QwantSectionHeaderIdentifier = "QwantSectionHeaderIdentifier"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(QwantThemedTableSectionHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: QwantSectionHeaderIdentifier)
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let sectionSetting = settings[section]
        guard let sectionFooter = sectionSetting.footerTitle?.string else {
            return nil
        }
        let footerView = QwantThemedTableSectionHeaderFooterView()
        footerView.titleLabel.text = sectionFooter
        footerView.titleAlignment = .top
        footerView.applyTheme(theme: themeManager.currentTheme)
        return footerView
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = settings[indexPath.section]
        if let setting = section[indexPath.row] {
            let cell = LargeSubtitleCell(style: setting.style, reuseIdentifier: nil)
            setting.onConfigureCell(cell, theme: themeManager.currentTheme)
            cell.title.text = setting.title?.string ?? ""
            cell.subtitle.text = setting.status?.string ?? ""
            cell.backgroundColor = UIColor.theme.qwantVIP.sectionColor
            return cell
        }
        return super.tableView(tableView, cellForRowAt: indexPath)
    }
}

class SettingsTableViewController: ThemedTableViewController {
    typealias SettingsGenerator = (SettingsTableViewController, SettingsDelegate?) -> [SettingSection]

    fileprivate let Identifier = "CellIdentifier"
    var settings = [SettingSection]()

    weak var settingsDelegate: SettingsDelegate?

    var profile: Profile!
    var tabManager: TabManager!

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Identifier)
        tableView.register(ThemedTableSectionHeaderFooterView.self,
                           forHeaderFooterViewReuseIdentifier: ThemedTableSectionHeaderFooterView.cellIdentifier)
        tableView.tableFooterView = UIView(frame: CGRect(width: view.frame.width, height: 30))
        tableView.estimatedRowHeight = 44
        tableView.estimatedSectionHeaderHeight = 44

        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(didLongPress))
        tableView.addGestureRecognizer(longPressGestureRecognizer)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        settings = generateSettings()
        NotificationCenter.default.addObserver(self, selector: #selector(syncDidChangeState), name: .ProfileDidStartSyncing, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(syncDidChangeState), name: .ProfileDidFinishSyncing, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(firefoxAccountDidChange), name: .FirefoxAccountChanged, object: nil)

        applyTheme()
    }

    override func applyTheme() {
        settings = generateSettings()
        super.applyTheme()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refresh()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        [Notification.Name.ProfileDidStartSyncing, Notification.Name.ProfileDidFinishSyncing, Notification.Name.FirefoxAccountChanged].forEach { name in
            NotificationCenter.default.removeObserver(self, name: name, object: nil)
        }
    }

    // Override to provide settings in subclasses
    func generateSettings() -> [SettingSection] {
        return []
    }

    @objc fileprivate func syncDidChangeState() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

    @objc fileprivate func refresh() {
        // Through-out, be aware that modifying the control while a refresh is in progress is /not/ supported and will likely crash the app.
        //// self.profile.rustAccount.refreshProfile()
        // TODO [rustfxa] listen to notification and refresh profile
    }

    @objc func firefoxAccountDidChange() {
        self.tableView.reloadData()
    }

    @objc func didLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        let location = gestureRecognizer.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: location), gestureRecognizer.state == .began else { return }

        let section = settings[indexPath.section]
        if let setting = section[indexPath.row], setting.enabled {
            setting.onLongPress(navigationController)
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = settings[indexPath.section]
        if let setting = section[indexPath.row] {
            let cell = ThemedTableViewCell(style: setting.style, reuseIdentifier: nil)
            setting.onConfigureCell(cell, theme: themeManager.currentTheme)
            cell.applyTheme(theme: themeManager.currentTheme)
            return cell
        }
        return super.tableView(tableView, cellForRowAt: indexPath)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return settings.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = settings[section]
        return section.count
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: ThemedTableSectionHeaderFooterView.cellIdentifier) as? ThemedTableSectionHeaderFooterView else { return nil }

        let sectionSetting = settings[section]
        if let sectionTitle = sectionSetting.title?.string {
            headerView.titleLabel.text = sectionTitle.uppercased()
        }
        headerView.applyTheme(theme: themeManager.currentTheme)
        return headerView
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let sectionSetting = settings[section]

        guard let footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: ThemedTableSectionHeaderFooterView.cellIdentifier) as? ThemedTableSectionHeaderFooterView,
                let sectionFooter = sectionSetting.footerTitle?.string else { return nil }

        footerView.titleLabel.text = sectionFooter
        footerView.titleAlignment = .top
        footerView.applyTheme(theme: themeManager.currentTheme)
        return footerView
    }

    // To hide a footer dynamically requires returning nil from viewForFooterInSection
    // and setting the height to zero.
    // However, we also want the height dynamically calculated, there is a magic constant
    // for that: `UITableViewAutomaticDimension`.
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let sectionSetting = settings[section]
        if sectionSetting.footerTitle?.string != nil {
            return UITableView.automaticDimension
        }
        return 0
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let section = settings[indexPath.section]
        if let setting = section[indexPath.row], let height = setting.cellHeight {
            return height
        }

        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let section = settings[indexPath.section]
        if let setting = section[indexPath.row], setting.enabled {
            setting.onClick(navigationController)
        }
    }

    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        let section = settings[indexPath.section]
        if let setting = section[indexPath.row] {
            setting.accessoryButtonTapped()
        }
    }
}
