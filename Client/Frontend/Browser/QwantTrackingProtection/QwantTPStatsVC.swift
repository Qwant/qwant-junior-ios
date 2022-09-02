// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

class QwantTPStatsVC: UIViewController {
    
    // MARK: UI components
    
    private lazy var closeButton = {
        return UIBarButtonItem(barButtonSystemItem: .close) { [weak self] _ in
            self?.dismiss(animated: true, completion: nil)
        }
    }()
    
    lazy private var tableView: UITableView = .build { [weak self] tableView in
        guard let self = self else { return }
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(CountersCell.self, forCellReuseIdentifier: CountersCell.Identifier)
        tableView.register(TrackerCell.self, forCellReuseIdentifier: TrackerCell.Identifier)

        // Set an empty footer to prevent empty cells from appearing in the list.
        tableView.tableFooterView = UIView()
    }
    
    private var constraints = [NSLayoutConstraint]()
    
    // MARK: - Variables
    
    internal var notificationCenter: NotificationProtocol
    private var viewModel: QwantTPStatsVM
    
    // MARK: - View lifecycle
    
    init(viewModel: QwantTPStatsVM,
         and notificationCenter: NotificationCenter = NotificationCenter.default) {
        self.viewModel = viewModel
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
    
    private func setupView() {
        NSLayoutConstraint.deactivate(constraints)
        constraints.removeAll()
        
        setupStatListView()
        NSLayoutConstraint.activate(constraints)
    }
    
    private func setupStatListView() {
        view.addSubview(tableView)
        
        let statListConstraints = [
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ]
        
        constraints.append(contentsOf: statListConstraints)
    }
    
    private func updateViewDetails() {
        self.title = viewModel.title
        self.navigationItem.setRightBarButton(closeButton, animated: false)
        
        tableView.reloadData()
    }
}

extension QwantTPStatsVC: NotificationThemeable {
    @objc func applyTheme() {
        overrideUserInterfaceStyle =  LegacyThemeManager.instance.userInterfaceStyle
        view.backgroundColor = UIColor.theme.etpMenu.background
        
        setNeedsStatusBarAppearanceUpdate()
    }
}

// MARK: - Notifiable
extension QwantTPStatsVC: Notifiable {
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

extension QwantTPStatsVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.orderedDomains.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
            case 0:
                let lImage: UIImage = #imageLiteral(resourceName: "menu-TrackingProtection")
                let rImage: UIImage = #imageLiteral(resourceName: "library-history")
                return CountersCell(lIcon: lImage, lValue: viewModel.statisticsTrackersBlockedFormattedString, lTitle: viewModel.statisticsBlockedTrackersTitleString,
                                    rIcon: rImage, rValue: viewModel.statisticsTimeSavedFormattedString, rTitle: viewModel.statisticsSavedTimeTitleString)
            default:
                let cell = tableView.dequeueReusableCell(withIdentifier: TrackerCell.Identifier, for: indexPath)
                cell.textLabel?.text = viewModel.orderedDomains[indexPath.row - 1].key
                cell.detailTextLabel?.text = String(describing: viewModel.orderedDomains[indexPath.row - 1].value)
                return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
            case 0: return 110
            default: return 44
        }
    }
}
