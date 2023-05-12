//
//  DataSourceViews.swift
//  launchOptions
//
//  Created by Aleksey Bakhtin on 12/20/17.
//  Copyright © 2018 launchOptions. All rights reserved.
//

#if os(iOS)
import UIKit

public class DataSourceCell<Type>: UITableViewCell {
    func configure(with object: Type) { }
}

public protocol DataSourceHeaderFooter {
    func configure(with object: DataSourceSectionInfo)
}

public class DataSourceCollectionCell<Type>: UICollectionViewCell {
    func configure(with object: Type) { }
}

public protocol DataSourcePositionHandler {
    func configure(for position: UITableViewCellPosition)
}

public protocol DataSourceExpandable {
    var expanded: Bool? { get set }
    var closedContraints: [NSLayoutConstraint]! { get }
    var expandedConstraints: [NSLayoutConstraint]! { get }
    mutating func setExpanded(value: Bool)
}

public extension DataSourceExpandable {
    mutating func setExpanded(value: Bool) {
        expanded = value
    }
}

extension DataSource {
    public var noDataViewText: String? {
        get {
            return noDataViewAsLabel?.text
        }
        set {
            let noDataView = UILabel()
            noDataView.textColor = UIColor(red: 56.0 / 255.0, green: 70.0 / 255.0, blue: 80.0 / 255.0, alpha: 1.0)
            noDataView.numberOfLines = 0
            noDataView.textAlignment = .center
            noDataViewAsLabel = noDataView

            noDataViewAsLabel?.text = newValue
        }
    }
    
    private var noDataViewAsLabel: UILabel? {
        get {
            return noDataView as? UILabel
        }
        set {
            noDataView = newValue
        }
    }
}

public protocol HasBackgroundView: UIScrollView {
    var backgroundView: UIView? { get set }
}

extension UITableView: HasBackgroundView { }
extension UICollectionView: HasBackgroundView { }

#endif
