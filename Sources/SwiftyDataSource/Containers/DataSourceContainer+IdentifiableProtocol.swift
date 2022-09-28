//
//  DataSourceContainer+IdentifiableProtocol.swift
//  SwiftyDataSource
//
//  Created by Alexey Bakhtin on 2020-07-27.
//  Copyright © 2020 EffectiveSoft. All rights reserved.
//

#if os(iOS)
import Foundation

public protocol IdentifiableProtocol: Matchable {
    var id: Int { get }
}

extension IdentifiableProtocol {
    static func ~= (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}

extension DataSourceContainer where ResultType: IdentifiableProtocol {
    public func indexPath(forIdentifiable object: ResultType) -> IndexPath?  {
        return search { (indexPath, objectInContainer) -> Bool in
            return object.id == objectInContainer.id
        }
    }

    public func objectsInContainer(forIdentifiable object: ResultType) -> [ResultType]  {
        var objects = [ResultType]()
        enumerate { _, objectInContainer in
            if object.id == objectInContainer.id {
                objects.append(objectInContainer)
            }
        }
        return objects
    }
}
#endif
