//
//  NativeListViewController.swift
//  zmaticoo-ios-demo-swift
//
//  Swift 版原生广告信息流列表：对齐 ObjC 版 NativeListViewController
//  （每 9 条普通行插入 1 条广告，广告行懒加载、独立复用标识，
//   支持下拉刷新与滚动加载更多）。
//

import UIKit
import MaticooSDK

final class NativeListViewController: UIViewController,
                                      UITableViewDataSource,
                                      UITableViewDelegate,
                                      MATNativeAdDelegate {

    // MARK: - Constants (对齐 ObjC 版)

    private let initialNormalItemCount = 54
    private let pageNormalItemCount = 54
    private let maxNormalItemCount = 200
    private let adEveryNNormalItems = 9
    private let normalRowHeight: CGFloat = 68
    private let adLoadingRowHeight: CGFloat = 84
    private let cellTypeNormal = 0
    private let cellTypeAd = 1

    // MARK: - Properties

    private let tableView = UITableView()
    private let refreshControl = UIRefreshControl()
    private var adSlots: [Int: NativeListAdSlot] = [:]
    private var normalItemCount: Int = 54
    private var isLoadingMore = false

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        normalItemCount = initialNormalItemCount
        view.backgroundColor = DemoTheme.groupedBackgroundColor
        title = "Native List"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Back", style: .plain, target: self, action: #selector(backTapped)
        )

        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 380
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(NativeListNormalCell.self, forCellReuseIdentifier: "NormalCell")
        registerAdCellReuseIdentifiers()
        view.addSubview(tableView)

        refreshControl.addTarget(self, action: #selector(refreshList), for: .valueChanged)
        tableView.refreshControl = refreshControl

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }

    deinit {
        destroyAllAdSlots()
    }

    @objc private func backTapped() {
        if navigationController?.presentingViewController != nil {
            navigationController?.dismiss(animated: true, completion: nil)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }

    // MARK: - Row math (对齐 ObjC 版)

    private var groupsCount: Int {
        return normalItemCount / adEveryNNormalItems
    }

    private var totalItemCount: Int {
        let groups = groupsCount
        let remaining = normalItemCount % adEveryNNormalItems
        return groups * (adEveryNNormalItems + 1) + remaining
    }

    private func cellType(forRow row: Int) -> Int {
        let adEveryCycle = adEveryNNormalItems + 1
        let groups = groupsCount
        let groupsItems = groups * adEveryCycle
        if row >= groupsItems {
            return cellTypeNormal
        }
        let within = row % adEveryCycle
        return within == adEveryNNormalItems ? cellTypeAd : cellTypeNormal
    }

    private func normalIndex(forRow row: Int) -> Int {
        let adEveryCycle = adEveryNNormalItems + 1
        let groups = groupsCount
        let groupsItems = groups * adEveryCycle
        if row < groupsItems {
            let cycleIndex = row / adEveryCycle
            let within = row % adEveryCycle
            return cycleIndex * adEveryNNormalItems + within
        }
        return groups * adEveryNNormalItems + (row - groupsItems)
    }

    private func adReuseIdentifier(forRow row: Int) -> String {
        return "AdCell_\(row)"
    }

    private func registerAdCellReuseIdentifiers() {
        for row in 0..<totalItemCount where cellType(forRow: row) == cellTypeAd {
            tableView.register(NativeListAdCell.self, forCellReuseIdentifier: adReuseIdentifier(forRow: row))
        }
    }

    // MARK: - Ad slots

    private func adSlot(forRow row: Int) -> NativeListAdSlot {
        if let slot = adSlots[row] {
            return slot
        }
        let slot = NativeListAdSlot(row: row)
        adSlots[row] = slot
        return slot
    }

    private func adSlot(forNativeAd nativeAd: MATNativeAd) -> NativeListAdSlot? {
        return adSlots.values.first { $0.nativeAd === nativeAd }
    }

    private func destroyAllAdSlots() {
        adSlots.values.forEach { $0.destroyAd() }
        adSlots.removeAll()
    }

    private func adShellWidth(for tableView: UITableView) -> CGFloat {
        let width = tableView.bounds.width - 16
        guard width >= 50 else { return DemoTheme.nativeCardWidth }
        return min(max(width, 280), DemoTheme.nativeCardWidth)
    }

    private func renderNativeAdOnce(in slot: NativeListAdSlot) {
        guard !slot.hasRendered, let nativeAd = slot.nativeAd else { return }
        let shellWidth = adShellWidth(for: tableView)
        slot.adShellHost.subviews.forEach { $0.removeFromSuperview() }
        slot.adShellHost.constraints.forEach { slot.adShellHost.removeConstraint($0) }
        NativeAdRenderer.render(nativeAd, in: slot.adShellHost, width: shellWidth)
        slot.cardHeight = NativeAdRenderer.preferredHeight(for: nativeAd, width: shellWidth)
        slot.hasRendered = true
    }

    // MARK: - MATNativeAdDelegate

    func nativeAdLoadSuccess(_ nativeAd: MATNativeAd) {
        guard let slot = adSlot(forNativeAd: nativeAd) else { return }
        log("NativeList didLoad row=\(slot.row)")
        renderNativeAdOnce(in: slot)

        let path = IndexPath(row: slot.row, section: 0)
        if tableView.indexPathsForVisibleRows?.contains(path) == true {
            tableView.reloadRows(at: [path], with: .none)
        }
    }

    func nativeAdFailed(_ nativeAd: MATNativeAd, withError error: Error) {
        guard let slot = adSlot(forNativeAd: nativeAd) else { return }
        slot.loadFailed = true
        slot.errorMessage = "Native ad load failed"
        slot.nativeAd?.destroy()
        slot.nativeAd = nil
        log("NativeList didFailWithError row=\(slot.row) error=\(error.localizedDescription)")

        let path = IndexPath(row: slot.row, section: 0)
        if let cell = tableView.cellForRow(at: path) as? NativeListAdCell {
            cell.bind(shellHost: slot.adShellHost,
                      nativeAd: nil,
                      loadFailed: true,
                      errorMessage: slot.errorMessage,
                      hasRendered: false)
        }
    }

    func nativeAdDisplayed(_ nativeAd: MATNativeAd) {
        if let slot = adSlot(forNativeAd: nativeAd) {
            log("NativeList didDisplay row=\(slot.row)")
        }
    }

    func nativeAd(_ nativeAd: MATNativeAd, displayFailWithError error: Error) {
        if let slot = adSlot(forNativeAd: nativeAd) {
            log("NativeList displayFailWithError row=\(slot.row) error=\(error.localizedDescription)")
        }
    }

    func nativeAdClicked(_ nativeAd: MATNativeAd) {
        if let slot = adSlot(forNativeAd: nativeAd) {
            log("NativeList didClick row=\(slot.row)")
        }
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return totalItemCount
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if cellType(forRow: indexPath.row) == cellTypeAd {
            let reuseId = adReuseIdentifier(forRow: indexPath.row)
            let cell = tableView.dequeueReusableCell(withIdentifier: reuseId, for: indexPath) as! NativeListAdCell
            let slot = adSlot(forRow: indexPath.row)
            cell.bind(shellHost: slot.adShellHost,
                      nativeAd: slot.nativeAd,
                      loadFailed: slot.loadFailed,
                      errorMessage: slot.errorMessage,
                      hasRendered: slot.hasRendered)
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "NormalCell", for: indexPath) as! NativeListNormalCell
        cell.indexLabel.text = "\(normalIndex(forRow: indexPath.row) + 1)"
        return cell
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if cellType(forRow: indexPath.row) == cellTypeNormal {
            return normalRowHeight
        }
        let slot = adSlot(forRow: indexPath.row)
        if slot.hasRendered {
            return slot.cardHeight + 16 + 12
        }
        return adLoadingRowHeight
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard cellType(forRow: indexPath.row) == cellTypeAd else { return }
        let slot = adSlot(forRow: indexPath.row)
        if slot.adLoadRequested || slot.hasRendered || slot.loadFailed {
            return
        }
        slot.adLoadRequested = true
        let ad = MATNativeAd(placementID: DemoConfig.nativePlacementID)
        ad.delegate = self
        slot.nativeAd = ad
        NativeAdRenderer.configure(ad)
        ad.load()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !isLoadingMore else { return }
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let frameHeight = scrollView.frame.height
        guard contentHeight > frameHeight else { return }
        if offsetY > contentHeight - frameHeight - 120 {
            loadMoreIfNeeded()
        }
    }

    // MARK: - Refresh / Load more

    @objc private func refreshList() {
        isLoadingMore = false
        normalItemCount = initialNormalItemCount
        destroyAllAdSlots()
        registerAdCellReuseIdentifiers()
        tableView.reloadData()
        tableView.setContentOffset(.zero, animated: false)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.refreshControl.endRefreshing()
        }
    }

    private func loadMoreIfNeeded() {
        guard normalItemCount < maxNormalItemCount else { return }
        isLoadingMore = true

        let oldTotal = totalItemCount
        let newNormalCount = min(maxNormalItemCount, normalItemCount + pageNormalItemCount)
        guard newNormalCount != normalItemCount else {
            isLoadingMore = false
            return
        }

        normalItemCount = newNormalCount
        let newTotal = totalItemCount
        if newTotal > oldTotal {
            for row in oldTotal..<newTotal where cellType(forRow: row) == cellTypeAd {
                tableView.register(NativeListAdCell.self, forCellReuseIdentifier: adReuseIdentifier(forRow: row))
            }
            let paths = (oldTotal..<newTotal).map { IndexPath(row: $0, section: 0) }
            tableView.insertRows(at: paths, with: .automatic)
        } else {
            tableView.reloadData()
        }
        isLoadingMore = false
    }

    private func log(_ message: String) {
        print("[SwiftDemo] \(message)")
    }
}

// MARK: - DemoConfig（与 ViewController 共用）

enum DemoConfig {
    static let appKey = "588bcf777ad1960b84222d468bef42865171c8ce91729a0329c6a67c23fc739d"
    static let bannerPlacementID = "1004574300"
    static let interstitialPlacementID = "1004498206"
    static let rewardPlacementID = "1004574515"
    static let nativePlacementID = "1004646645"
    // Header Bidding 广告位（请替换为你自己的 HB 广告位）
    static let hbBannerPlacementID = "1004574431"
    static let hbInterstitialPlacementID = "1004498229"
    static let hbRewardPlacementID = "1004574581"
    static let hbNativePlacementID = "1004646610"
    // 询价请求中的 AdX ID（由你的 AdX 合作方提供）
    static let adxID = "adx_id"
}

// MARK: - NativeListNormalCell

final class NativeListNormalCell: UITableViewCell {
    let indexLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear

        let card = UIView()
        DemoTheme.applyCardStyle(to: card, cornerRadius: 12.0)
        card.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(card)

        indexLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        indexLabel.textAlignment = .center
        indexLabel.textColor = DemoTheme.primaryTextColor
        indexLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(indexLabel)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            card.heightAnchor.constraint(greaterThanOrEqualToConstant: 56),
            indexLabel.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            indexLabel.centerYAnchor.constraint(equalTo: card.centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - NativeListAdSlot

final class NativeListAdSlot {
    let row: Int
    var nativeAd: MATNativeAd?
    let adShellHost = UIView()
    var adLoadRequested = false
    var loadFailed = false
    var hasRendered = false
    var cardHeight: CGFloat = 72
    var errorMessage: String?

    init(row: Int) {
        self.row = row
        adShellHost.translatesAutoresizingMaskIntoConstraints = false
    }

    func destroyAd() {
        nativeAd?.destroy()
        nativeAd = nil
        adShellHost.subviews.forEach { $0.removeFromSuperview() }
        adShellHost.constraints.forEach { adShellHost.removeConstraint($0) }
        adLoadRequested = false
        loadFailed = false
        hasRendered = false
        cardHeight = 72
        errorMessage = nil
    }
}

// MARK: - NativeListAdCell

final class NativeListAdCell: UITableViewCell {
    private let placeholderLabel = UILabel()
    private let adContainer = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear

        let card = UIView()
        DemoTheme.applyCardStyle(to: card, cornerRadius: 12.0)
        card.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(card)

        adContainer.translatesAutoresizingMaskIntoConstraints = false
        adContainer.clipsToBounds = true

        placeholderLabel.text = "Loading native ad..."
        placeholderLabel.font = UIFont.systemFont(ofSize: 13)
        placeholderLabel.textAlignment = .center
        placeholderLabel.numberOfLines = 0
        placeholderLabel.textColor = DemoTheme.tertiaryTextColor
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(adContainer)
        adContainer.addSubview(placeholderLabel)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            adContainer.topAnchor.constraint(equalTo: card.topAnchor, constant: 8),
            adContainer.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 8),
            adContainer.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -8),
            adContainer.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -8),

            placeholderLabel.centerXAnchor.constraint(equalTo: adContainer.centerXAnchor),
            placeholderLabel.centerYAnchor.constraint(equalTo: adContainer.centerYAnchor),
            placeholderLabel.leadingAnchor.constraint(greaterThanOrEqualTo: adContainer.leadingAnchor, constant: 8),
            placeholderLabel.trailingAnchor.constraint(lessThanOrEqualTo: adContainer.trailingAnchor, constant: -8),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        // 广告行独占 reuseIdentifier，渲染视图由数据源持有，回收时不移除
        placeholderLabel.isHidden = false
        placeholderLabel.text = "Loading native ad..."
    }

    func bind(shellHost: UIView, nativeAd: MATNativeAd?, loadFailed: Bool, errorMessage: String?, hasRendered: Bool) {
        if loadFailed {
            placeholderLabel.isHidden = false
            placeholderLabel.text = (errorMessage?.isEmpty == false) ? errorMessage! : "Native ad load failed"
            return
        }
        if !hasRendered || nativeAd == nil {
            placeholderLabel.isHidden = false
            placeholderLabel.text = "Loading native ad..."
            return
        }
        if shellHost.superview != adContainer {
            shellHost.removeFromSuperview()
            shellHost.translatesAutoresizingMaskIntoConstraints = false
            adContainer.addSubview(shellHost)
            NSLayoutConstraint.activate([
                shellHost.topAnchor.constraint(equalTo: adContainer.topAnchor),
                shellHost.leadingAnchor.constraint(equalTo: adContainer.leadingAnchor),
                shellHost.trailingAnchor.constraint(equalTo: adContainer.trailingAnchor),
                shellHost.bottomAnchor.constraint(equalTo: adContainer.bottomAnchor),
            ])
        }
        placeholderLabel.isHidden = true
    }
}
