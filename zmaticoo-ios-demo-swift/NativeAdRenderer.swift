//
//  NativeAdRenderer.swift
//  zmaticoo-ios-demo-swift
//
//  Swift 版原生广告渲染器：布局与样式对齐 ObjC 版 MATNativeAdRenderer
//  （主题卡片 + 媒体区 + AD 角标 + SDK AdChoicesView + icon/headline/advertiser/body + 通栏 CTA）。
//

import UIKit
import MaticooSDK

enum NativeAdRenderer {

    // MARK: - Constants (对齐 ObjC 版)

    private static let cardPadding: CGFloat = 12
    private static let cardCornerRadius: CGFloat = 12
    private static let iconSize: CGFloat = 44
    private static let ctaHeight: CGFloat = 40
    private static let mediaMaxHeightRatio: CGFloat = 0.72
    private static let iconRowGap: CGFloat = 10
    private static let bodyTopGap: CGFloat = 8
    private static let ctaTopGap: CGFloat = 10
    private static let bodyMaxLines = 2
    private static let defaultCTAText = "Learn More"
    private static let defaultAspect: CGFloat = 16.0 / 9.0
    private static let badgeSize = CGSize(width: 22, height: 14)
    private static let adChoicesSize = CGSize(width: 52, height: 14)

    // MARK: - Configure

    /// load 前调用：视频素材默认静音起播
    static func configure(_ nativeAd: MATNativeAd) {
        let options = MATNativeAdOptions()
        let videoOptions = MATVideoOptions()
        videoOptions.startMuted = true
        options.videoOptions = videoOptions
        nativeAd.setNativeAdOptions(options)
    }

    // MARK: - Height calculation

    static func mediaAspect(for elements: MATNativeAdElements) -> CGFloat {
        let media = elements.mediaContent
        if media.aspectRatio > 0.01 && media.aspectRatio <= 10.0 {
            return media.aspectRatio
        }
        if elements.icon.aspectRatio > 0.01 {
            return elements.icon.aspectRatio
        }
        return defaultAspect
    }

    static func mediaHeight(for elements: MATNativeAdElements, width: CGFloat) -> CGFloat {
        let innerWidth = max(width - cardPadding * 2, 44)
        let aspect = mediaAspect(for: elements)
        let mediaHeight = innerWidth / max(aspect, 0.01)
        return min(mediaHeight, width * mediaMaxHeightRatio)
    }

    static func preferredHeight(for elements: MATNativeAdElements, width: CGFloat) -> CGFloat {
        let width = max(width, 280)
        let innerWidth = max(width - cardPadding * 2, 44)
        let mediaH = mediaHeight(for: elements, width: width)

        let bodyFont = UIFont.systemFont(ofSize: 13)
        var bodyH = textBlockHeight(text: elements.body, font: bodyFont, width: innerWidth, maxLines: bodyMaxLines)
        if bodyH < bodyFont.lineHeight && !elements.body.isEmpty {
            bodyH = bodyFont.lineHeight
        }

        return ceil(cardPadding
            + mediaH
            + iconRowGap
            + iconSize
            + bodyTopGap
            + bodyH
            + ctaTopGap
            + ctaHeight
            + cardPadding)
    }

    static func preferredHeight(for nativeAd: MATNativeAd, width: CGFloat) -> CGFloat {
        return preferredHeight(for: nativeAd.nativeElements, width: width)
    }

    private static func textBlockHeight(text: String, font: UIFont, width: CGFloat, maxLines: Int) -> CGFloat {
        guard !text.isEmpty, maxLines > 0 else { return 0 }
        let maxHeight = ceil(font.lineHeight * CGFloat(maxLines) + font.leading * CGFloat(max(0, maxLines - 1)))
        let bounds = text.boundingRect(
            with: CGSize(width: width, height: maxHeight),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )
        return min(ceil(bounds.height), maxHeight)
    }

    // MARK: - Render

    /// 渲染 native 广告到 container（清空既有子视图），并注册点击交互。
    @discardableResult
    static func render(_ nativeAd: MATNativeAd, in container: UIView, width: CGFloat) -> UIView? {
        container.subviews.forEach { $0.removeFromSuperview() }
        container.constraints.forEach { container.removeConstraint($0) }

        let elements = nativeAd.nativeElements
        let width = max(width, 280)
        let height = preferredHeight(for: elements, width: width)
        let mediaH = mediaHeight(for: elements, width: width)

        // 卡片外壳（对齐 ObjC：主题卡片样式）
        let shell = UIView()
        DemoTheme.applyCardStyle(to: shell, cornerRadius: cardCornerRadius)
        shell.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(shell)

        // 媒体容器 + SDK 媒体视图
        let mediaHostView = UIView()
        mediaHostView.backgroundColor = DemoTheme.mediaPlaceholderColor
        mediaHostView.clipsToBounds = true
        mediaHostView.layer.cornerRadius = 8.0
        mediaHostView.translatesAutoresizingMaskIntoConstraints = false
        shell.addSubview(mediaHostView)

        let mediaView = MATMediaView()
        mediaView.backgroundColor = .clear
        mediaView.translatesAutoresizingMaskIntoConstraints = false
        mediaHostView.addSubview(mediaView)

        // AD 角标
        let adBadgeLabel = UILabel()
        adBadgeLabel.text = "AD"
        adBadgeLabel.font = UIFont.boldSystemFont(ofSize: 9.0)
        adBadgeLabel.textColor = .white
        adBadgeLabel.backgroundColor = DemoTheme.adBadgeColor
        adBadgeLabel.textAlignment = .center
        adBadgeLabel.layer.cornerRadius = 3.0
        adBadgeLabel.clipsToBounds = true
        adBadgeLabel.translatesAutoresizingMaskIntoConstraints = false
        shell.addSubview(adBadgeLabel)

        // AdChoices（SDK 组件：内部处理 ad choice 点击）
        let adChoicesView = MATAdChoicesView()
        adChoicesView.translatesAutoresizingMaskIntoConstraints = false
        shell.addSubview(adChoicesView)

        // Icon
        let iconView = UIImageView()
        iconView.contentMode = .scaleAspectFill
        iconView.clipsToBounds = true
        iconView.layer.cornerRadius = 8.0
        iconView.backgroundColor = UIColor(white: 0.94, alpha: 1.0)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.setContentCompressionResistancePriority(.required, for: .horizontal)
        iconView.setContentCompressionResistancePriority(.required, for: .vertical)
        iconView.setContentHuggingPriority(.required, for: .horizontal)
        iconView.setContentHuggingPriority(.required, for: .vertical)
        shell.addSubview(iconView)

        // Headline
        let headlineLabel = label(text: elements.headline,
                                  font: UIFont.boldSystemFont(ofSize: 15.0),
                                  color: DemoTheme.primaryTextColor,
                                  numberOfLines: 2)
        shell.addSubview(headlineLabel)

        // Advertiser
        let advertiserLabel = label(text: elements.advertiser ?? "",
                                    font: UIFont.systemFont(ofSize: 11.0),
                                    color: DemoTheme.tertiaryTextColor,
                                    numberOfLines: 1)
        advertiserLabel.isHidden = (elements.advertiser ?? "").isEmpty
        shell.addSubview(advertiserLabel)

        // Body
        let bodyLabel = label(text: elements.body,
                              font: UIFont.systemFont(ofSize: 13.0),
                              color: DemoTheme.secondaryTextColor,
                              numberOfLines: bodyMaxLines)
        shell.addSubview(bodyLabel)

        // CTA（对齐 ObjC：通栏 Label 而非按钮）
        let ctaText = elements.callToAction.isEmpty ? defaultCTAText : elements.callToAction
        let ctaLabel = label(text: ctaText,
                             font: UIFont.boldSystemFont(ofSize: 15.0),
                             color: .white,
                             numberOfLines: 1)
        ctaLabel.textAlignment = .center
        ctaLabel.backgroundColor = DemoTheme.primaryAccentColor
        ctaLabel.layer.cornerRadius = 8.0
        ctaLabel.clipsToBounds = true
        ctaLabel.isUserInteractionEnabled = true
        shell.addSubview(ctaLabel)

        let bodyH = max(textBlockHeight(text: elements.body,
                                        font: UIFont.systemFont(ofSize: 13),
                                        width: max(width - cardPadding * 2, 44),
                                        maxLines: bodyMaxLines),
                        UIFont.systemFont(ofSize: 13).lineHeight)

        NSLayoutConstraint.activate([
            shell.topAnchor.constraint(equalTo: container.topAnchor),
            shell.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            shell.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            shell.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            shell.widthAnchor.constraint(equalToConstant: width),
            shell.heightAnchor.constraint(equalToConstant: height),

            // 媒体区
            mediaHostView.topAnchor.constraint(equalTo: shell.topAnchor, constant: cardPadding),
            mediaHostView.leadingAnchor.constraint(equalTo: shell.leadingAnchor, constant: cardPadding),
            mediaHostView.trailingAnchor.constraint(equalTo: shell.trailingAnchor, constant: -cardPadding),
            mediaHostView.heightAnchor.constraint(equalToConstant: mediaH),

            mediaView.topAnchor.constraint(equalTo: mediaHostView.topAnchor),
            mediaView.leadingAnchor.constraint(equalTo: mediaHostView.leadingAnchor),
            mediaView.trailingAnchor.constraint(equalTo: mediaHostView.trailingAnchor),
            mediaView.bottomAnchor.constraint(equalTo: mediaHostView.bottomAnchor),

            // AD 角标 + AdChoices（媒体左上角）
            adBadgeLabel.topAnchor.constraint(equalTo: mediaHostView.topAnchor, constant: 6.0),
            adBadgeLabel.leadingAnchor.constraint(equalTo: mediaHostView.leadingAnchor, constant: 6.0),
            adBadgeLabel.widthAnchor.constraint(equalToConstant: badgeSize.width),
            adBadgeLabel.heightAnchor.constraint(equalToConstant: badgeSize.height),

            adChoicesView.topAnchor.constraint(equalTo: adBadgeLabel.topAnchor),
            adChoicesView.leadingAnchor.constraint(equalTo: adBadgeLabel.trailingAnchor, constant: 4.0),
            adChoicesView.widthAnchor.constraint(equalToConstant: adChoicesSize.width),
            adChoicesView.heightAnchor.constraint(equalToConstant: adChoicesSize.height),

            // Icon 行
            iconView.topAnchor.constraint(equalTo: mediaHostView.bottomAnchor, constant: iconRowGap),
            iconView.leadingAnchor.constraint(equalTo: shell.leadingAnchor, constant: cardPadding),
            iconView.widthAnchor.constraint(equalToConstant: iconSize),
            iconView.heightAnchor.constraint(equalToConstant: iconSize),

            // Headline / Advertiser（icon 右侧）
            headlineLabel.topAnchor.constraint(equalTo: iconView.topAnchor),
            headlineLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 10.0),
            headlineLabel.trailingAnchor.constraint(equalTo: shell.trailingAnchor, constant: -cardPadding),

            advertiserLabel.topAnchor.constraint(equalTo: headlineLabel.bottomAnchor, constant: 2.0),
            advertiserLabel.leadingAnchor.constraint(equalTo: headlineLabel.leadingAnchor),
            advertiserLabel.trailingAnchor.constraint(equalTo: headlineLabel.trailingAnchor),
            advertiserLabel.bottomAnchor.constraint(lessThanOrEqualTo: iconView.bottomAnchor),

            // Body
            bodyLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: bodyTopGap),
            bodyLabel.leadingAnchor.constraint(equalTo: shell.leadingAnchor, constant: cardPadding),
            bodyLabel.trailingAnchor.constraint(equalTo: shell.trailingAnchor, constant: -cardPadding),
            bodyLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: bodyH),

            // CTA 通栏
            ctaLabel.topAnchor.constraint(equalTo: bodyLabel.bottomAnchor, constant: ctaTopGap),
            ctaLabel.leadingAnchor.constraint(equalTo: shell.leadingAnchor, constant: cardPadding),
            ctaLabel.trailingAnchor.constraint(equalTo: shell.trailingAnchor, constant: -cardPadding),
            ctaLabel.bottomAnchor.constraint(equalTo: shell.bottomAnchor, constant: -cardPadding),
            ctaLabel.heightAnchor.constraint(equalToConstant: ctaHeight),
        ])

        if let image = elements.icon.image {
            iconView.image = image
        } else if let url = elements.icon.imageURL {
            loadImage(from: url) { image in
                iconView.image = image
            }
        }

        // AdChoices 绑定广告实例（SDK 组件内部处理点击）
        adChoicesView.setNativeAd(nativeAd)

        // 绑定点击区域并启动可见性检测（load 成功后、主线程调用）
        nativeAd.registerView(forInteraction: shell,
                              mediaView: mediaView,
                              clickableViews: [ctaLabel, headlineLabel, bodyLabel, iconView, mediaHostView])
        return shell
    }

    private static func label(text: String, font: UIFont, color: UIColor, numberOfLines: Int) -> UILabel {
        let label = UILabel()
        label.font = font
        label.textColor = color
        label.text = text.isEmpty ? "" : text
        label.numberOfLines = numberOfLines
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }

    private static func loadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, _, _ in
            DispatchQueue.main.async {
                completion(data.flatMap { UIImage(data: $0) })
            }
        }.resume()
    }
}
