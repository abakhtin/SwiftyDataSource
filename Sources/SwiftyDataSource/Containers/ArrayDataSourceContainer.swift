//
//  ArrayController.swift
//  DPDataStorage
//
//  Created by Aleksey Bakhtin on 12/20/17.
//  Copyright © 2018 launchOptions. All rights reserved.
//

#if os(iOS)
import UIKit

enum ArrayDataSourceContainerError: Error {
    case NonValidIndexPathInsertion
}

public class ArrayDataSourceContainer<ResultType>: DataSourceContainer<ResultType> {

    // MARK: Initializer
    
    required public init(objects: [ResultType]? = nil, named: String = "", delegate: DataSourceContainerDelegate? = nil) {
        super.init(delegate: delegate)
        if let objects = objects {
            try! insert(sectionObjects: objects, at: 0, named: named, indexTitle: nil)
        }
    }

    // MARK: DataSourceContainer implementing
    
    open override var sections: [DataSourceSectionInfo]? {
        return arraySections
    }
    
    open override var fetchedObjects: [ResultType]? {
        get {
            return arraySections.reduce(into: [], { (result, section) in result?.append(contentsOf: section.arrayObjects) })
        }
    }
    
    open override func object(at indexPath: IndexPath) -> ResultType? {
        return arraySections[indexPath.section][indexPath.row]
    }

    open override func search(_ block:(IndexPath, ResultType) -> Bool) -> IndexPath? {
        for (sectionIndex, section) in arraySections.enumerated() {
            for (rowIndex, object) in section.arrayObjects.enumerated() {
                let indexPath = IndexPath(row: rowIndex, section: sectionIndex)
                if block(indexPath, object) {
                    return indexPath
                }
            }
        }
        return nil
    }

    open override func enumerate(_ block:(IndexPath, ResultType) -> Void) {
        for (sectionIndex, section) in arraySections.enumerated() {
            for (rowIndex, object) in section.arrayObjects.enumerated() {
                block(IndexPath(row: rowIndex, section: sectionIndex), object)
            }
        }
    }

    open override func indexPath(for object: ResultType) -> IndexPath? {
        fatalError("Array data source does not suuport indexPath(for:). Use search method instead")
    }
    
    open override func numberOfSections() -> Int? {
        return arraySections.count
    }
    
    open override func numberOfItems(in section: Int) -> Int? {
        guard section < arraySections.count else {
            return 0
        }
        return arraySections[section].arrayObjects.count
    }

    // MARK: Array controller public interface

    public func insert(object: ResultType, at indexPath: IndexPath) throws {
        let arraySection = arraySections[safe: indexPath.section]
        guard indexPath.row <= arraySection?.arrayObjects.count ?? 0 else {
            throw ArrayDataSourceContainerError.NonValidIndexPathInsertion
        }
        guard let section = arraySection else {
            try insert(sectionObjects: [object], at: indexPath.section)
            return
        }
        
        section.insert(object: object, at: indexPath.row)
        delegate?.containerWillChangeContent(self)
        delegate?.container(self, didChange: object, at: nil, for: .insert, newIndexPath: indexPath)
        delegate?.containerDidChangeContent(self)
    }

    public func remove(at indexPath: IndexPath) throws {
        guard let arraySection = arraySections[safe: indexPath.section],
            indexPath.row <= arraySection.arrayObjects.count else {
            throw ArrayDataSourceContainerError.NonValidIndexPathInsertion
        }
        arraySection.remove(at: indexPath.row)
        delegate?.containerWillChangeContent(self)
        delegate?.container(self, didChange: object, at: indexPath, for: .delete, newIndexPath: nil)
        delegate?.containerDidChangeContent(self)
    }

    public func replace(object: ResultType, at indexPath: IndexPath, reloadAction: Bool = false) throws {
        let arraySection = arraySections[safe: indexPath.section]
        guard let section = arraySection else {
            try insert(sectionObjects: [object], at: indexPath.section)
            return
        }
        guard indexPath.row < section.arrayObjects.count else {
            try insert(object: object, at: indexPath)
            return
        }
        guard indexPath.row <= section.arrayObjects.count else {
            throw ArrayDataSourceContainerError.NonValidIndexPathInsertion
        }

        section.replace(object: object, at: indexPath.row)
        
        delegate?.container(self, didChange: object, at: indexPath, for: reloadAction ? .reload : .update, newIndexPath: indexPath)
    }

    public func replace(sectionObjects: [ResultType], at sectionIndex: Int, named name: String = "", indexTitle: String? = nil) throws {
        guard sectionIndex <= self.arraySections.count else {
            throw ArrayDataSourceContainerError.NonValidIndexPathInsertion
        }
        let section = Section(objects: sectionObjects, name: name, indexTitle: indexTitle)
        if sectionIndex == self.arraySections.count {
            self.arraySections.insert(section, at: sectionIndex)
            delegate?.container(self, didChange: section, atSectionIndex: sectionIndex, for: .insert)
        } else {
            self.arraySections[sectionIndex] = section
            delegate?.container(self, didChange: section, atSectionIndex: sectionIndex, for: .update)
        }
    }

    // MARK: Method allows to add objects to new section. If newSectionIndex is nil, add to the end.
    public func insert(sectionObjects: [ResultType], at newSectionIndex: Int? = nil, named name: String = "", indexTitle: String? = nil) throws {
        if let sectionIndex = newSectionIndex, sectionIndex > self.arraySections.count {
            throw ArrayDataSourceContainerError.NonValidIndexPathInsertion
        }
        let sectionIndex = newSectionIndex ?? self.arraySections.count
        let section = Section(objects: sectionObjects, name: name, indexTitle: indexTitle)
        self.arraySections.insert(section, at: sectionIndex)
        
        delegate?.containerWillChangeContent(self)
        delegate?.container(self, didChange: section, atSectionIndex: sectionIndex, for: .insert)
        delegate?.containerDidChangeContent(self)
    }

    // MARK: Method allows to add objects to the end of concrete section or create new if it does not exist
    public func insert(objects: [ResultType], toSectionAt sectionIndex: Int, named name: String = "", indexTitle: String? = nil) throws {
        let arraySection = arraySections[safe: sectionIndex]
        guard let section = arraySection else {
            try insert(sectionObjects: objects, at: sectionIndex, named: name, indexTitle: indexTitle)
            return
        }
        
        delegate?.containerWillChangeContent(self)
        objects.forEach { object in
            let rowIndex = section.numberOfObjects
            section.insert(object: object, at: rowIndex)
            delegate?.container(self, didChange: object, at: nil, for: .insert, newIndexPath: IndexPath(row: rowIndex, section: sectionIndex))
        }
        delegate?.containerDidChangeContent(self)
    }
   
    public func removeAll() {
        let backUpArraySections = arraySections
        arraySections.removeAll()
        delegate?.containerWillChangeContent(self)
        for i in 0 ..< backUpArraySections.count {
            delegate?.container(self, didChange: backUpArraySections[i], atSectionIndex: i, for: .delete)
        }
        delegate?.containerDidChangeContent(self)
    }
    
    public func removeSection(at sectionIndex: Int) throws {
        guard sectionIndex < arraySections.count else {
            throw ArrayDataSourceContainerError.NonValidIndexPathInsertion
        }
        let backUpArraySections = arraySections
        arraySections.remove(at: sectionIndex)
        delegate?.containerWillChangeContent(self)
        delegate?.container(self, didChange: backUpArraySections[sectionIndex], atSectionIndex: sectionIndex, for: .delete)
        delegate?.containerDidChangeContent(self)
    }
    
    // MARK: Storage implementing
    
    var arraySections = [Section<ResultType>]()

    // MARK: Array section class
    
    class Section<ResultType>: DataSourceSectionInfo {
        
        // MARK: Initializing
        
        init(objects: [ResultType], name: String, indexTitle: String?) {
            self.arrayObjects = objects
            self.name = name
            self.indexTitle = indexTitle
        }
        
        // MARK: Storage
        
        private(set) var arrayObjects: [ResultType]
        
        // MARK: DataSourceSectionInfo implementing
        
        public var name: String
        
        public var indexTitle: String?
        
        var numberOfObjects: Int {
            guard let objects = objects else { return 0 }
            return objects.count
        }
        
        public var objects: [Any]? {
            return arrayObjects
        }
        
        // MARK: Public interface
        
        func insert(object: ResultType, at index: Int) {
            self.arrayObjects.insert(object, at: index)
        }

        func remove(at index: Int) {
            self.arrayObjects.remove(at: index)
        }

        func replace(object: ResultType, at index: Int) {
            self.arrayObjects[index] = object
        }

        // MARK: Subscription
        
        subscript(index: Int) -> ResultType? {
            get {
                return arrayObjects[index]
            }
            set(newValue) {
                if let newValue = newValue {
                    arrayObjects[index] = newValue
                }
            }
        }
    }
}
#endif
