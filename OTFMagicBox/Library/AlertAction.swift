//
//  AlertAction.swift
//  OTFMagicBox
//
//  Created by Sakib Kurtic on 9/10/22.
//

import Foundation

public class AlertAction {
    public enum Style: Int {
        case `default` = 0
        case cancel
        case destructive
    }

    public let title: String
    public let style: Style
    public let handler: (() -> Void)

    public init(title: String,
         style: Style = .default,
         handler: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.handler = handler
    }
}
