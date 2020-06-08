//
//  UIView+Corners.swift
//  launchOptions
//
//  Created by Alexey Bakhtin on 9/20/18.
//  Copyright © 2018 launchOptions. All rights reserved.
//

import UIKit

public extension UIView {
    enum Corner: Int {
        case bottomRight = 0,
        topRight,
        bottomLeft,
        topLeft
    }
    
    private func round(corner: Corner) -> CACornerMask.Element {
        let corners: [CACornerMask.Element] = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMinXMinYCorner]
        return corners[corner.rawValue]
    }
    
    private func createMask(corners: [Corner]) -> UInt {
        return corners.reduce(0, { (a, b) -> UInt in
            return a + round(corner: b).rawValue
        })
    }
    
    @available(iOS 11, *)
    func round(corners: [Corner], byRadius value: CGFloat) {
        layer.cornerRadius = value
        let maskedCorners: CACornerMask = CACornerMask(rawValue: createMask(corners: corners))
        layer.maskedCorners = maskedCorners
    }
    
    
    // Should be called after views layout
    func round(corners: UIRectCorner, byRadius value: CGFloat) {
        round(corners: corners, byRadii: CGSize(width: value, height: value))
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
