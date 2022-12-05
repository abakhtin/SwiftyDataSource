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
    public func indexPathMatchableObject(_ sameObject: ResultType) -> IndexPath? {
        return search({ $1 ~= sameObject })
    }
    
    public func sectionIndexOfMatchableObject(_ object: ResultType) -> Int? {
        guard let existedObjectIndexPath = indexPathMatchableObject(object) else { return nil }
        return existedObjectIndexPath.section
    }
    
    public func replaceMatchableObject(_ existingObject: ResultType? = nil, with newObject: ResultType, replaceAfterReuse: Bool = false) throws {
        guard let existedObjectIndexPath = indexPathMatchableObject(existingObject ?? newObject) else { return }
        try replace(object: newObject, at: existedObjectIndexPath, replaceAfterReuse: replaceAfterReuse)
    }
    
    public func insertMatchableObject(_ object: ResultType, atObjectIndexPath existingObject: ResultType) throws {
        guard let existedObjectIndexPath = indexPathMatchableObject(existingObject) else { return }
        try insert(object: object, at: existedObjectIndexPath)
    }
    
    public func insertMatchableObjectsToEndOfSection(_ objects: [ResultType], someObjectInThisSection: ResultType) throws {
        guard let existedObjectSectionIndex = sectionIndexOfMatchableObject(someObjectInThisSection) else { return }
        try insert(objects: objects, toSectionAt: existedObjectSectionIndex)
    }
    
    public func deleteMatchableObject(_ sameObject: ResultType) throws {
        guard let existedObjectIndexPath = indexPathMatchableObject(sameObject) else { return }
        try remove(at: existedObjectIndexPath)
    }
    
    public func findMatchableObject(_ sameObject: ResultType) -> ResultType? {
        guard let existedObjectIndexPath = indexPathMatchableObject(sameObject) else { return nil }
        return object(at: existedObjectIndexPath)
    }
    
    public func findMatchableObjects(_ sameObjects: ResultType..., completion: ((ResultType, IndexPath) -> Void)?) {
        enumerate { indexPath, result in
            if sameObjects.contains(where: { $0 ~= result }) { completion?(result, indexPath) }
        }
    }
}
