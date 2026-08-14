//
//  NativeAdPresenter.swift
//  zmaticoo-ios-demo-swift
//
//  Swift 版全屏原生广告展示：对齐 ObjC 版 MATNativeAdPresenter
//  （半透明遮罩 + 居中卡片 + 角标关闭按钮 + 缩放淡入动画）。
//

import UIKit
import MaticooSDK

final class NativeAdPresenter {

    private static let closeButtonSize: CGFloat = 22
    private static let closeHitInset: CGFloat = 8
    private static let closeCornerOffset: CGFloat = 8
    private static let diagonal: CGFloat = 0.70710678118654752440

    private static var overlay: UIView?
    private static var onDismiss: (() -> Void)?

    private static func makeCloseButton() -> UIButton {
        let button = EnlargedHitAreaButton(type: .custom)
        button.setTitle("✕", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        button.setTitleColor(UIColor(white: 0.35, alpha: 1), for: .normal)
        button.backgroundColor = UIColor(white: 1, alpha: 0.95)
        button.layer.cornerRadius = closeButtonSize / 2
        button.layer.borderColor = UIColor(white: 0.88, alpha: 1).cgColor
        button.layer.borderWidth = 0.5
        button.clipsToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityLabel = "Close ad"
        button.accessibilityTraits = .button
        button.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        return button
    }

    @objc private static func closeTapped() {
        dismiss(animated: true)
    }

    static func isPresenting() -> Bool {
        return overlay != nil
    }

    static func dismiss(animated: Bool) {
        guard let currentOverlay = overlay else { return }
        let dismissBlock = onDismiss
        overlay = nil
        onDismiss = nil

        let cleanup: () -> Void = {
            currentOverlay.removeFromSuperview()
            dismissBlock?()
        }

        guard animated else {
            cleanup()
            return
        }
        UIView.animate(withDuration: 0.2, animations: {
            currentOverlay.alpha = 0
        }, completion: { _ in
            cleanup()
        })
    }

    static func present(_ nativeAd: MATNativeAd, from host: UIViewController, onDismiss: (() -> Void)? = nil) {
        guard let hostView = host.view else { return }

        dismiss(animated: false)
        self.onDismiss = onDismiss

        let width = DemoTheme.nativeCardWidth
        let shellHeight = NativeAdRenderer.preferredHeight(for: nativeAd, width: width)

        let diagonalShift = closeCornerOffset * diagonal
        let topInset = ceil(closeButtonSize / 2 + diagonalShift)
        let wrapperHeight = shellHeight + topInset

        // 点击遮罩空白处不关闭（hitTest 透传）
        let overlayView = PassthroughView(frame: hostView.bounds)
        overlayView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        hostView.addSubview(overlayView)

        let wrapper = UIView()
        wrapper.translatesAutoresizingMaskIntoConstraints = false
        wrapper.clipsToBounds = false
        wrapper.layer.shadowColor = UIColor.black.cgColor
        wrapper.layer.shadowOffset = CGSize(width: 0, height: 4)
        wrapper.layer.shadowRadius = 12
        wrapper.layer.shadowOpacity = 0.2
        overlayView.addSubview(wrapper)

        let shellHost = UIView()
        shellHost.translatesAutoresizingMaskIntoConstraints = false
        shellHost.clipsToBounds = false
        wrapper.addSubview(shellHost)

        NativeAdRenderer.render(nativeAd, in: shellHost, width: width)

        let closeButton = makeCloseButton()
        overlayView.addSubview(closeButton)

        NSLayoutConstraint.activate([
            wrapper.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            wrapper.centerYAnchor.constraint(equalTo: overlayView.centerYAnchor),
            wrapper.widthAnchor.constraint(equalToConstant: width),
            wrapper.heightAnchor.constraint(equalToConstant: wrapperHeight),

            shellHost.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
            shellHost.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
            shellHost.topAnchor.constraint(equalTo: wrapper.topAnchor, constant: topInset),
            shellHost.heightAnchor.constraint(equalToConstant: shellHeight),

            closeButton.widthAnchor.constraint(equalToConstant: closeButtonSize),
            closeButton.heightAnchor.constraint(equalToConstant: closeButtonSize),
            closeButton.centerXAnchor.constraint(equalTo: wrapper.trailingAnchor, constant: diagonalShift),
            closeButton.centerYAnchor.constraint(equalTo: wrapper.topAnchor, constant: topInset - diagonalShift),
        ])

        overlayView.bringSubviewToFront(closeButton)
        overlay = overlayView

        wrapper.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        wrapper.alpha = 0
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut, animations: {
            wrapper.transform = .identity
            wrapper.alpha = 1
        }, completion: nil)
    }
}

/// 点击自身（非子视图区域）时透传，避免遮挡宿主页面交互
private final class PassthroughView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hit = super.hitTest(point, with: event)
        return hit == self ? nil : hit
    }
}

/// 关闭按钮：扩大点击热区（对齐 ObjC 版 MATNativeCloseButton）
private final class EnlargedHitAreaButton: UIButton {
    private static let hitInset: CGFloat = 8

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let hitFrame = bounds.insetBy(dx: -Self.hitInset, dy: -Self.hitInset)
        return hitFrame.contains(point)
    }
}
