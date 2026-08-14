//
//  ViewController.swift
//  zmaticoo-ios-demo-swift
//
//  Swift 版主页：与 ObjC demo（zmaticoo-ios-demo）功能对齐
//  - Init SDK（含 loading / toast）
//  - Setting（隐私开关）
//  - Banner / Interstitial / RewardedVideo / Native（全屏展示）
//  - Native List（信息流）
//  - Header Bidding（插屏 / 激励视频，新 API：询价 → loadAd:biddingRequestId → maticooIds 精确 show）
//

import UIKit
import MaticooSDK

class ViewController: UIViewController,
                      MATBannerAdDelegate,
                      MATInterstitialAdDelegate,
                      MATRewardedVideoAdDelegate,
                      MATNativeAdDelegate {

    // MARK: - UI

    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private var bannerContainer: UIView!
    private var bannerStatusLabel: UILabel!
    private var interstitialStatusLabel: UILabel!
    private var interstitialShowButton: UIButton!
    private var rewardStatusLabel: UILabel!
    private var rewardShowButton: UIButton!
    private var nativeStatusLabel: UILabel!
    private var initStatusLabel: UILabel!
    private var loadingOverlay: UIView?
    // Header Bidding（插屏）
    private var hbInterstitialStatusLabel: UILabel!
    private var hbInterstitialShowButton: UIButton!
    private var hbInterstitialAd: MATInterstitialAd?
    private var hbInterstitialIds: MATMaticooIds?
    // Header Bidding（激励视频）
    private var hbRewardStatusLabel: UILabel!
    private var hbRewardShowButton: UIButton!
    private var hbRewardedVideoAd: MATRewardedVideoAd?
    private var hbRewardIds: MATMaticooIds?
    // Header Bidding（Banner）
    private var hbBannerStatusLabel: UILabel!
    private var hbBannerContainer: UIView!
    private var hbBannerAd: MATBannerAd?
    // Header Bidding（Native）
    private var hbNativeStatusLabel: UILabel!
    private var hbNativeAd: MATNativeAd?

    // MARK: - Ads

    private var bannerAd: MATBannerAd?
    private var interstitialAd: MATInterstitialAd?
    private var rewardedVideoAd: MATRewardedVideoAd?
    private var nativeAd: MATNativeAd?
    /// 最近一次 load 成功对应的 Ids（SDK 新回调带回；show 时回传）
    private var interstitialIds: MATMaticooIds?
    private var rewardIds: MATMaticooIds?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = DemoTheme.groupedBackgroundColor
        buildLayout()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let overlay = loadingOverlay, overlay.superview != nil {
            overlay.frame = view.bounds
        }
    }

    deinit {
        bannerAd?.destroy()
        hbBannerAd?.destroy()
        hbNativeAd?.destroy()
        MATInterstitialAd.destroy([DemoConfig.interstitialPlacementID])
        MATRewardedVideoAd.destroy([DemoConfig.rewardPlacementID])
        MATInterstitialAd.destroy([DemoConfig.hbInterstitialPlacementID])
        MATRewardedVideoAd.destroy([DemoConfig.hbRewardPlacementID])
        nativeAd?.destroy()
    }

    // MARK: - UI Layout

    private func buildLayout() {
        scrollView.alwaysBounceVertical = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        stackView.axis = .vertical
        stackView.spacing = 14
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32),
        ])

        // Header：logo + 双行标题（对齐 ObjC demo）
        let logoWrap = UIView()
        logoWrap.translatesAutoresizingMaskIntoConstraints = false
        let logoView = UIImageView(image: UIImage(named: "ic_maticoo"))
        logoView.contentMode = .scaleAspectFit
        logoView.translatesAutoresizingMaskIntoConstraints = false
        logoView.accessibilityLabel = "zMaticoo"
        logoWrap.addSubview(logoView)
        NSLayoutConstraint.activate([
            logoView.centerXAnchor.constraint(equalTo: logoWrap.centerXAnchor),
            logoView.topAnchor.constraint(equalTo: logoWrap.topAnchor),
            logoView.bottomAnchor.constraint(equalTo: logoWrap.bottomAnchor),
            logoView.heightAnchor.constraint(equalToConstant: 80),
            logoView.widthAnchor.constraint(lessThanOrEqualTo: logoWrap.widthAnchor),
            logoWrap.heightAnchor.constraint(equalToConstant: 80),
        ])
        stackView.addArrangedSubview(logoWrap)

        let titleLabel = UILabel()
        titleLabel.attributedText = headerTitleAttributedString()
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        stackView.addArrangedSubview(titleLabel)

        // SDK card：Init + Setting
        let sdkCard = verticalCard()
        let initButton = primaryButton(title: "Init SDK", action: #selector(initSDKTapped))
        let settingButton = secondaryButton(title: "Setting", action: #selector(settingTapped))
        let sdkButtons = buttonRow()
        sdkButtons.addArrangedSubview(initButton)
        sdkButtons.addArrangedSubview(settingButton)
        sdkCard.addArrangedSubview(sdkButtons)
        initStatusLabel = statusLabel()
        initStatusLabel.text = "not initialized"
        sdkCard.addArrangedSubview(initStatusLabel)
        stackView.addArrangedSubview(wrapCard(sdkCard))

        // Section title
        let sectionTitle = UILabel()
        sectionTitle.text = "Advertising Type Testing"
        sectionTitle.font = UIFont.boldSystemFont(ofSize: 17)
        sectionTitle.textColor = DemoTheme.primaryTextColor
        stackView.addArrangedSubview(sectionTitle)

        // Banner card
        let bannerCard = verticalCard()
        bannerCard.addArrangedSubview(subsectionTitle("Banner"))
        bannerCard.addArrangedSubview(primaryButton(title: "Load", action: #selector(loadBannerTapped)))
        bannerStatusLabel = statusLabel()
        bannerCard.addArrangedSubview(bannerStatusLabel)
        bannerContainer = UIView()
        bannerContainer.isHidden = true
        bannerContainer.translatesAutoresizingMaskIntoConstraints = false
        bannerCard.addArrangedSubview(bannerContainer)
        bannerContainer.heightAnchor.constraint(equalToConstant: 50).isActive = true
        stackView.addArrangedSubview(wrapCard(bannerCard))

        // Interstitial card
        let interCard = verticalCard()
        interCard.addArrangedSubview(subsectionTitle("Interstitial"))
        let interButtons = buttonRow()
        interButtons.addArrangedSubview(primaryButton(title: "Load", action: #selector(loadInterstitialTapped)))
        interstitialShowButton = secondaryButton(title: "Show", action: #selector(showInterstitialTapped))
        interstitialShowButton.isEnabled = false
        interButtons.addArrangedSubview(interstitialShowButton)
        interCard.addArrangedSubview(interButtons)
        interstitialStatusLabel = statusLabel()
        interCard.addArrangedSubview(interstitialStatusLabel)
        stackView.addArrangedSubview(wrapCard(interCard))

        // RewardedVideo card
        let rewardCard = verticalCard()
        rewardCard.addArrangedSubview(subsectionTitle("Reward"))
        let rewardButtons = buttonRow()
        rewardButtons.addArrangedSubview(primaryButton(title: "Load", action: #selector(loadRewardTapped)))
        rewardShowButton = secondaryButton(title: "Show", action: #selector(showRewardTapped))
        rewardShowButton.isEnabled = false
        rewardButtons.addArrangedSubview(rewardShowButton)
        rewardCard.addArrangedSubview(rewardButtons)
        rewardStatusLabel = statusLabel()
        rewardCard.addArrangedSubview(rewardStatusLabel)
        stackView.addArrangedSubview(wrapCard(rewardCard))

        // Native card
        let nativeCard = verticalCard()
        nativeCard.addArrangedSubview(subsectionTitle("Native"))
        let nativeButtons = buttonRow()
        nativeButtons.addArrangedSubview(primaryButton(title: "Load", action: #selector(loadNativeTapped)))
        nativeButtons.addArrangedSubview(secondaryButton(title: "Native List", action: #selector(openNativeListTapped)))
        nativeCard.addArrangedSubview(nativeButtons)
        nativeStatusLabel = statusLabel()
        nativeCard.addArrangedSubview(nativeStatusLabel)
        stackView.addArrangedSubview(wrapCard(nativeCard))

        // Section title: Header Bidding
        let hbSectionTitle = UILabel()
        hbSectionTitle.text = "Header Bidding Testing"
        hbSectionTitle.font = UIFont.boldSystemFont(ofSize: 17)
        hbSectionTitle.textColor = DemoTheme.primaryTextColor
        stackView.addArrangedSubview(hbSectionTitle)

        // HB Interstitial card
        let hbInterCard = verticalCard()
        hbInterCard.addArrangedSubview(subsectionTitle("Interstitial (Bidding)"))
        let hbInterButtons = buttonRow()
        hbInterButtons.addArrangedSubview(primaryButton(title: "Bid + Load", action: #selector(hbBidAndLoadInterstitialTapped)))
        hbInterstitialShowButton = secondaryButton(title: "Show", action: #selector(hbShowInterstitialTapped))
        hbInterstitialShowButton.isEnabled = false
        hbInterButtons.addArrangedSubview(hbInterstitialShowButton)
        hbInterCard.addArrangedSubview(hbInterButtons)
        hbInterstitialStatusLabel = statusLabel()
        hbInterCard.addArrangedSubview(hbInterstitialStatusLabel)
        stackView.addArrangedSubview(wrapCard(hbInterCard))

        // HB Reward card
        let hbRewardCard = verticalCard()
        hbRewardCard.addArrangedSubview(subsectionTitle("Reward (Bidding)"))
        let hbRewardButtons = buttonRow()
        hbRewardButtons.addArrangedSubview(primaryButton(title: "Bid + Load", action: #selector(hbBidAndLoadRewardTapped)))
        hbRewardShowButton = secondaryButton(title: "Show", action: #selector(hbShowRewardTapped))
        hbRewardShowButton.isEnabled = false
        hbRewardButtons.addArrangedSubview(hbRewardShowButton)
        hbRewardCard.addArrangedSubview(hbRewardButtons)
        hbRewardStatusLabel = statusLabel()
        hbRewardCard.addArrangedSubview(hbRewardStatusLabel)
        stackView.addArrangedSubview(wrapCard(hbRewardCard))

        // HB Banner card
        let hbBannerCard = verticalCard()
        hbBannerCard.addArrangedSubview(subsectionTitle("Banner (Bidding)"))
        hbBannerCard.addArrangedSubview(primaryButton(title: "Bid + Load", action: #selector(hbBidAndLoadBannerTapped)))
        hbBannerStatusLabel = statusLabel()
        hbBannerCard.addArrangedSubview(hbBannerStatusLabel)
        hbBannerContainer = UIView()
        hbBannerContainer.isHidden = true
        hbBannerContainer.translatesAutoresizingMaskIntoConstraints = false
        hbBannerCard.addArrangedSubview(hbBannerContainer)
        hbBannerContainer.heightAnchor.constraint(equalToConstant: 50).isActive = true
        stackView.addArrangedSubview(wrapCard(hbBannerCard))

        // HB Native card
        let hbNativeCard = verticalCard()
        hbNativeCard.addArrangedSubview(subsectionTitle("Native (Bidding)"))
        hbNativeCard.addArrangedSubview(primaryButton(title: "Bid + Load", action: #selector(hbBidAndLoadNativeTapped)))
        hbNativeStatusLabel = statusLabel()
        hbNativeCard.addArrangedSubview(hbNativeStatusLabel)
        stackView.addArrangedSubview(wrapCard(hbNativeCard))
    }

    // MARK: - UI Helpers

    private func verticalCard() -> UIStackView {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 8
        s.alignment = .fill
        return s
    }

    private func buttonRow() -> UIStackView {
        let s = UIStackView()
        s.axis = .horizontal
        s.spacing = 8
        s.distribution = .fillEqually
        return s
    }

    private func wrapCard(_ inner: UIStackView) -> UIView {
        let card = UIView()
        // 对齐 ObjC：主题卡片样式 + 阴影（主页卡片保留阴影，关闭 clipsToBounds）
        DemoTheme.applyCardStyle(to: card, cornerRadius: 12.0)
        card.layer.masksToBounds = false
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.06
        card.layer.shadowRadius = 8
        card.layer.shadowOffset = CGSize(width: 0, height: 3)
        inner.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(inner)
        NSLayoutConstraint.activate([
            inner.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            inner.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            inner.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            inner.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),
        ])
        return card
    }

    /// 双行标题：line1 加粗 28 主色 / line2 SDK 版本 15 三级色（对齐 ObjC demo）
    private func headerTitleAttributedString() -> NSAttributedString {
        let line1 = "zMaticoo SDK Demo"
        var ver = MaticooAds.shareSDK().getSDKVersion()
        if ver.isEmpty {
            ver = "—"
        }
        let line2 = "SDK \(ver)"
        let full = "\(line1)\n\(line2)"
        let attributed = NSMutableAttributedString(string: full)

        attributed.addAttributes([
            .font: UIFont.boldSystemFont(ofSize: 28),
            .foregroundColor: DemoTheme.primaryTextColor,
        ], range: NSRange(location: 0, length: (line1 as NSString).length))

        let secondStart = (line1 as NSString).length + 1
        attributed.addAttributes([
            .font: UIFont.systemFont(ofSize: 15),
            .foregroundColor: DemoTheme.tertiaryTextColor,
        ], range: NSRange(location: secondStart, length: (line2 as NSString).length))
        return attributed
    }

    private func subsectionTitle(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        l.textColor = DemoTheme.primaryTextColor
        return l
    }

    private func statusLabel() -> UILabel {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 13)
        l.numberOfLines = 0
        l.textColor = DemoTheme.tertiaryTextColor
        return l
    }

    private func primaryButton(title: String, action: Selector) -> UIButton {
        let b = UIButton(type: .custom)
        b.setTitle(title, for: .normal)
        DemoTheme.applyPrimaryButtonStyle(to: b)
        b.addTarget(self, action: action, for: .touchUpInside)
        return b
    }

    private func secondaryButton(title: String, action: Selector) -> UIButton {
        let b = UIButton(type: .custom)
        b.setTitle(title, for: .normal)
        DemoTheme.applySecondaryButtonStyle(to: b)
        b.addTarget(self, action: action, for: .touchUpInside)
        return b
    }

    // MARK: - Loading overlay / toast（对齐 ObjC demo）

    private func setLoading(_ on: Bool) {
        if on {
            if loadingOverlay == nil {
                let v = UIView(frame: view.bounds)
                v.backgroundColor = UIColor.black.withAlphaComponent(0.25)
                v.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                let indicator = UIActivityIndicatorView(style: .whiteLarge)
                indicator.translatesAutoresizingMaskIntoConstraints = false
                v.addSubview(indicator)
                NSLayoutConstraint.activate([
                    indicator.centerXAnchor.constraint(equalTo: v.centerXAnchor),
                    indicator.centerYAnchor.constraint(equalTo: v.centerYAnchor),
                ])
                indicator.startAnimating()
                loadingOverlay = v
            }
            loadingOverlay?.frame = view.bounds
            if let overlay = loadingOverlay {
                view.addSubview(overlay)
            }
        } else {
            loadingOverlay?.removeFromSuperview()
        }
    }

    private func flashMessage(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                alert.dismiss(animated: true, completion: nil)
            }
        }
    }

    // MARK: - Actions

    @objc private func initSDKTapped() {
        initStatusLabel.text = "initializing..."
        MaticooAds.shareSDK().initSDK(DemoConfig.appKey) { [weak self] in
            self?.initStatusLabel.text = "init success"
            self?.flashMessage("SDK Init Success")
        } onError: { [weak self] error in
            self?.initStatusLabel.text = "init error: \(error.localizedDescription)"
            self?.flashMessage("SDK Init Error: \(error.localizedDescription)")
        }
    }

    @objc private func settingTapped() {
        let setting = SettingViewController()
        let nav = UINavigationController(rootViewController: setting)
        nav.modalPresentationStyle = .formSheet
        present(nav, animated: true, completion: nil)
    }

    @objc private func loadBannerTapped() {
        guard MaticooAds.shareSDK().isInitSuccess() else {
            bannerStatusLabel.text = "Please Init SDK first"
            return
        }
        if bannerAd == nil {
            let ad = MATBannerAd(placementID: DemoConfig.bannerPlacementID)
            ad.canCloseAd = true
            ad.delegate = self
            bannerAd = ad
        }
        bannerContainer.subviews.forEach { $0.removeFromSuperview() }
        guard let ad = bannerAd else { return }
        ad.translatesAutoresizingMaskIntoConstraints = false
        bannerContainer.addSubview(ad)
        NSLayoutConstraint.activate([
            ad.leadingAnchor.constraint(equalTo: bannerContainer.leadingAnchor),
            ad.trailingAnchor.constraint(equalTo: bannerContainer.trailingAnchor),
            ad.topAnchor.constraint(equalTo: bannerContainer.topAnchor),
            ad.bottomAnchor.constraint(equalTo: bannerContainer.bottomAnchor),
        ])
        bannerStatusLabel.text = "loading..."
        bannerContainer.isHidden = true
        ad.load()
    }

    @objc private func loadInterstitialTapped() {
        guard MaticooAds.shareSDK().isInitSuccess() else {
            interstitialStatusLabel.text = "Please Init SDK first"
            return
        }
        if interstitialAd == nil {
            let ad = MATInterstitialAd(placementID: DemoConfig.interstitialPlacementID)
            ad.delegate = self
            interstitialAd = ad
        }
        interstitialShowButton.isEnabled = false
        interstitialStatusLabel.text = "loading..."
        setLoading(true)
        interstitialAd?.loadAd()
    }

    @objc private func showInterstitialTapped() {
        guard let ad = interstitialAd else { return }
        if ad.isReady {
            interstitialStatusLabel.text = ""
            // 回传 didLoad 带回的 maticooIds（Waterfall 下 SDK 忽略匹配）
            ad.show(from: self, maticooIds: interstitialIds)
        } else {
            interstitialStatusLabel.text = "not ready"
        }
    }

    @objc private func loadRewardTapped() {
        guard MaticooAds.shareSDK().isInitSuccess() else {
            rewardStatusLabel.text = "Please Init SDK first"
            return
        }
        if rewardedVideoAd == nil {
            let ad = MATRewardedVideoAd(placementID: DemoConfig.rewardPlacementID)
            ad.delegate = self
            rewardedVideoAd = ad
        }
        rewardShowButton.isEnabled = false
        rewardStatusLabel.text = "loading..."
        setLoading(true)
        rewardedVideoAd?.loadAd()
    }

    @objc private func showRewardTapped() {
        guard let ad = rewardedVideoAd else { return }
        if ad.isReady {
            rewardStatusLabel.text = ""
            // 回传 didLoad 带回的 maticooIds（Waterfall 下 SDK 忽略匹配）
            ad.show(from: self, maticooIds: rewardIds)
        } else {
            rewardStatusLabel.text = "not ready"
        }
    }

    @objc private func loadNativeTapped() {
        guard MaticooAds.shareSDK().isInitSuccess() else {
            nativeStatusLabel.text = "Please Init SDK first"
            return
        }
        NativeAdPresenter.dismiss(animated: false)
        nativeAd?.destroy()
        nativeStatusLabel.text = "loading..."
        let ad = MATNativeAd(placementID: DemoConfig.nativePlacementID)
        ad.delegate = self
        NativeAdRenderer.configure(ad)
        nativeAd = ad
        ad.load()
    }

    @objc private func openNativeListTapped() {
        guard MaticooAds.shareSDK().isInitSuccess() else {
            flashMessage("Please Init SDK first")
            return
        }
        let listVC = NativeListViewController()
        let nav = UINavigationController(rootViewController: listVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true, completion: nil)
    }

    // MARK: - Header Bidding actions（新 API）

    /// 统一询价入口：成功后回调 biddingRequestId（内部已做主线程回跳 + reportTrack 上报）
    private func hbBid(placementID: String,
                       completion: @escaping (String) -> Void,
                       failure: @escaping (Error) -> Void) {
        let param = MATBiddingRequestParameter()
        param.placementId = placementID
        param.adxId = DemoConfig.adxID
        MATBiddingRequest.biddingRequest(with: param) { [weak self] bidResponse in
            DispatchQueue.main.async {
                guard let bidResponse = bidResponse else {
                    failure(NSError(domain: "MATDemoErrorDomain", code: -1,
                                    userInfo: [NSLocalizedDescriptionKey: "nil bid response"]))
                    return
                }
                guard bidResponse.success else {
                    let error = bidResponse.error ?? NSError(domain: "MATDemoErrorDomain", code: -1,
                                                             userInfo: [NSLocalizedDescriptionKey: "unknown bid error"])
                    self?.log("Bidding bidFailed placement=\(placementID) code=\((error as NSError).code) error=\(error.localizedDescription)")
                    failure(error)
                    return
                }
                self?.log("Bidding bidSuccess placement=\(placementID) price=\(bidResponse.price) requestId=\(bidResponse.biddingRequestId ?? "")")
                // reportTrack：真实接入应在 AdX 竞价胜出（win）后调用；demo 无 mediation，此处模拟胜出上报
                MATBiddingRequest.reportTrack(bidResponse)
                completion(bidResponse.biddingRequestId ?? "")
            }
        }
    }

    @objc private func hbBidAndLoadInterstitialTapped() {
        guard MaticooAds.shareSDK().isInitSuccess() else {
            hbInterstitialStatusLabel.text = "Please Init SDK first"
            return
        }
        if hbInterstitialAd == nil {
            let ad = MATInterstitialAd(placementID: DemoConfig.hbInterstitialPlacementID)
            ad.delegate = self
            hbInterstitialAd = ad
        }
        hbInterstitialShowButton.isEnabled = false
        hbInterstitialStatusLabel.text = "bidding..."
        hbBid(placementID: DemoConfig.hbInterstitialPlacementID,
              completion: { [weak self] biddingRequestId in
                  // Bidding 加载：回传询价得到的 requestId
                  self?.hbInterstitialAd?.load(biddingRequestId)
              },
              failure: { [weak self] error in
                  self?.hbInterstitialStatusLabel.text = "bid failed \(error.localizedDescription)"
              })
    }

    @objc private func hbShowInterstitialTapped() {
        guard let ad = hbInterstitialAd else { return }
        // isReady(with:) 与 show(from:maticooIds:) 同口径：Bidding 按 requestId 精确匹配
        if ad.isReady(with: hbInterstitialIds) {
            hbInterstitialStatusLabel.text = ""
            ad.show(from: self, maticooIds: hbInterstitialIds)
        } else {
            hbInterstitialStatusLabel.text = "not ready"
        }
    }

    @objc private func hbBidAndLoadRewardTapped() {
        guard MaticooAds.shareSDK().isInitSuccess() else {
            hbRewardStatusLabel.text = "Please Init SDK first"
            return
        }
        if hbRewardedVideoAd == nil {
            let ad = MATRewardedVideoAd(placementID: DemoConfig.hbRewardPlacementID)
            ad.delegate = self
            hbRewardedVideoAd = ad
        }
        hbRewardShowButton.isEnabled = false
        hbRewardStatusLabel.text = "bidding..."
        hbBid(placementID: DemoConfig.hbRewardPlacementID,
              completion: { [weak self] biddingRequestId in
                  // Bidding 加载：回传询价得到的 requestId
                  self?.hbRewardedVideoAd?.load(biddingRequestId)
              },
              failure: { [weak self] error in
                  self?.hbRewardStatusLabel.text = "bid failed \(error.localizedDescription)"
              })
    }

    @objc private func hbShowRewardTapped() {
        guard let ad = hbRewardedVideoAd else { return }
        // isReady(with:) 与 show(from:maticooIds:) 同口径：Bidding 按 requestId 精确匹配
        if ad.isReady(with: hbRewardIds) {
            hbRewardStatusLabel.text = ""
            ad.show(from: self, maticooIds: hbRewardIds)
        } else {
            hbRewardStatusLabel.text = "not ready"
        }
    }

    @objc private func hbBidAndLoadBannerTapped() {
        guard MaticooAds.shareSDK().isInitSuccess() else {
            hbBannerStatusLabel.text = "Please Init SDK first"
            return
        }
        if hbBannerAd == nil {
            let ad = MATBannerAd(placementID: DemoConfig.hbBannerPlacementID)
            ad.canCloseAd = true
            ad.delegate = self
            hbBannerAd = ad
        }
        hbBannerContainer.subviews.forEach { $0.removeFromSuperview() }
        guard let ad = hbBannerAd else { return }
        ad.translatesAutoresizingMaskIntoConstraints = false
        hbBannerContainer.addSubview(ad)
        NSLayoutConstraint.activate([
            ad.leadingAnchor.constraint(equalTo: hbBannerContainer.leadingAnchor),
            ad.trailingAnchor.constraint(equalTo: hbBannerContainer.trailingAnchor),
            ad.topAnchor.constraint(equalTo: hbBannerContainer.topAnchor),
            ad.bottomAnchor.constraint(equalTo: hbBannerContainer.bottomAnchor),
        ])
        hbBannerStatusLabel.text = "bidding..."
        hbBannerContainer.isHidden = true
        hbBid(placementID: DemoConfig.hbBannerPlacementID,
              completion: { [weak self] biddingRequestId in
                  // Bidding 加载：回传询价得到的 requestId
                  self?.hbBannerAd?.load(biddingRequestId)
              },
              failure: { [weak self] error in
                  self?.hbBannerStatusLabel.text = "bid failed \(error.localizedDescription)"
              })
    }

    @objc private func hbBidAndLoadNativeTapped() {
        guard MaticooAds.shareSDK().isInitSuccess() else {
            hbNativeStatusLabel.text = "Please Init SDK first"
            return
        }
        if hbNativeAd == nil {
            let ad = MATNativeAd(placementID: DemoConfig.hbNativePlacementID)
            ad.delegate = self
            NativeAdRenderer.configure(ad)
            hbNativeAd = ad
        }
        hbNativeStatusLabel.text = "bidding..."
        hbBid(placementID: DemoConfig.hbNativePlacementID,
              completion: { [weak self] biddingRequestId in
                  // Bidding 加载：回传询价得到的 requestId
                  self?.hbNativeAd?.load(biddingRequestId)
              },
              failure: { [weak self] error in
                  self?.hbNativeStatusLabel.text = "bid failed \(error.localizedDescription)"
              })
    }

    // MARK: - MATBannerAdDelegate

    func bannerAdDidLoad(_ bannerAd: MATBannerAd) {
        if bannerAd === hbBannerAd {
            hbBannerStatusLabel.text = "bid load success"
            hbBannerContainer.isHidden = false
            return
        }
        bannerStatusLabel.text = "load success"
        bannerContainer.isHidden = false
    }

    func bannerAd(_ bannerAd: MATBannerAd, didFailWithError error: Error) {
        if bannerAd === hbBannerAd {
            hbBannerStatusLabel.text = "bid load failed \(error.localizedDescription)"
            return
        }
        bannerStatusLabel.text = "load failed \(error.localizedDescription)"
    }

    func bannerAd(_ bannerAd: MATBannerAd, showFailWithError error: Error) {
        bannerStatusLabel.text = "show failed \(error.localizedDescription)"
    }

    func bannerAdDidImpression(_ bannerAd: MATBannerAd) {
        log("Banner didImpression")
    }

    func bannerAdDidClick(_ bannerAd: MATBannerAd) {
        log("Banner didClick")
    }

    func bannerAdDismissed(_ bannerAd: MATBannerAd) {
        if bannerAd === hbBannerAd {
            hbBannerContainer.isHidden = true
            hbBannerStatusLabel.text = ""
        }
        log("Banner dismissed")
    }

    // MARK: - MATInterstitialAdDelegate

    /// 新回调（SDK 新优先：实现本方法后旧 didLoad 不再回调）；持有 maticooIds 供 show 回传
    func interstitialAdDidLoad(_ interstitialAd: MATInterstitialAd, maticooIds: MATMaticooIds) {
        if interstitialAd === hbInterstitialAd {
            hbInterstitialIds = maticooIds
            hbInterstitialShowButton.isEnabled = true
            hbInterstitialStatusLabel.text = "bid load success"
            log("Bidding didLoad placement=\(DemoConfig.hbInterstitialPlacementID) requestId=\(maticooIds.biddingRequestId ?? "(waterfall)")")
            return
        }
        interstitialIds = maticooIds
        interstitialShowButton.isEnabled = true
        interstitialStatusLabel.text = "load success"
        log("Interstitial didLoad requestId=\(maticooIds.biddingRequestId ?? "(waterfall)")")
        setLoading(false)
    }

    /// 旧回调保留仅为满足协议必选；SDK 已实现新回调时不会走到这里
    func interstitialAdDidLoad(_ interstitialAd: MATInterstitialAd) {
        log("Interstitial didLoad(legacy) unreachable")
    }

    func interstitialAd(_ interstitialAd: MATInterstitialAd, didFailWithError error: Error) {
        if interstitialAd === hbInterstitialAd {
            hbInterstitialStatusLabel.text = "bid load failed \(error.localizedDescription)"
            log("Bidding didFailWithError placement=\(DemoConfig.hbInterstitialPlacementID) error=\(error.localizedDescription)")
            return
        }
        interstitialStatusLabel.text = "load failed \(error.localizedDescription)"
        setLoading(false)
    }

    func interstitialAd(_ interstitialAd: MATInterstitialAd, displayFailWithError error: Error) {
        if interstitialAd === hbInterstitialAd {
            hbInterstitialStatusLabel.text = "show failed \(error.localizedDescription)"
            return
        }
        interstitialStatusLabel.text = "show failed \(error.localizedDescription)"
    }

    func interstitialAdWillLogImpression(_ interstitialAd: MATInterstitialAd) {
        log("Interstitial willLogImpression")
    }

    func interstitialAdDidClick(_ interstitialAd: MATInterstitialAd) {
        log("Interstitial didClick")
    }

    func interstitialAdWillClose(_ interstitialAd: MATInterstitialAd) {
        log("Interstitial willClose")
    }

    func interstitialAdDidClose(_ interstitialAd: MATInterstitialAd) {
        if interstitialAd === hbInterstitialAd {
            hbInterstitialStatusLabel.text = ""
            hbInterstitialShowButton.isEnabled = false
            hbInterstitialIds = nil
            return
        }
        interstitialStatusLabel.text = ""
    }

    func interstitialAdEndCardShow(_ interstitialAd: MATInterstitialAd) {
        log("Interstitial endCardShow")
    }

    // MARK: - MATRewardedVideoAdDelegate

    /// 新回调（SDK 新优先：实现本方法后旧 didLoad 不再回调）；持有 maticooIds 供 show 回传
    func rewardedVideoAdDidLoad(_ rewardedVideoAd: MATRewardedVideoAd, maticooIds: MATMaticooIds) {
        if rewardedVideoAd === hbRewardedVideoAd {
            hbRewardIds = maticooIds
            hbRewardShowButton.isEnabled = true
            hbRewardStatusLabel.text = "bid load success"
            log("Bidding didLoad placement=\(DemoConfig.hbRewardPlacementID) requestId=\(maticooIds.biddingRequestId ?? "(waterfall)")")
            return
        }
        rewardIds = maticooIds
        rewardShowButton.isEnabled = true
        rewardStatusLabel.text = "load success"
        log("Rewarded didLoad requestId=\(maticooIds.biddingRequestId ?? "(waterfall)")")
        setLoading(false)
    }

    /// 旧回调保留仅为满足协议必选；SDK 已实现新回调时不会走到这里
    func rewardedVideoAdDidLoad(_ rewardedVideoAd: MATRewardedVideoAd) {
        log("Rewarded didLoad(legacy) unreachable")
    }

    func rewardedVideoAd(_ rewardedVideoAd: MATRewardedVideoAd, didFailWithError error: Error) {
        if rewardedVideoAd === hbRewardedVideoAd {
            hbRewardStatusLabel.text = "bid load failed \(error.localizedDescription)"
            log("Bidding didFailWithError placement=\(DemoConfig.hbRewardPlacementID) error=\(error.localizedDescription)")
            return
        }
        rewardStatusLabel.text = "load failed \(error.localizedDescription)"
        setLoading(false)
    }

    func rewardedVideoAd(_ rewardedVideoAd: MATRewardedVideoAd, displayFailWithError error: Error) {
        if rewardedVideoAd === hbRewardedVideoAd {
            hbRewardStatusLabel.text = "show failed \(error.localizedDescription)"
            return
        }
        rewardStatusLabel.text = "show failed \(error.localizedDescription)"
    }

    func rewardedVideoAdStarted(_ rewardedVideoAd: MATRewardedVideoAd) {
        log("Rewarded started")
    }

    func rewardedVideoAdCompleted(_ rewardedVideoAd: MATRewardedVideoAd) {
        log("Rewarded completed")
    }

    func rewardedVideoAdWillLogImpression(_ rewardedVideoAd: MATRewardedVideoAd) {
        log("Rewarded willLogImpression")
    }

    func rewardedVideoAdDidClick(_ rewardedVideoAd: MATRewardedVideoAd) {
        log("Rewarded didClick")
    }

    func rewardedVideoAdWillClose(_ rewardedVideoAd: MATRewardedVideoAd) {
        log("Rewarded willClose")
    }

    func rewardedVideoAdDidClose(_ rewardedVideoAd: MATRewardedVideoAd) {
        if rewardedVideoAd === hbRewardedVideoAd {
            hbRewardStatusLabel.text = ""
            hbRewardShowButton.isEnabled = false
            hbRewardIds = nil
            return
        }
        rewardStatusLabel.text = ""
    }

    func rewardedVideoAdReward(_ rewardedVideoAd: MATRewardedVideoAd, rewardInfo: MATRewardInfo) {
        let rewardId = rewardInfo.rewardId.isEmpty ? "—" : rewardInfo.rewardId
        let rewardName = rewardInfo.rewardName.isEmpty ? "—" : rewardInfo.rewardName
        log("Rewarded didReward id=\(rewardId) name=\(rewardName) amount=\(rewardInfo.rewardAmount)")
    }

    func rewardedVideoAdDidSkip(_ rewardedVideoAd: MATRewardedVideoAd) {
        log("Rewarded didSkip")
    }

    func rewardedVideoAdEndCardShow(_ rewardedVideoAd: MATRewardedVideoAd) {
        log("Rewarded endCardShow")
    }

    // MARK: - MATNativeAdDelegate

    func nativeAdLoadSuccess(_ nativeAd: MATNativeAd) {
        if nativeAd === hbNativeAd {
            hbNativeStatusLabel.text = "bid load success"
            log("Native(Bidding) didLoad")
            NativeAdPresenter.present(nativeAd, from: self) { [weak self] in
                self?.hbNativeStatusLabel.text = ""
                self?.hbNativeAd?.destroy()
                self?.hbNativeAd = nil
            }
            return
        }
        nativeStatusLabel.text = "load success"
        log("Native didLoad")
        NativeAdPresenter.present(nativeAd, from: self) { [weak self] in
            self?.nativeStatusLabel.text = ""
            self?.nativeAd?.destroy()
            self?.nativeAd = nil
        }
    }

    func nativeAdFailed(_ nativeAd: MATNativeAd, withError error: Error) {
        if nativeAd === hbNativeAd {
            hbNativeStatusLabel.text = "bid load failed \(error.localizedDescription)"
            return
        }
        nativeStatusLabel.text = "load failed \(error.localizedDescription)"
        flashMessage("Native load failed")
    }

    func nativeAdDisplayed(_ nativeAd: MATNativeAd) {
        log("Native displayed")
    }

    func nativeAd(_ nativeAd: MATNativeAd, displayFailWithError error: Error) {
        nativeStatusLabel.text = "show failed \(error.localizedDescription)"
        flashMessage("Native show failed")
    }

    func nativeAdClicked(_ nativeAd: MATNativeAd) {
        log("Native clicked")
        flashMessage("Native clicked")
    }

    // MARK: - Misc

    private func log(_ message: String) {
        print("[SwiftDemo] \(message)")
    }
}
