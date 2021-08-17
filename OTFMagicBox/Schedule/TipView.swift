//
//  TipView.swift
//  CompletelyNewApp
//
//  Created by Spurti Benakatti on 08/07/21.
//

import UIKit
import OTFCareKit
import OTFCareKitUI

class TipView: OCKView, OCKCardable {

    var cardView: UIView { self }
    let contentView: UIView = OCKView()
    let headerView = OCKHeaderView()
    let imageView = UIImageView()
    var imageHeightConstraint: NSLayoutConstraint!

    private let blurView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.regular)
        return UIVisualEffectView(effect: blurEffect)
    }()

    override init() {
        super.init()
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        headerView.detailLabel.textColor = .secondaryLabel

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = layer.cornerRadius

        blurView.clipsToBounds = true
        blurView.layer.cornerRadius = layer.cornerRadius
        blurView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        contentView.frame = bounds

        addSubview(contentView)
        contentView.addSubview(imageView)
        contentView.addSubview(blurView)
        contentView.addSubview(headerView)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        blurView.translatesAutoresizingMaskIntoConstraints = false
        headerView.translatesAutoresizingMaskIntoConstraints = false
        imageHeightConstraint = imageView.heightAnchor.constraint(
            equalToConstant: scaledImageHeight(compatibleWith: traitCollection))

        NSLayoutConstraint.activate([
            headerView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            headerView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),

            blurView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            blurView.topAnchor.constraint(equalTo: contentView.topAnchor),
            blurView.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16),

            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageHeightConstraint
        ])
    }

    func scaledImageHeight(compatibleWith traitCollection: UITraitCollection) -> CGFloat {
        return UIFontMetrics.default.scaledValue(for: 200, compatibleWith: traitCollection)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            imageHeightConstraint.constant = scaledImageHeight(compatibleWith: traitCollection)
        }
    }

    override func styleDidChange() {
        super.styleDidChange()
        let cachedStyle = style()
        enableCardStyling(true, style: cachedStyle)
        directionalLayoutMargins = cachedStyle.dimension.directionalInsets1
    }
}
