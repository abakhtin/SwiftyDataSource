//
//  TableViewDataSourceDelegate.swift
//  launchOptions
//
//  Created by Aleksey Bakhtin on 12/20/17.
//  Copyright © 2018 launchOptions. All rights reserved.
//

#if os(iOS)
import UIKit

// MARK: DataSource for customizing default behaviour of dataSource

public protocol TableViewDataSourceDelegate: AnyObject {
    associatedtype ObjectType
    func dataSource(_ dataSource: DataSourceProtocol, setupCell cell: UITableViewCell, at indexPath: IndexPath)
    func dataSource(_ dataSource: DataSourceProtocol, cellIdentifierFor object: ObjectType, at indexPath: IndexPath) -> String?
    func dataSource(_ dataSource: DataSourceProtocol, accessoryTypeFor object: ObjectType, at indexPath: IndexPath) -> UITableViewCell.AccessoryType?
    func dataSource(_ dataSource: DataSourceProtocol, didSelect object: ObjectType, at indexPath: IndexPath)
    func dataSource(_ dataSource: DataSourceProtocol, didDeselect object: ObjectType, at indexPath: IndexPath?)
    func dataSourceDidScrollToLastElement(_ dataSource: DataSourceProtocol)
    func dataSourceLeadingSwipeActions(_ dataSource: DataSourceProtocol, didSwipe object: ObjectType, at indexPath: IndexPath) -> UISwipeActionsConfiguration?
    func dataSourceTrailingSwipeActions(_ dataSource: DataSourceProtocol, didSwipe object: ObjectType, at indexPath: IndexPath) -> UISwipeActionsConfiguration?
}

// MARK: Default implementation as all of methods are optional

public extension TableViewDataSourceDelegate {
    func dataSource(_ dataSource: DataSourceProtocol, setupCell cell: UITableViewCell, at indexPath: IndexPath) { }
    func dataSource(_ dataSource: DataSourceProtocol, cellIdentifierFor object: ObjectType, at indexPath: IndexPath) -> String? { nil }
    func dataSource(_ dataSource: DataSourceProtocol, accessoryTypeFor object: ObjectType, at indexPath: IndexPath) -> UITableViewCell.AccessoryType? { nil }
    func dataSource(_ dataSource: DataSourceProtocol, didSelect object: ObjectType, at indexPath: IndexPath) { }
    func dataSource(_ dataSource: DataSourceProtocol, didDeselect object: ObjectType, at indexPath: IndexPath?) { }
    func dataSourceDidScrollToLastElement(_ dataSource: DataSourceProtocol) { }
    func dataSourceLeadingSwipeActions(_ dataSource: DataSourceProtocol, didSwipe object: ObjectType, at indexPath: IndexPath) -> UISwipeActionsConfiguration? { nil }
    func dataSourceTrailingSwipeActions(_ dataSource: DataSourceProtocol, didSwipe object: ObjectType, at indexPath: IndexPath) -> UISwipeActionsConfiguration? { nil }
}


// MARK: Type erasure for protocol with associated type. So we can use protocol for initializing

public class AnyTableViewDataSourceDelegate<T>: TableViewDataSourceDelegate {
    private let _dataSourceSetupCellAtIndexPath: (DataSourceProtocol, UITableViewCell, IndexPath) -> Void
    private let _dataSourceCellIdentifierForObjectAtIndexPath: (DataSourceProtocol, T, IndexPath) -> String?
    private let _dataSourceAccessoryTypeForObjectAtIndexPath: (DataSourceProtocol, T, IndexPath) -> UITableViewCell.AccessoryType?
    private let _dataSourceDidSelectObjectAtIndexPath: (DataSourceProtocol, T, IndexPath) -> Void
    private let _dataSourceDidDeselectObjectAtIndexPath: (DataSourceProtocol, T, IndexPath?) -> Void
    private let _dataSourceDidScrollToLastElement: (DataSourceProtocol) -> Void
    private let _dataSourceLeadingSwipeActions: (DataSourceProtocol, T, IndexPath) -> UISwipeActionsConfiguration?
    private let _dataSourceTrailingSwipeActions: (DataSourceProtocol, T, IndexPath) -> UISwipeActionsConfiguration?
    
    public required init<U: TableViewDataSourceDelegate>(_ delegate: U) where U.ObjectType == T {
        _dataSourceCellIdentifierForObjectAtIndexPath = { [weak delegate] in delegate?.dataSource($0, cellIdentifierFor: $1, at: $2) }
        _dataSourceAccessoryTypeForObjectAtIndexPath = { [weak delegate] in delegate?.dataSource($0, accessoryTypeFor: $1, at: $2) }
        _dataSourceDidSelectObjectAtIndexPath = { [weak delegate] in
            delegate?.dataSource($0, didSelect: $1, at: $2) }
        _dataSourceDidDeselectObjectAtIndexPath = { [weak delegate] in
            delegate?.dataSource($0, didDeselect: $1, at: $2) }
        _dataSourceDidScrollToLastElement = { [weak delegate] in delegate?.dataSourceDidScrollToLastElement($0)}
        _dataSourceLeadingSwipeActions = { [weak delegate] in delegate?.dataSourceLeadingSwipeActions($0, didSwipe: $1, at: $2)}
        _dataSourceTrailingSwipeActions = { [weak delegate] in delegate?.dataSourceTrailingSwipeActions($0, didSwipe: $1, at: $2)}
        _dataSourceSetupCellAtIndexPath = { [weak delegate] in
            delegate?.dataSource($0, setupCell: $1, at: $2)
        }
    }
    
    public func dataSourceTrailingSwipeActions(_ dataSource: DataSourceProtocol, didSwipe object: T, at indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        _dataSourceTrailingSwipeActions(dataSource, object, indexPath)
    }
    
    public func dataSourceLeadingSwipeActions(_ dataSource: DataSourceProtocol, didSwipe object: T, at indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        _dataSourceLeadingSwipeActions(dataSource, object, indexPath)
    }
    
    public func dataSourceDidScrollToLastElement(_ dataSource: DataSourceProtocol) {
        _dataSourceDidScrollToLastElement(dataSource)
    }

    public func dataSource(_ dataSource: DataSourceProtocol, cellIdentifierFor object: T, at indexPath: IndexPath) -> String? {
        _dataSourceCellIdentifierForObjectAtIndexPath(dataSource, object, indexPath)
    }
    
    public func dataSource(_ dataSource: DataSourceProtocol, accessoryTypeFor object: T, at indexPath: IndexPath) -> UITableViewCell.AccessoryType? {
        _dataSourceAccessoryTypeForObjectAtIndexPath(dataSource, object, indexPath)
    }
    
    public func dataSource(_ dataSource: DataSourceProtocol, didSelect object: T, at indexPath: IndexPath) {
        _dataSourceDidSelectObjectAtIndexPath(dataSource, object, indexPath)
    }

    public func dataSource(_ dataSource: DataSourceProtocol, didDeselect object: T, at indexPath: IndexPath?) {
        _dataSourceDidDeselectObjectAtIndexPath(dataSource, object, indexPath)
    }
    
    public func dataSource(_ dataSource: DataSourceProtocol, setupCell cell: UITableViewCell, at indexPath: IndexPath) {
        _dataSourceSetupCellAtIndexPath(dataSource, cell, indexPath)
    }
}
#endif
