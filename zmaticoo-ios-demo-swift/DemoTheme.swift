//
//  DemoTheme.swift
//  zmaticoo-ios-demo-swift
//
//  Swift 版主题：与 ObjC 版 MATDemoTheme 完全对齐（颜色 / 卡片 / 按钮 / nativeCardWidth）。
//

import UIKit

enum DemoTheme {

    // MARK: - Colors

    static var groupedBackgroundColor: UIColor {
        if #available(iOS 13.0, *) {
            return .systemGroupedBackground
        }
        return .groupTableViewBackground
    }

    static var cardBackgroundColor: UIColor {
        if #available(iOS 13.0, *) {
            return .secondarySystemGroupedBackground
        }
        return .white
    }

    static var primaryAccentColor: UIColor {
        return UIColor(red: 0.12, green: 0.52, blue: 0.98, alpha: 1.0)
    }

    static var primaryTextColor: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor(white: 0.12, alpha: 1.0)
        }
        return .black
    }

    static var secondaryTextColor: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor(white: 0.35, alpha: 1.0)
        }
        return .darkGray
    }

    static var tertiaryTextColor: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor(white: 0.55, alpha: 1.0)
        }
        return .gray
    }

    static var cardBorderColor: UIColor {
        return UIColor(white: 0.90, alpha: 1.0)
    }

    static var mediaPlaceholderColor: UIColor {
        return UIColor(white: 0.96, alpha: 1.0)
    }

    static var adBadgeColor: UIColor {
        return UIColor(red: 0.95, green: 0.45, blue: 0.15, alpha: 1.0)
    }

    // MARK: - Styles

    static func applyCardStyle(to view: UIView, cornerRadius: CGFloat) {
        view.backgroundColor = .white
        view.layer.cornerRadius = cornerRadius
        view.layer.borderColor = cardBorderColor.cgColor
        view.layer.borderWidth = 0.5
        view.clipsToBounds = true
    }

    static func applyPrimaryButtonStyle(to button: UIButton) {
        button.layer.cornerRadius = 10.0
        button.layer.masksToBounds = true
        button.contentEdgeInsets = UIEdgeInsets(top: 11, left: 14, bottom: 11, right: 14)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15.0)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = primaryAccentColor
    }

    static func applySecondaryButtonStyle(to button: UIButton) {
        button.layer.cornerRadius = 10.0
        button.layer.masksToBounds = true
        button.contentEdgeInsets = UIEdgeInsets(top: 11, left: 14, bottom: 11, right: 14)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15.0, weight: .medium)
        button.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        button.layer.borderWidth = 0.5
        button.layer.borderColor = cardBorderColor.cgColor
        button.setTitleColor(primaryTextColor, for: .normal)
    }

    // MARK: - Native card width (aligned with TopOn shell: ~86% screen, capped)

    static var nativeCardWidth: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        var width = floor(screenWidth * 0.86)
        width = min(width, 360.0)
        width = max(width, 300.0)
        width = min(width, screenWidth - 28.0 * 2.0)
        return max(width, 280.0)
    }
}
