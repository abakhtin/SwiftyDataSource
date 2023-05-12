//
//  CollectionViewDataSourceDelegate.swift
//  SwiftyDataSource
//
//  Created by Ruslan Latfulin on 12/16/19.
//  Copyright © 2019 launchOptions. All rights reserved.
//

#if os(iOS)
import UIKit

public protocol CollectionViewDataSourceDelegate: AnyObject {
    associatedtype ObjectType
    func dataSource(_ dataSource: DataSourceProtocol, cellIdentifierFor object: ObjectType, at indexPath: IndexPath) -> String?
    func dataSource(_ dataSource: DataSourceProtocol, didSelect object: ObjectType, at indexPath: IndexPath)
    func dataSource(_ dataSource: DataSourceProtocol, didDeselect object: ObjectType, at indexPath: IndexPath?)
    func dataSourceDidScrollToLastElement(_ dataSource: DataSourceProtocol)
}

//MARK: Default implementation

public extension CollectionViewDataSourceDelegate {
    func dataSource(_ dataSource: DataSourceProtocol, cellIdentifierFor object: ObjectType, at indexPath: IndexPath) -> String? {
        return nil
    }
    func dataSource(_ dataSource: DataSourceProtocol, didSelect object: ObjectType, at indexPath: IndexPath) { }
    func dataSource(_ dataSource: DataSourceProtocol, didDeselect object: ObjectType, at indexPath: IndexPath?) { }
    func dataSourceDidScrollToLastElement(_ dataSource: DataSourceProtocol) { }
}

public class AnyCollectionViewDataSourceDelegate<T>: CollectionViewDataSourceDelegate {
    public required init<U: CollectionViewDataSourceDelegate>(_ delegate: U) where U.ObjectType == T {
        _dataSourceCellIdentifierForObjectAtIndexPath = { [weak delegate] in delegate?.dataSource($0, cellIdentifierFor: $1, at: $2) }
        _dataSourceDidSelectObjectAtIndexPath = { [weak delegate] in delegate?.dataSource($0, didSelect: $1, at: $2) }
        _dataSourceDidDeselectObjectAtIndexPath = { [weak delegate] in delegate?.dataSource($0, didDeselect: $1, at: $2) }
        _dataSourceDidScrollToLastElement = { [weak delegate] in delegate?.dataSourceDidScrollToLastElement($0)}
    }

    private let _dataSourceCellIdentifierForObjectAtIndexPath: (DataSourceProtocol, T, IndexPath) -> String?
    private let _dataSourceDidSelectObjectAtIndexPath: (DataSourceProtocol, T, IndexPath) -> Void
    private let _dataSourceDidDeselectObjectAtIndexPath: (DataSourceProtocol, T, IndexPath?) -> Void
    private let _dataSourceDidScrollToLastElement: (DataSourceProtocol) -> Void

    public func dataSource(_ dataSource: DataSourceProtocol, cellIdentifierFor object: T, at indexPath: IndexPath) -> String? {
        return _dataSourceCellIdentifierForObjectAtIndexPath(dataSource, object, indexPath)
    }
    
    public func dataSource(_ dataSource: DataSourceProtocol, didSelect object: T, at indexPath: IndexPath) {
        return _dataSourceDidSelectObjectAtIndexPath(dataSource, object, indexPath)
    }

    public func dataSource(_ dataSource: DataSourceProtocol, didDeselect object: T, at indexPath: IndexPath?) {
        return _dataSourceDidDeselectObjectAtIndexPath(dataSource, object, indexPath)
    }
    
    public func dataSourceDidScrollToLastElement(_ dataSource: DataSourceProtocol) {
        return _dataSourceDidScrollToLastElement(dataSource)
    }

}
#endif
