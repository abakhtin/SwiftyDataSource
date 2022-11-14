//
//  HasBackgroundView.swift
//  SwiftyDataSource
//
//  Created by Alex Rybchinskiy on 14.11.22.
//  Copyright © 2022 EffectiveSoft. All rights reserved.
//

#if os(iOS)
import UIKit

public protocol HasBackgroundView: UIScrollView {
    var backgroundView: UIView? { get set }
}

extension UITableView: HasBackgroundView { }
extension UICollectionView: HasBackgroundView { }
#endif
