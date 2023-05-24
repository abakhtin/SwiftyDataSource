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

public protocol DataSourceExpandable: AnyObject {
    var isExpanded: Bool { get set }
    func setExpanded(value: Bool)
}

public extension DataSourceExpandable {
    func setExpanded(value: Bool) {
        isExpanded = value
    }
}
#endif
