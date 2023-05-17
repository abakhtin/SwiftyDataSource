//
//  HashableDataSourceContainer.swift
//  SwiftyDataSource
//
//  Created by Yauheni Fiadotau on 13.05.23.
//  Copyright © 2023 EffectiveSoft. All rights reserved.
//

import Foundation

public class HashableDataSourceContainer<ObjectType: Hashable>: DataSourceContainer<ObjectType> {
    private lazy var operationsPipe = DataSourceContainerOperationsQueue()
   
    private var _sections: [Section] = []
    private var sectionsSet: Set<Section> { Set(_sections) }
    private var fetchedObjectsSet: Set<ObjectType> { Set(fetchedObjects ?? []) }
    
    public override var sections: [DataSourceSectionInfo]? { _sections }
    public override var fetchedObjects: [ObjectType]? { _sections.flatMap { $0._objects } }
    
    public func performAfterUpdates(_ block: @escaping (_ container: HashableDataSourceContainer<ObjectType>) -> Void) {
        operationsPipe.executeOperation {
            block(self)
        }
    }
    
    public init(_ sections: [Section] = []) {
        super.init()
        if !sections.isEmpty { appendSections(sections) }
    }
    
    public override func object(at indexPath: IndexPath) -> ObjectType? {
        _sections[safe: indexPath.section]?._objects[safe: indexPath.row]
    }
    
    public override func indexPath(for object: ObjectType) -> IndexPath? {
        if let sectionWithObject = section(containingObject: object),
           let sectionIndex = indexOfSection(sectionWithObject),
           let objectIndex = sectionWithObject.indexOfObject(object) {
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
        return resultIndexPath
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
    
    public func objects(atSectionIndex sectionIndex: Int) -> [ObjectType] {
        _sections[safe: sectionIndex]?._objects ?? []
    }
    
    public func objects(atSection section: Section) -> [ObjectType] {
        section._objects
    }
    
    public func objects(atSectionContaining object: ObjectType) -> [ObjectType] {
        section(containingObject: object)?._objects ?? []
    }
    
    public func section(containingObject object: ObjectType) -> Section? {
        _sections.first { $0.contains(object: object) }
    }
    
    public func firstObject(inSection section: Section?) -> ObjectType? {
        section?._objects.first
    }
    
    public func lastObject(inSection section: Section?) -> ObjectType? {
        section?._objects.last
    }
    
    public func contains(_ object: ObjectType) -> Bool {
        fetchedObjectsSet.contains(object)
    }
    
    public func indexOfObject(_ object: ObjectType) -> Int? {
        indexPath(for: object)?.row
    }
    
    public func indexOfSection(_ section: Section) -> Int? {
        _sections.firstIndex(of: section)
    }
    
    public func appendObjects(_ objects: [ObjectType], to section: Section?) {
        var objectsCountBeforeUpdate: Int?
        var objectsToAppend = [ObjectType]()
        
        performContainerUpdate {
            guard let section else { return }
            objectsToAppend = self.filterExistingObjects(objects)
            guard !objectsToAppend.isEmpty else { return }
            objectsCountBeforeUpdate = section.numberOfObjects
            section.append(objectsToAppend)
        } delegateUpdate: {
            guard let objectsCountBeforeUpdate, let section, let sectionIndex = self.indexOfSection(section) else { return }
            objectsToAppend.enumerated().forEach { index, object in
                self.delegate?.container(self, didChange: object, at: nil, for: .insert, newIndexPath: IndexPath(row: objectsCountBeforeUpdate == .zero ? index : objectsCountBeforeUpdate + index, section: sectionIndex))
            }
        }
    }
    
    public func insertObjects(_ objects: [ObjectType], beforeObject: ObjectType) {
        var section: Section?
        var beforeObjectIndex: Int?
        var objectsToInsert = [ObjectType]()
        
        performContainerUpdate {
            guard let findedSection = self.section(containingObject: beforeObject) else { return }
            objectsToInsert = self.filterExistingObjects(objects)
            guard !objectsToInsert.isEmpty else { return }
            section = findedSection
            beforeObjectIndex = findedSection.indexOfObject(beforeObject)
            findedSection.insertObjects(objectsToInsert, beforeObject: beforeObject)
        } delegateUpdate: {
            guard let section, let beforeObjectIndex, let sectionIndex = self.indexOfSection(section) else { return }
            objectsToInsert.enumerated().forEach { index, object in
                self.delegate?.container(self, didChange: object, at: nil, for: .insert, newIndexPath: IndexPath(row: beforeObjectIndex + index, section: sectionIndex))
            }
        }
    }
    
    public func insertObjects(_ objects: [ObjectType], afterObject: ObjectType) {
        var section: Section?
        var afterObjectIndex: Int?
        var objectsToInsert = [ObjectType]()
        
        performContainerUpdate {
            guard let findedSection = self.section(containingObject: afterObject) else { return }
            objectsToInsert = self.filterExistingObjects(objects)
            guard !objectsToInsert.isEmpty else { return }
            section = findedSection
            afterObjectIndex = findedSection.indexOfObject(afterObject)
            findedSection.insertObjects(objectsToInsert, afterObject: afterObject)
        } delegateUpdate: {
            guard let section, let afterObjectIndex, let sectionIndex = self.indexOfSection(section) else { return }
            objectsToInsert.enumerated().forEach { index, object in
                self.delegate?.container(self, didChange: object, at: nil, for: .insert, newIndexPath: IndexPath(row: afterObjectIndex + index + 1, section: sectionIndex))
            }
        }
    }
    
    public func deleteObjects(_ objects: [ObjectType]) {
        var indexesOfDeletedObjects = [Int: [(object: ObjectType, index: Int)]]()
        var sectionsForDelete = [Int: Section]()
        
        performContainerUpdate {
            let objectsToDeleteDictionary = objects.uniqued().reduce(into: [Section: [ObjectType]]()) { result, object in
                if let section = self.section(containingObject: object) {
                    result[section, default: []].append(object)
                }
            }
            
            objectsToDeleteDictionary.forEach { section, objects in
                if let sectionIndex = self.indexOfSection(section) {
                    let objectsAndIndexes = objects.compactMap { object -> (object: ObjectType, index: Int)? in
                        guard let objectIndex = section.indexOfObject(object) else { return nil }
                        return (object, objectIndex)
                    }
                    section.deleteObjects(objectsAndIndexes.map { $0.object })
                    indexesOfDeletedObjects[sectionIndex] = objectsAndIndexes
                    if section.numberOfObjects == .zero {
                        sectionsForDelete[sectionIndex] = section
                    }
                }
            }
            self._sections.removeAll() { sectionsForDelete.values.contains($0) }
        } delegateUpdate: {
            indexesOfDeletedObjects.sorted { $0.key > $1.key }.forEach { sectionIndex, enumeratedObjects in
                enumeratedObjects.sorted { $0.index > $1.index }.forEach { enumeratedObject in
                    self.delegate?.container(
                        self,
                        didChange: enumeratedObject.object,
                        at: IndexPath(row: enumeratedObject.index, section: sectionIndex),
                        for: .delete,
                        newIndexPath: nil)
                }
            }
            sectionsForDelete.sorted { $0.key > $1.key }.forEach { sectionIndex, section in
                self.delegate?.container(self, didChange: section, atSectionIndex: sectionIndex, for: .delete)
            }
        }
    }
    
    public func deleteAllObjects() {
        var sections = [Section]()
        performContainerUpdate {
            sections = self._sections
            self._sections = []
        } delegateUpdate: {
            sections.enumerated().forEach { index, section in
                self.delegate?.container(self, didChange: section, atSectionIndex: index, for: .delete)
            }
        }
    }
    
    public func moveObject(_ object: ObjectType, beforeObject: ObjectType) {
        var oldIndexPath: IndexPath?
        var newIndexPath: IndexPath?
        
        performContainerUpdate {
            if let sectionOfObject = self.section(containingObject: object),
               let sectionIndex = self.indexOfSection(sectionOfObject),
               let indexOfObject = sectionOfObject.indexOfObject(object),
               let sectionOfBeforeObject = self.section(containingObject: beforeObject),
               let sectionIndexOfBeforeObject = self.indexOfSection(sectionOfBeforeObject),
               let indexOfBeforeObject = sectionOfObject.indexOfObject(beforeObject) {
                oldIndexPath = IndexPath(row: indexOfObject, section: sectionIndex)
                newIndexPath = IndexPath(row: indexOfBeforeObject, section: sectionIndexOfBeforeObject)
                guard oldIndexPath != newIndexPath else { return }
                if sectionOfObject == sectionOfBeforeObject {
                    sectionOfObject.moveObject(object, beforeObject: beforeObject)
                } else {
                    sectionOfObject.deleteObjects([object])
                    sectionOfBeforeObject.insertObjects([object], beforeObject: beforeObject)
                }
            }
        } delegateUpdate: {
            guard let oldIndexPath, let newIndexPath, oldIndexPath != newIndexPath else { return }
            self.delegate?.container(self, didChange: object, at: oldIndexPath, for: .move, newIndexPath: newIndexPath)
        }
    }
    
    public func moveObject(_ object: ObjectType, afterObject: ObjectType) {
        var oldIndexPath: IndexPath?
        var newIndexPath: IndexPath?
        
        performContainerUpdate {
            if let sectionOfObject = self.section(containingObject: object),
               let sectionIndex = self.indexOfSection(sectionOfObject),
               let indexOfObject = sectionOfObject.indexOfObject(object),
               let sectionOfAfterObject = self.section(containingObject: afterObject),
               let sectionIndexOfAfterObject = self.indexOfSection(sectionOfAfterObject),
               let indexOfAfterItem = sectionOfObject.indexOfObject(afterObject) {
                oldIndexPath = IndexPath(row: indexOfObject, section: sectionIndex)
                newIndexPath = IndexPath(row: indexOfAfterItem + 1, section: sectionIndexOfAfterObject)
                guard oldIndexPath != newIndexPath else { return }
                if sectionOfObject == sectionOfAfterObject {
                    sectionOfObject.moveObject(object, afterObject: afterObject)
                } else {
                    sectionOfObject.deleteObjects([object])
                    sectionOfAfterObject.insertObjects([object], afterObject: afterObject)
                    
                }
            }
        } delegateUpdate: {
            guard let oldIndexPath, let newIndexPath, oldIndexPath != newIndexPath else { return }
            self.delegate?.container(self, didChange: object, at: oldIndexPath, for: .move, newIndexPath: newIndexPath)
        }
    }
    
    public func replaceObject(_ object: ObjectType, with newObject: ObjectType) {
        var indexPath: IndexPath?
        
        performContainerUpdate {
            if let sectionWithObject = self.section(containingObject: object),
               let sectionIndex = self.indexOfSection(sectionWithObject),
               let objectIndex = sectionWithObject.indexOfObject(object) {
                sectionWithObject.replaceObject(object, with: newObject)
                indexPath = IndexPath(row: objectIndex, section: sectionIndex)
            }
        } delegateUpdate: {
            guard let indexPath else { return }
            self.delegate?.container(self, didChange: object, at: indexPath, for: .delete, newIndexPath: nil)
            self.delegate?.container(self, didChange: newObject, at: indexPath, for: .insert, newIndexPath: indexPath)
        }
    }
    
    public func reloadObjects(_ objects: [ObjectType]) {
        var existingObjects = Set<ObjectType>()
        
        performContainerUpdate {
            existingObjects = Set(objects).intersection(self.fetchedObjectsSet)
        } delegateUpdate: {
            existingObjects.forEach { object in
                self.delegate?.container(self, didChange: object, at: self.indexPath(for: object), for: .reload, newIndexPath: nil)
            }
        }
    }
    
    public func reconfigureObjects(_ objects: [ObjectType]) {
        var existingObjects = Set<ObjectType>()
        
        performContainerUpdate {
            existingObjects = Set(objects).intersection(self.fetchedObjectsSet)
        } delegateUpdate: {
            existingObjects.forEach { object in
                self.delegate?.container(self, didChange: object, at: self.indexPath(for: object), for: .update, newIndexPath: nil)
            }
        }
    }
    
    public func appendSections(_ sections: [Section]) {
        var sectionsCountBeforeUpdate: Int?
        var sectionsToAppend = [Section]()
        
        performContainerUpdate {
            sectionsToAppend = self.filterSectionsForExistedObjects(in: sections)
            guard !sectionsToAppend.isEmpty else { return }
            sectionsCountBeforeUpdate = self.numberOfSections()
            self._sections.append(contentsOf: sectionsToAppend)
        } delegateUpdate: {
            guard let sectionsCountBeforeUpdate else { return }
            sectionsToAppend.enumerated().forEach { index, section in
                self.delegate?.container(self, didChange: section, atSectionIndex: sectionsCountBeforeUpdate == .zero ? index : sectionsCountBeforeUpdate + index, for: .insert)
            }
        }
    }
    
    public func insertSections(_ sections: [Section], beforeSection: Section) {
        var sectionsToInsert = [Section]()
        var beforeSectionIndex: Int?
        
        performContainerUpdate {
            sectionsToInsert = self.filterSectionsForExistedObjects(in: sections)
            guard !sectionsToInsert.isEmpty else { return }
            beforeSectionIndex = self.indexOfSection(beforeSection)
            guard let beforeSectionIndex else { return }
            self._sections.insert(contentsOf: sectionsToInsert, at: beforeSectionIndex)
        } delegateUpdate: {
            guard let beforeSectionIndex else { return }
            sectionsToInsert.enumerated().forEach { index, section in
                self.delegate?.container(self, didChange: section, atSectionIndex: beforeSectionIndex + index, for: .insert)
            }
        }
    }
    
    public func insertSections(_ sections: [Section], afterSection: Section) {
        var sectionsToInsert = [Section]()
        var afterSectionIndex: Int?
        
        performContainerUpdate {
            sectionsToInsert = self.filterSectionsForExistedObjects(in: sections)
            guard !sectionsToInsert.isEmpty else { return }
            afterSectionIndex = self.indexOfSection(afterSection)
            guard let afterSectionIndex else { return }
            if afterSectionIndex + 1 == self.numberOfSections() {
                self._sections.append(contentsOf: sectionsToInsert)
            } else {
                self._sections.insert(contentsOf: sectionsToInsert, at: afterSectionIndex + 1)
            }
        } delegateUpdate: {
            guard let afterSectionIndex else { return }
            sectionsToInsert.enumerated().forEach { index, section in
                self.delegate?.container(self, didChange: section, atSectionIndex: afterSectionIndex + 1 + index, for: .insert)
            }
        }
    }
    
    public func deleteSections(_ sections: [Section]) {
        var sectionsForRemove = [Int: Section]()
        
        performContainerUpdate {
            let existingSections = Set(sections).intersection(self.sectionsSet)
            guard !existingSections.isEmpty else { return }
            sectionsForRemove = existingSections.reduce(into: [Int: Section]()) { result, section in
                if let sectionIndex = self.indexOfSection(section) {
                    result[sectionIndex] = section
                }
            }
            self._sections.removeAll { Set(sectionsForRemove.values).contains($0) }
        } delegateUpdate: {
            sectionsForRemove.forEach { index, section in
                self.delegate?.container(self, didChange: section, atSectionIndex: index, for: .delete)
            }
        }
    }
    
    public func moveSection(_ section: Section, beforeSection: Section) {
        var sectionIndex: Int?
        var beforeSectionIndex: Int?
        
        performContainerUpdate {
            sectionIndex = self.indexOfSection(section)
            beforeSectionIndex = self.indexOfSection(beforeSection)
            guard let sectionIndex, let beforeSectionIndex else { return }
            self._sections.remove(at: sectionIndex)
            self._sections.insert(section, at: beforeSectionIndex)
        } delegateUpdate: {
            guard let sectionIndex, let beforeSectionIndex else { return }
            self.delegate?.container(self, didChange: section, atSectionIndex: sectionIndex, for: .delete)
            self.delegate?.container(self, didChange: section, atSectionIndex: beforeSectionIndex, for: .insert)
        }
    }
    
    public func moveSection(_ section: Section, afterSection: Section) {
        var sectionIndex: Int?
        var afterSectionIndex: Int?
        
        performContainerUpdate {
            sectionIndex = self.indexOfSection(section)
            afterSectionIndex = self.indexOfSection(afterSection)
            guard let sectionIndex, let afterSectionIndex else { return }
            self._sections.remove(at: sectionIndex)
            if afterSectionIndex + 1 < self._sections.count {
                self._sections.insert(section, at: afterSectionIndex + 1)
            } else {
                self._sections.append(section)
            }
        } delegateUpdate: {
            guard let sectionIndex, let afterSectionIndex else { return }
            self.delegate?.container(self, didChange: section, atSectionIndex: sectionIndex, for: .delete)
            self.delegate?.container(self, didChange: section, atSectionIndex: afterSectionIndex + 1, for: .insert)
        }
    }
    
    public func reloadSections(_ sections: [Section]) {
        var existingSections = Set<Section>()
        
        performContainerUpdate {
            existingSections = Set(sections).intersection(self.sectionsSet)
        } delegateUpdate: {
            existingSections.forEach { section in
                if let sectionIndex = self.indexOfSection(section) {
                    self.delegate?.container(self, didChange: section, atSectionIndex: sectionIndex, for: .reload)
                }
            }
        }
    }
    
    private func filterExistingObjects(_ objects: [ObjectType]) -> [ObjectType] {
        let newObjects = Set(objects).subtracting(fetchedObjectsSet)
        return objects.filter { newObjects.contains($0) }
    }

    private func filterSectionsForExistedObjects(in sections: [Section]) -> [Section] {
        var tempSet = Set<ObjectType>()
        var filteredSections = [Section]()
        
        for section in sections {
            let objects = filterExistingObjects(section._objects)
            section._objects = objects.filter { !tempSet.contains($0) }
            tempSet.formUnion(objects)
            
            if !section._objects.isEmpty {
                filteredSections.append(section)
            }
        }
        
        return filteredSections
    }
    
    private func performContainerUpdate(update: @escaping () -> Void, delegateUpdate: @escaping () -> Void) {
        operationsPipe.executeOperation(update) {
            self.delegate?.containerWillChangeContent(self)
            delegateUpdate()
            self.delegate?.containerDidChangeContent(self)
        }
    }
    
    public class Section: Hashable, DataSourceSectionInfo {
        public private(set) var sender: Any?
        public private(set) var name: String
        public private(set) var indexTitle: String?
        public var numberOfObjects: Int { _objects.count }
        public var objects: [Any]? { _objects }
        
        fileprivate var _objects: [ObjectType] = []
        fileprivate var objectsSet: Set<ObjectType> { Set(_objects) }
        
        public init(sender: Any? = nil, name: String = .init(), indexTitle: String? = nil, objects: [ObjectType] = []) {
            self.sender = sender
            self.name = name
            self.indexTitle = indexTitle
            self._objects = objects
        }
        
        fileprivate func contains(object: ObjectType) -> Bool {
            objectsSet.contains(object)
        }
        
        fileprivate func indexOfObject(_ object: ObjectType) -> Int? {
            _objects.firstIndex(of: object)
        }
        
        fileprivate func append(_ objects: [ObjectType]) {
            _objects.append(contentsOf: objects)
        }
        
        fileprivate func insertObjects(_ objects: [ObjectType], beforeObject: ObjectType) {
            if let beforeObjectIndex = indexOfObject(beforeObject) {
                _objects.insert(contentsOf: objects, at: beforeObjectIndex)
            }
        }
        
        fileprivate func insertObjects(_ objects: [ObjectType], afterObject: ObjectType) {
            if let afterObjectIndex = indexOfObject(afterObject) {
                if afterObjectIndex + 1 == numberOfObjects {
                    _objects.append(contentsOf: objects)
                } else {
                    _objects.insert(contentsOf: objects, at: afterObjectIndex + 1)
                }
            }
        }
        
        fileprivate func deleteObjects(_ objects: [ObjectType]) {
            _objects.removeAll { objects.contains($0) }
        }
        
        fileprivate func moveObject(_ object: ObjectType, beforeObject: ObjectType) {
            if let beforeObjectIndex = indexOfObject(beforeObject) {
                _objects.removeAll { $0 == object }
                _objects.insert(object, at: beforeObjectIndex)
            }
        }
        
        fileprivate func moveObject(_ object: ObjectType, afterObject: ObjectType) {
            if contains(object: afterObject) {
                _objects.removeAll { $0 == object }
                if let afterObjectIndex = indexOfObject(afterObject) {
                    if afterObjectIndex + 1 == numberOfObjects {
                        _objects.append(object)
                    } else {
                        _objects.insert(object, at: afterObjectIndex + 1)
                    }
                }
            }
        }
        
        fileprivate func replaceObject(_ object: ObjectType, with newObject: ObjectType) {
            insertObjects([newObject], afterObject: object)
            deleteObjects([object])
        }
        
        public static func == (lhs: Section, rhs: Section) -> Bool {
            lhs.hashValue == rhs.hashValue
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(_objects)
            hasher.combine(name)
            hasher.combine(indexTitle)
        }
    }
}
