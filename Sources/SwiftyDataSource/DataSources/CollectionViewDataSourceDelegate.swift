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
    func dataSource(_ dataSource: DataSourceProtocol, setupCell cell: UICollectionViewCell, at indexPath: IndexPath)
    func dataSource(_ dataSource: DataSourceProtocol, cellIdentifierFor object: ObjectType, at indexPath: IndexPath) -> String?
    func dataSource(_ dataSource: DataSourceProtocol, didSelect object: ObjectType, at indexPath: IndexPath)
    func dataSource(_ dataSource: DataSourceProtocol, didDeselect object: ObjectType, at indexPath: IndexPath?)
    func dataSourceDidScrollToLastElement(_ dataSource: DataSourceProtocol)
}

//MARK: Default implementation

public extension CollectionViewDataSourceDelegate {
    func dataSource(_ dataSource: DataSourceProtocol, setupCell cell: UICollectionViewCell, at indexPath: IndexPath) { }
    func dataSource(_ dataSource: DataSourceProtocol, cellIdentifierFor object: ObjectType, at indexPath: IndexPath) -> String? { nil }
    func dataSource(_ dataSource: DataSourceProtocol, didSelect object: ObjectType, at indexPath: IndexPath) { }
    func dataSource(_ dataSource: DataSourceProtocol, didDeselect object: ObjectType, at indexPath: IndexPath?) { }
    func dataSourceDidScrollToLastElement(_ dataSource: DataSourceProtocol) { }
}

public class AnyCollectionViewDataSourceDelegate<T>: CollectionViewDataSourceDelegate {
    private let _dataSourceSetupCellAtIndexPath: (DataSourceProtocol, UICollectionViewCell, IndexPath) -> Void
    private let _dataSourceCellIdentifierForObjectAtIndexPath: (DataSourceProtocol, T, IndexPath) -> String?
    private let _dataSourceDidSelectObjectAtIndexPath: (DataSourceProtocol, T, IndexPath) -> Void
    private let _dataSourceDidDeselectObjectAtIndexPath: (DataSourceProtocol, T, IndexPath?) -> Void
    private let _dataSourceDidScrollToLastElement: (DataSourceProtocol) -> Void

    public required init<U: CollectionViewDataSourceDelegate>(_ delegate: U) where U.ObjectType == T {
        _dataSourceSetupCellAtIndexPath = { [weak delegate] in
            delegate?.dataSource($0, setupCell: $1, at: $2)
        }
        _dataSourceCellIdentifierForObjectAtIndexPath = { [weak delegate] in delegate?.dataSource($0, cellIdentifierFor: $1, at: $2)
        }
        _dataSourceDidSelectObjectAtIndexPath = { [weak delegate] in
            delegate?.dataSource($0, didSelect: $1, at: $2)
        }
        _dataSourceDidDeselectObjectAtIndexPath = { [weak delegate] in
            delegate?.dataSource($0, didDeselect: $1, at: $2)
        }
        _dataSourceDidScrollToLastElement = { [weak delegate] in delegate?.dataSourceDidScrollToLastElement($0)
        }
    }
    
    public func dataSource(_ dataSource: DataSourceProtocol, setupCell cell: UICollectionViewCell, at indexPath: IndexPath) {
        _dataSourceSetupCellAtIndexPath(dataSource, cell, indexPath)
    }

    public func dataSource(_ dataSource: DataSourceProtocol, cellIdentifierFor object: T, at indexPath: IndexPath) -> String? {
        _dataSourceCellIdentifierForObjectAtIndexPath(dataSource, object, indexPath)
    }
    
    public func dataSource(_ dataSource: DataSourceProtocol, didSelect object: T, at indexPath: IndexPath) {
        _dataSourceDidSelectObjectAtIndexPath(dataSource, object, indexPath)
    }

    public func dataSource(_ dataSource: DataSourceProtocol, didDeselect object: T, at indexPath: IndexPath?) {
        _dataSourceDidDeselectObjectAtIndexPath(dataSource, object, indexPath)
    }
    
    public func dataSourceDidScrollToLastElement(_ dataSource: DataSourceProtocol) {
        _dataSourceDidScrollToLastElement(dataSource)
    }

}
#endif
