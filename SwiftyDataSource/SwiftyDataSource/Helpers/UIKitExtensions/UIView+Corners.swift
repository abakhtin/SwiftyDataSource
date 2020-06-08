//
//  UIView+Corners.swift
//  launchOptions
//
//  Created by Alexey Bakhtin on 9/20/18.
//  Copyright © 2018 launchOptions. All rights reserved.
//

import UIKit

public extension UIView {
    // Should be called after views layout
    
    func round(corners: UIRectCorner, byRadius value: CGFloat) {
        if #available(iOS 11, *) {
            layer.cornerRadius = value
            layer.maskedCorners = CACornerMask(rawValue: corners.rawValue)
        } else {
            round(corners: corners, byRadii: CGSize(width: value, height: value))
        }
    }

    func round(corners: UIRectCorner, byRadii value: CGSize) {
        let path = UIBezierPath(
            roundedRect: self.bounds,
            byRoundingCorners: corners,
            cornerRadii: value
        )
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        self.layer.mask = mask
    }
}
