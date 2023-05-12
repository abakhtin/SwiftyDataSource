//
//  MapViewDataSourceDelegate.swift
//  launchOptions
//
//  Created by Aleksey Bakhtin on 12/20/17.
//  Copyright © 2018 launchOptions. All rights reserved.
//

#if os(iOS)
import UIKit

// MARK: DataSource for customizing default behaviour of dataSource

public protocol MapViewDataSourceDelegate: AnyObject {
    associatedtype ObjectType
    func dataSource(_ dataSource: DataSourceProtocol, didSelect object: ObjectType)
}

// MARK: Default implementation as all of methods are optional

public extension MapViewDataSourceDelegate {
    func dataSource(_ dataSource: DataSourceProtocol, didSelect object: ObjectType) { }
}


// MARK: Type erasure for protocol with associated type. So we can use protocol for initializing

public class AnyMapViewDataSourceDelegate<T>: MapViewDataSourceDelegate {
    public required init<U: MapViewDataSourceDelegate>(_ delegate: U) where U.ObjectType == T {
        _dataSourceDidSelectObject = delegate.dataSource
    }

    private let _dataSourceDidSelectObject: (DataSourceProtocol, T) -> Void
    
    public func dataSource(_ dataSource: DataSourceProtocol, didSelect object: T) {
        return _dataSourceDidSelectObject(dataSource, object)
    }
}
#endif
