//
//  HashableDataSourceContainer.swift
//  SwiftyDataSource
//
//  Created by Yauheni Fiadotau on 13.05.23.
//  Copyright © 2023 EffectiveSoft. All rights reserved.
//

import Foundation

public class HashableDataSourceContainer<ObjectType: Hashable>: DataSourceContainer<ObjectType> {
    
    private var _sections: [Section<ObjectType>] = []
    private var sectionsSet: Set<Section<ObjectType>> { Set(_sections) }
    
    public override var sections: [DataSourceSectionInfo]? { _sections }
    public override var fetchedObjects: [ObjectType]? { _sections.flatMap { $0._objects } }
    
    public init(_ sections: [SectionRepresentable<ObjectType>] = []) {
        super.init()
        if !sections.isEmpty { appendSections(sections) }
    }

    public override func object(at indexPath: IndexPath) -> ObjectType? {
        _sections[safe: indexPath.section]?._objects[safe: indexPath.row]
    }
    
    public override func indexPath(for object: ObjectType) -> IndexPath? {
        if let sectionWithObject = section(containingObject: object), let sectionIndex = _sections.enumerated().first(where: { $0.element == sectionWithObject })?.offset, let objectIndex = sectionWithObject._objects.enumerated().first(where: { $0.element == object })?.offset {
            return IndexPath(row: objectIndex, section: sectionIndex)
        } else {
            return nil
        }
    }
    
    public override func search(_ block: (IndexPath, ObjectType) -> Bool) -> IndexPath? {
        var resultIndexPath: IndexPath?
        _sections.enumerated().forEach { sectionIndex, section in
            section._objects.enumerated().forEach { objectIndex, object in
                let indexPath = IndexPath(row: objectIndex, section: sectionIndex)
                if block(indexPath, object) {
                    return resultIndexPath = indexPath
                }
            }
            if resultIndexPath != nil { return }
        }
        return nil
    }

    public override func enumerate(_ block: (IndexPath, ObjectType) -> Void) {
        _sections.enumerated().forEach { sectionIndex, section in
            section._objects.enumerated().forEach { objectIndex, object in
                block(IndexPath(row: objectIndex, section: sectionIndex), object)
            }
        }
    }
    
    public override func numberOfSections() -> Int? { _sections.count }
    
    public override func numberOfItems(in section: Int) -> Int? { _sections[safe: section]?.numberOfObjects }

    public func objects(atSection sectionIndex: Int) -> [ObjectType] {
        _sections[safe: sectionIndex]?._objects ?? []
    }

    public func section(containingObject object: ObjectType) -> Section<ObjectType>? {
        _sections.first { $0.contains(object: object) }
    }

    public func indexOfObject(_ object: ObjectType) -> Int? {
        indexPath(for: object)?.row
    }

    public func appendObjects(_ objects: [ObjectType], to section: Section<ObjectType>?) {
        if let section {
            let objectsToAppend = getOnlyNewObjects(objects)
            if !objectsToAppend.isEmpty {
                section.append(objectsToAppend)
                delegate?.containerWillChangeContent(self)
                objectsToAppend.compactMap { ($0, indexPath(for: $0)) }.forEach { object, indexPath in
                    delegate?.container(self, didChange: object, at: nil, for: .insert, newIndexPath: indexPath)
                }
                delegate?.containerDidChangeContent(self)
            }
        }
    }

    public func insertObjects(_ objects: [ObjectType], beforeObject: ObjectType) {
        if let section = section(containingObject: beforeObject) {
            let objectsToInsert = getOnlyNewObjects(objects)
            if !objectsToInsert.isEmpty {
                section.insertObjects(objects, beforeObject: beforeObject)
                delegate?.containerWillChangeContent(self)
                objectsToInsert.compactMap { ($0, indexPath(for: $0)) }.forEach { object, indexPath in
                    delegate?.container(self, didChange: object, at: nil, for: .insert, newIndexPath: indexPath)
                }
                delegate?.containerDidChangeContent(self)
            }
        }
    }

    public func insertObjects(_ objects: [ObjectType], afterObject: ObjectType) {
        if let section = section(containingObject: afterObject) {
            let objectsToInsert = getOnlyNewObjects(objects)
            if !objectsToInsert.isEmpty {
                section.insertObjects(objects, afterObject: afterObject)
                delegate?.containerWillChangeContent(self)
                objectsToInsert.compactMap { ($0, indexPath(for: $0)) }.forEach { object, indexPath in
                    delegate?.container(self, didChange: object, at: nil, for: .insert, newIndexPath: indexPath)
                }
                delegate?.containerDidChangeContent(self)
            }
        }
    }

    public func deleteObject(_ objects: [ObjectType]) {
        let objectsToDelete = objects.map { ($0, section(containingObject: $0)) }.filter { $0.1 != nil }
        if !objectsToDelete.isEmpty {
            delegate?.containerWillChangeContent(self)
            objectsToDelete.forEach { object, section in
                let indexPath = indexPath(for: object)
                section?.deleteObjects([object])
                delegate?.container(self, didChange: object, at: indexPath, for: .delete, newIndexPath: nil)
            }
            delegate?.containerWillChangeContent(self)
        }
    }

    public func deleteAllObjects() {
        if !_sections.isEmpty {
            let sections = _sections
            _sections = []
            delegate?.containerWillChangeContent(self)
            sections.enumerated().forEach { index, section in
                delegate?.container(self, didChange: section, atSectionIndex: index, for: .delete)
            }
            delegate?.containerDidChangeContent(self)
        }
    }

    public func moveObject(_ object: ObjectType, beforeObject: ObjectType) {
        if let sectionOfObject = section(containingObject: object), let sectionOfBeforeItem = section(containingObject: beforeObject) {
            let oldIndexPath = indexPath(for: object)
            let newIndexPath = indexPath(for: beforeObject)
            if oldIndexPath != newIndexPath {
                if sectionOfObject == sectionOfBeforeItem {
                    sectionOfObject.moveObject(object, beforeObject: beforeObject)
                } else {
                    sectionOfObject.deleteObjects([object])
                    sectionOfBeforeItem.insertObjects([object], beforeObject: beforeObject)
                }
                delegate?.containerWillChangeContent(self)
                delegate?.container(self, didChange: object, at: oldIndexPath, for: .move, newIndexPath: newIndexPath)
                delegate?.containerWillChangeContent(self)
            }
        }
    }

    public func moveObject(_ object: ObjectType, afterObject: ObjectType) {
        if let sectionOfObject = section(containingObject: object), let sectionOfAfterItem = section(containingObject: afterObject) {
            let oldIndexPath = indexPath(for: object)
            let newIndexPath = indexPath(for: afterObject).map { IndexPath(row: $0.row + 1, section: $0.section) }
            if oldIndexPath != newIndexPath {
                if sectionOfObject == sectionOfAfterItem {
                    sectionOfObject.moveObject(object, afterObject: afterObject)
                } else {
                    sectionOfObject.deleteObjects([object])
                    sectionOfAfterItem.insertObjects([object], afterObject: afterObject)
                    
                }
                delegate?.containerWillChangeContent(self)
                delegate?.container(self, didChange: object, at: oldIndexPath, for: .move, newIndexPath: newIndexPath)
                delegate?.containerDidChangeContent(self)
            }
        }
        
    }

    public func reloadObjects(_ objects: [ObjectType]) {
        let existingObjects = Set(objects).intersection(Set(fetchedObjects ?? []))
        if !existingObjects.isEmpty {
            delegate?.containerWillChangeContent(self)
            existingObjects.forEach { object in
                delegate?.container(self, didChange: object, at: indexPath(for: object), for: .reload, newIndexPath: nil)
            }
            delegate?.containerDidChangeContent(self)
        }
    }

    public func reconfigureObjects(_ objects: [ObjectType]) {
        let existingObjects = Set(objects).intersection(Set(fetchedObjects ?? []))
        if !existingObjects.isEmpty {
            delegate?.containerWillChangeContent(self)
            existingObjects.forEach { object in
                delegate?.container(self, didChange: object, at: indexPath(for: object), for: .update, newIndexPath: nil)
            }
            delegate?.containerDidChangeContent(self)
        }
    }

    public func appendSections(_ sections: [SectionRepresentable<ObjectType>]) {
        let sectionsWithNewObjects = getSectionsWithNewObjects(from: sections)
        if !sectionsWithNewObjects.isEmpty {
            _sections.append(contentsOf: sectionsWithNewObjects)
            delegate?.containerWillChangeContent(self)
            _sections.enumerated().filter { sectionsWithNewObjects.contains($0.element) }.forEach { sectionIndex, section in
                delegate?.container(self, didChange: section, atSectionIndex: sectionIndex, for: .insert)
            }
            delegate?.containerDidChangeContent(self)
        }
    }

    public func insertSections(_ sections: [SectionRepresentable<ObjectType>], beforeSection: Section<ObjectType>) {
        let sectionsWithNewObjects = getSectionsWithNewObjects(from: sections)
        if !sectionsWithNewObjects.isEmpty {
            if let beforeSectionIndex = _sections.firstIndex(of: beforeSection) {
                _sections.insert(contentsOf: sectionsWithNewObjects, at: beforeSectionIndex)
                delegate?.containerWillChangeContent(self)
                _sections.enumerated().filter { sectionsWithNewObjects.contains($0.element) }.forEach { sectionIndex, section in
                    delegate?.container(self, didChange: section, atSectionIndex: sectionIndex, for: .insert)
                }
                delegate?.containerDidChangeContent(self)
            }
        }
    }

    public func insertSections(_ sections: [SectionRepresentable<ObjectType>], afterSection: Section<ObjectType>) {
        let sectionsWithNewObjects = getSectionsWithNewObjects(from: sections)
        if !sectionsWithNewObjects.isEmpty {
            if let afterSectionIndex = _sections.firstIndex(of: afterSection) {
                _sections.insert(contentsOf: sectionsWithNewObjects, at: afterSectionIndex + 1)
                delegate?.containerWillChangeContent(self)
                _sections.enumerated().filter { sectionsWithNewObjects.contains($0.element) }.forEach { sectionIndex, section in
                    delegate?.container(self, didChange: section, atSectionIndex: sectionIndex, for: .insert)
                }
                delegate?.containerDidChangeContent(self)
            }
        }
    }

    public func deleteSections(_ sections: [Section<ObjectType>]) {
        let existingSections = Set(sections).intersection(sectionsSet)
        if !existingSections.isEmpty {
            delegate?.containerWillChangeContent(self)
            sections.forEach { section in
                let sectionIndex = _sections.firstIndex(of: section)
                _sections.removeAll { $0 == section }
                if let sectionIndex {
                    delegate?.container(self, didChange: section, atSectionIndex: sectionIndex, for: .delete)
                }
            }
            delegate?.containerDidChangeContent(self)
        }
    }

    public func moveSection(_ section: Section<ObjectType>, beforeSection: Section<ObjectType>) {
        if let sectionIndex = _sections.firstIndex(of: section), let beforeSectionIndex = _sections.firstIndex(of: beforeSection) {
            _sections.remove(at: sectionIndex)
            _sections.insert(section, at: beforeSectionIndex)
            
            delegate?.containerWillChangeContent(self)
            delegate?.container(self, didChange: section, atSectionIndex: sectionIndex, for: .move)
            delegate?.containerDidChangeContent(self)
        
        }
    }

    public func moveSection(_ section: Section<ObjectType>, afterSection: Section<ObjectType>) {
        if let sectionIndex = _sections.firstIndex(of: section), let afterSectionIndex = _sections.firstIndex(of: afterSection) {
            _sections.remove(at: sectionIndex)
            _sections.insert(section, at: afterSectionIndex + 1)
            
            delegate?.containerWillChangeContent(self)
            delegate?.container(self, didChange: section, atSectionIndex: sectionIndex, for: .move)
            delegate?.containerDidChangeContent(self)
        }
    }

    public func reloadSections(_ sections: [Section<ObjectType>]) {
        let existingSections = Set(sections).intersection(sectionsSet)
        if !existingSections.isEmpty {
            delegate?.containerWillChangeContent(self)
            sections.forEach { section in
                if let sectionIndex = _sections.firstIndex(of: section) {
                    delegate?.container(self, didChange: section, atSectionIndex: sectionIndex, for: .reload)
                }
            }
            delegate?.containerDidChangeContent(self)
        }
    }
    
    private func getOnlyNewObjects(_ objects: [ObjectType]) -> [ObjectType] {
        let newObjects = Set(objects).subtracting(Set(fetchedObjects ?? []))
        return objects.filter { newObjects.contains($0) }
    }
    
    private func getSectionsWithNewObjects(from sections: [SectionRepresentable<ObjectType>]) -> [Section<ObjectType>] {
        sections.reduce(into: [Section<ObjectType>]()) { result, nextValue in
            var nextValue = nextValue
            nextValue.objects = nextValue.objects.filter { !Set(fetchedObjects ?? []).contains($0) }
            if !nextValue.objects.isEmpty {
                result.append(nextValue.toSection())
            }
        }
    }
    
    public class Section<ObjectType: Hashable>: Hashable, DataSourceSectionInfo {
        public private(set) var sender: Any?
        public private(set) var name: String
        public private(set) var indexTitle: String?
        public var numberOfObjects: Int { _objects.count }
        public var objects: [Any]? { _objects }
        
        fileprivate var _objects: [ObjectType] = []
        fileprivate var objectsSet: Set<ObjectType> { Set(_objects) }
        
        init(sender: Any? = nil, name: String = .init(), indexTitle: String? = nil, objects: [ObjectType] = []) {
            self.sender = sender
            self.name = name
            self.indexTitle = indexTitle
            self._objects = objects
        }
        
        fileprivate func contains(object: ObjectType) -> Bool {
            objectsSet.contains(object)
        }
        
        fileprivate func append(_ objects: [ObjectType]) {
            _objects.append(contentsOf: objects)
        }
        
        fileprivate func insertObjects(_ objects: [ObjectType], beforeObject: ObjectType) {
            if let beforeObjectIndex = _objects.firstIndex(of: beforeObject) {
                _objects.insert(contentsOf: objects, at: beforeObjectIndex)
            }
        }
        
        fileprivate func insertObjects(_ objects: [ObjectType], afterObject: ObjectType) {
            if let afterObjectIndex = _objects.firstIndex(of: afterObject) {
                _objects.insert(contentsOf: objects, at: afterObjectIndex + 1)
            }
        }
        
        fileprivate func deleteObjects(_ objects: [ObjectType]) {
            _objects.removeAll { objects.contains($0) }
        }
        
        fileprivate func moveObject(_ object: ObjectType, beforeObject: ObjectType) {
            if let beforeObjectIndex = _objects.firstIndex(of: beforeObject) {
                _objects.removeAll { $0 == object }
                _objects.insert(object, at: beforeObjectIndex)
            }
        }
        
        fileprivate func moveObject(_ object: ObjectType, afterObject: ObjectType) {
            if let afterObjectIndex = _objects.firstIndex(of: afterObject) {
                _objects.removeAll { $0 == object }
                _objects.insert(object, at: afterObjectIndex + 1)
            }
        }
        
        public static func == (lhs: Section<ObjectType>, rhs: Section<ObjectType>) -> Bool {
            lhs.hashValue == rhs.hashValue
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(_objects)
            hasher.combine(name)
            hasher.combine(indexTitle)
        }
    }
    
    public struct SectionRepresentable<ObjectType: Hashable> {
        public var sender: Any? = nil
        public var name: String = .init()
        public var indexTitle: String? = nil
        public var objects: [ObjectType] = []
        
        public init(sender: Any? = nil, name: String = .init(), indexTitle: String? = nil, objects: [ObjectType]) {
            self.sender = sender
            self.name = name
            self.indexTitle = indexTitle
            self.objects = objects
        }
        
        fileprivate func toSection() -> Section<ObjectType> {
            .init(sender: sender, name: name, indexTitle: indexTitle, objects: objects)
        }
    }
}
