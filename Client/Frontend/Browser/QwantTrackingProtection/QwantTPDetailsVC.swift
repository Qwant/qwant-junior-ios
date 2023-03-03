// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

class QwantTPDetailsVC: QwantVIPBaseVC {
    
    private lazy var titleLabel: UILabel = .build { label in
        label.font = ETPMenuUX.Fonts.websiteTitle
        label.numberOfLines = 0
    }
    
    private lazy var domainLabel: UILabel = .build { label in
        label.font = ETPMenuUX.Fonts.detailsLabel
        label.numberOfLines = 0
    }
    
    private lazy var titleView: UIStackView = {
        let vStack = UIStackView(arrangedSubviews: [self.titleLabel, self.domainLabel])
        vStack.spacing = 2
        vStack.axis = .vertical
        vStack.alignment = .center
        
        return vStack
    }()
    
    lazy private var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ImageAndLabelPlaceholderCell.self, forCellReuseIdentifier: ImageAndLabelPlaceholderCell.Identifier)
        tableView.register(TwoLabelsInlineTableViewHeaderView.self, forHeaderFooterViewReuseIdentifier: TwoLabelsInlineTableViewHeaderView.Identifier)
        tableView.rowHeight = UITableView.automaticDimension
        // Set an empty footer to prevent empty cells from appearing in the list.
        tableView.tableFooterView = UIView()
        
        return tableView
    }()
    
    private var viewModel: QwantTPDetailsVM
    
    // MARK: - View lifecycle
    
    init(viewModel: QwantTPDetailsVM,
         and notificationCenter: NotificationCenter = NotificationCenter.default) {
        self.viewModel = viewModel
        super.init(notificationCenter: notificationCenter)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setupConstraints() {
        super.setupConstraints()
        view.addSubview(tableView)
        
        let trackerListConstraints = [
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ]
        
        constraints.append(contentsOf: trackerListConstraints)
    }
    
    override func updateViewDetails() {
        super.updateViewDetails()
        navigationItem.titleView = titleView
        
        titleLabel.text = viewModel.title
        domainLabel.text = viewModel.websiteTitle
        
        tableView.tableHeaderView = TwoCountersInlineView(
            lIcon: UIImage(named: "icon_www")!,
            lValue: String(describing: viewModel.orderedDomains.count),
            lTitle: viewModel.blockedDomainsTitleString,
            rIcon: UIImage(named: "icon_shield_green")!,
            rValue: String(describing: viewModel.stats.total),
            rTitle: viewModel.blockedTrackersTitleString)
        
        tableView.reloadData()
    }
    
    override func applyTheme() {
        super.applyTheme()
        tableView.backgroundColor = UIColor.theme.qwantVIP.background
        (tableView.tableHeaderView as? NotificationThemeable)?.applyTheme()
        tableView.reloadData()
    }
}

extension QwantTPDetailsVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.hasBlockedAtLeastOneTracker ? viewModel.orderedDomains.count : 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if !viewModel.hasBlockedAtLeastOneTracker {
            let cell = tableView.dequeueReusableCell(withIdentifier: ImageAndLabelPlaceholderCell.Identifier, for: indexPath) as! ImageAndLabelPlaceholderCell
            cell.backgroundColor = .clear
            cell.setValue(value: viewModel.placeholderTextTitle)
            return cell
        }
        
        let cellIdentifier = "TrackerCell"
        var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
        
        if cell == nil {
            cell = UITableViewCell(style: .value1, reuseIdentifier: cellIdentifier)
        }
        
        guard let cell = cell else {
            fatalError()
        }

        cell.selectionStyle = .none
        cell.textLabel?.text = viewModel.orderedDomains[indexPath.row].key
        cell.textLabel?.textColor = UIColor.theme.qwantVIP.textColor
        cell.textLabel?.font = QwantUX.Font.Text.l
        cell.detailTextLabel?.text = String(describing: viewModel.orderedDomains[indexPath.row].value)
        cell.detailTextLabel?.textColor = UIColor.theme.qwantVIP.subtextColor
        cell.detailTextLabel?.font = QwantUX.Font.Text.l
        cell.backgroundColor = UIColor.theme.qwantVIP.sectionColor
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section == 0 else { return nil }
        
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: TwoLabelsInlineTableViewHeaderView.Identifier) as? TwoLabelsInlineTableViewHeaderView else {
            return nil
        }

        headerView.setValues(lValue: viewModel.leftHandSideHeaderTitle, rValue: viewModel.rightHandSideHeaderTitle)
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard section == 0 else { return 0 }
        
        return 140
    }
}
