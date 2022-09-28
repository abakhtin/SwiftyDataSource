//
//  DataSourceContainer+Matchable.swift
//  SwiftyDataSource
//
//  Created by Yauheni Fiadotau on 28.09.22.
//  Copyright © 2022 EffectiveSoft. All rights reserved.
//

import Foundation

public protocol Matchable {
    static func ~= (lhs: Self, rhs: Self) -> Bool
}

extension ArrayDataSourceContainer where ResultType: Matchable {
    public func replaceMatchableObject(with newObject: ResultType) throws {
        guard let existedObjectIndexPath = search({ $1 ~= newObject }) else { return }
        try replace(object: newObject, at: existedObjectIndexPath)
    }
}
