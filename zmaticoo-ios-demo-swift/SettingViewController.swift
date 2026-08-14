//
//  SettingViewController.swift
//  zmaticoo-ios-demo-swift
//
//  Swift 版隐私设置页：对齐 ObjC 版 SettingViewController
//  （GDPR / DoNotSell / COPPA 三个开关，实时写入 SDK）。
//

import UIKit
import MaticooSDK

final class SettingViewController: UIViewController {

    private let switchGdpr = UISwitch()
    private let switchDoNotSell = UISwitch()
    private let switchCoppa = UISwitch()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Setting"
        view.backgroundColor = DemoTheme.groupedBackgroundColor
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done, target: self, action: #selector(doneTapped)
        )

        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -16),
            stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -32),
        ])

        let sdk = MaticooAds.shareSDK()
        switchGdpr.isOn = sdk.getConsentStatus()
        switchDoNotSell.isOn = sdk.getDoNotSell()
        switchCoppa.isOn = sdk.getIsAgeRestrictedUser()

        switchGdpr.addTarget(self, action: #selector(gdprChanged(_:)), for: .valueChanged)
        switchDoNotSell.addTarget(self, action: #selector(doNotSellChanged(_:)), for: .valueChanged)
        switchCoppa.addTarget(self, action: #selector(coppaChanged(_:)), for: .valueChanged)

        stack.addArrangedSubview(row(title: "GDPR", switchView: switchGdpr))
        stack.addArrangedSubview(row(title: "DoNotSell", switchView: switchDoNotSell))
        stack.addArrangedSubview(row(title: "CoppaStatus", switchView: switchCoppa))
    }

    @objc private func doneTapped() {
        dismiss(animated: true, completion: nil)
    }

    @objc private func gdprChanged(_ sender: UISwitch) {
        MaticooAds.shareSDK().setConsentStatus(sender.isOn)
    }

    @objc private func doNotSellChanged(_ sender: UISwitch) {
        MaticooAds.shareSDK().setDoNotSell(sender.isOn)
    }

    @objc private func coppaChanged(_ sender: UISwitch) {
        MaticooAds.shareSDK().setIsAgeRestrictedUser(sender.isOn)
    }

    // MARK: - UI Helpers

    private func row(title: String, switchView: UISwitch) -> UIView {
        let row = UIView()
        row.backgroundColor = DemoTheme.cardBackgroundColor
        row.layer.cornerRadius = 8
        row.layer.masksToBounds = true

        let label = UILabel()
        label.text = title
        label.font = UIFont.systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        switchView.translatesAutoresizingMaskIntoConstraints = false

        row.addSubview(label)
        row.addSubview(switchView)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 12),
            label.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            label.trailingAnchor.constraint(lessThanOrEqualTo: switchView.leadingAnchor, constant: -8),
            switchView.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -12),
            switchView.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            row.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
        ])
        return row
    }
}
