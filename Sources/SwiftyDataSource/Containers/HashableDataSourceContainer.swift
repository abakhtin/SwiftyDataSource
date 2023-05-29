//
//  HashableDataSourceContainer.swift
//  SwiftyDataSource
//
//  Created by Yauheni Fiadotau on 13.05.23.
//  Copyright © 2023 EffectiveSoft. All rights reserved.
//

import Foundation

public class HashableDataSourceContainer<ObjectType: Hashable>: DataSourceContainer<ObjectType> {
    
    // MARK: - Container Update Queue
    
    private lazy var operationsQueue = DataSourceContainerOperationsQueue()
    
    private func performContainerUpdate(update: @escaping () -> Void, delegateUpdate: @escaping () -> Void) {
        sectionsBackup = _sections
        operationsQueue.executeOperation(update) {
            self.delegate?.containerWillChangeContent(self)
            delegateUpdate()
            self.sectionsBackup = self._sections
            self.delegate?.containerDidChangeContent(self)
        }
    }
   
    // MARK: - Storage
    
    private var _sections: [Section] = []
    private var sectionsBackup: [Section] = []
    
    // MARK: - Initializer
    
    public init(_ sections: [Section] = []) {
        super.init()
        if !sections.isEmpty { appendSections(sections) }
    }
    
    // MARK: - Computed Sets
    
    private var sectionsSet: Set<Section> { Set(sectionsBackup) }
    private var fetchedObjectsSet: Set<ObjectType> { Set(fetchedObjects ?? []) }
    
    // MARK: - DataSourceContainer Interface & implementation
    
    /// Retrieves an array of section information in the container.
    /// - Returns: An array of `DataSourceSectionInfo` representing the sections in the container.
    public override var sections: [DataSourceSectionInfo]? { sectionsBackup }
    /// Retrieves an array of objects fetched from the container.
    /// - Returns: An array of `ObjectType` representing the fetched objects.
    public override var fetchedObjects: [ObjectType]? { sectionsBackup.flatMap { $0._objects } }
    
    /// Retrieves the object at the specified index path.
    /// - Parameter indexPath: The index path of the object.
    /// - Returns: The object at the specified index path, or `nil` if the index path is out of bounds.
    public override func object(at indexPath: IndexPath) -> ObjectType? {
        sectionsBackup[safe: indexPath.section]?._objects[safe: indexPath.row]
    }
    
    /// Retrieves the index path for the specified object.
    /// - Parameter object: The object.
    /// - Returns: The index path of the object, or `nil` if the object is not found.
    public override func indexPath(for object: ObjectType) -> IndexPath? {
        if let sectionWithObject = section(containingObject: object),
           let sectionIndex = indexOfSection(sectionWithObject),
           let objectIndex = sectionWithObject.indexOfObject(object) {
            return IndexPath(row: objectIndex, section: sectionIndex)
        } else {
            return nil
        }
    }
    
    /// Searches for an object in the container that satisfies the specified condition.
    /// - Parameter block: A closure that takes an index path and an object as parameters and returns a Boolean value indicating whether the object satisfies the condition.
    /// - Returns: The index path of the first object that satisfies the condition, or `nil` if no object is found.
    public override func search(_ block: (IndexPath, ObjectType) -> Bool) -> IndexPath? {
        var resultIndexPath: IndexPath?
        sectionsBackup.enumerated().forEach { sectionIndex, section in
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
    
    /// Enumerates through each object in the container and executes the specified closure.
    /// - Parameter block: A closure that takes an index path and an object as parameters and performs an action.
    public override func enumerate(_ block: (IndexPath, ObjectType) -> Void) {
        sectionsBackup.enumerated().forEach { sectionIndex, section in
            section._objects.enumerated().forEach { objectIndex, object in
                block(IndexPath(row: objectIndex, section: sectionIndex), object)
            }
        }
    }
    
    /// Retrieves the number of sections in the container.
    /// - Returns: The number of sections in the container
    public override func numberOfSections() -> Int? { sectionsBackup.count }
    
    /// Retrieves the number of items in the specified section.
    /// - Parameter section: The section index.
    /// - Returns: The number of items in the specified section, or `nil` if the section is invalid.
    public override func numberOfItems(in section: Int) -> Int? { sectionsBackup[safe: section]?.numberOfObjects }
    
    // MARK: - Public HashableDataSourceContainer interface & implementation
    
    /// Performs the specified block of code after all pending updates have been applied to the container.
    /// - Parameter block: The block of code to be executed.
    ///                    It takes the `HashableDataSourceContainer` instance as its parameter.
    public func performAfterUpdates(_ block: @escaping (_ container: HashableDataSourceContainer<ObjectType>) -> Void) {
        operationsQueue.executeOperation {
            block(self)
        }
    }
    
    /// Retrieves the objects in the specified section.
    /// - Parameter sectionIndex: The index of the section.
    /// - Returns: An array of objects in the specified section.
    public func objects(atSectionIndex sectionIndex: Int) -> [ObjectType] {
        sectionsBackup[safe: sectionIndex]?._objects ?? []
    }
    
    /// Retrieves the objects in the specified section.
    /// - Parameter section: The section.
    /// - Returns: An array of objects in the specified section.
    public func objects(atSection section: Section) -> [ObjectType] {
        section._objects
    }
    
    /// Retrieves the objects in the section containing the specified object.
    /// - Parameter object: The object.
    /// - Returns: An array of objects in the section containing the specified object.
    public func objects(atSectionContaining object: ObjectType) -> [ObjectType] {
        section(containingObject: object)?._objects ?? []
    }
    
    /// Retrieves the section that contains the specified object.
    /// - Parameter object: The object.
    /// - Returns: The section that contains the specified object, or `nil` if the object is not found in any section.
    public func section(containingObject object: ObjectType) -> Section? {
        sectionsBackup.first { $0.contains(object: object) }
    }
    
    /// Retrieves the first object in the specified section.
    /// - Parameter section: The section.
    /// - Returns: The first object in the section, or `nil` if the section is empty.
    public func firstObject(inSection section: Section?) -> ObjectType? {
        section?._objects.first
    }
    
    /// Retrieves the last object in the specified section.
    /// - Parameter section: The section.
    /// - Returns: The last object in the section, or `nil` if the section is empty.
    public func lastObject(inSection section: Section?) -> ObjectType? {
        section?._objects.last
    }
    
    /// Checks if the container contains the specified object.
    /// - Parameter object: The object to be checked.
    /// - Returns: `true` if the container contains the object, `false` otherwise.
    public func contains(_ object: ObjectType) -> Bool {
        fetchedObjectsSet.contains(object)
    }
    
    /// Retrieves the index of the specified object.
    /// - Parameter object: The object.
    /// - Returns: The index of the object, or `nil` if the object is not found.
    public func indexOfObject(_ object: ObjectType) -> Int? {
        indexPath(for: object)?.row
    }
    
    /// Retrieves the index of the specified section.
    /// - Parameter section: The section.
    /// - Returns: The index of the section, or `nil` if the section is not found.
    public func indexOfSection(_ section: Section) -> Int? {
        sectionsBackup.firstIndex(of: section)
    }
    
    /// Appends the specified objects to the given section.
    /// - Parameters:
    ///   - objects: The objects to be appended.
    ///   - section: The section to which the objects should be appended.
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
    
    /// Inserts the specified objects before the given object in the same section.
    /// - Parameters:
    ///   - objects: The objects to be inserted.
    ///   - beforeObject: The object before which the new objects should be inserted.
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
    
    /// Inserts the specified objects after the given object in the same section.
    /// - Parameters:
    ///   - objects: The objects to be inserted.
    ///   - afterObject: The object after which the new objects should be inserted.
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
    
    /// Deletes the specified objects from the container.
    /// - Parameter objects: The objects to be deleted.
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
    
    /// Deletes all objects from the container.
    public func deleteAllObjects() {
        var sections = [Section]()
        performContainerUpdate {
            sections = self.sectionsBackup
            self._sections = []
        } delegateUpdate: {
            sections.enumerated().forEach { index, section in
                self.delegate?.container(self, didChange: section, atSectionIndex: index, for: .delete)
            }
        }
    }
    
    /// Moves the specified object before another object in the same section.
    /// - Parameters:
    ///   - object: The object to be moved.
    ///   - beforeObject: The object before which the specified object should be moved.
    public func moveObject(_ object: ObjectType, beforeObject: ObjectType) {
        var oldIndexPath: IndexPath?
        var newIndexPath: IndexPath?
        
        performContainerUpdate {
            guard object != beforeObject,
                  let sectionOfObject = self.section(containingObject: object),
                  let sectionIndex = self.indexOfSection(sectionOfObject),
                  let indexOfObject = sectionOfObject.indexOfObject(object),
                  let sectionOfBeforeObject = self.section(containingObject: beforeObject),
                  let sectionIndexOfBeforeObject = self.indexOfSection(sectionOfBeforeObject),
                  let indexOfBeforeObject = sectionOfBeforeObject.indexOfObject(beforeObject) else { return }
            oldIndexPath = IndexPath(row: indexOfObject, section: sectionIndex)
            newIndexPath = IndexPath(row: indexOfBeforeObject, section: sectionIndexOfBeforeObject)
            if sectionOfObject == sectionOfBeforeObject {
                sectionOfObject.moveObject(object, beforeObject: beforeObject)
            } else {
                sectionOfObject.deleteObjects([object])
                sectionOfBeforeObject.insertObjects([object], beforeObject: beforeObject)
            }
        } delegateUpdate: {
            guard let oldIndexPath, let newIndexPath, oldIndexPath != newIndexPath else { return }
            self.delegate?.container(self, didChange: object, at: oldIndexPath, for: .move, newIndexPath: newIndexPath)
        }
    }
    
    /// Moves the specified object after another object in the same section.
    /// - Parameters:
    ///   - object: The object to be moved.
    ///   - afterObject: The object after which the specified object should be moved.
    public func moveObject(_ object: ObjectType, afterObject: ObjectType) {
        var oldIndexPath: IndexPath?
        var newIndexPath: IndexPath?
        
        performContainerUpdate {
            guard object != afterObject,
                  let sectionOfObject = self.section(containingObject: object),
                  let sectionIndex = self.indexOfSection(sectionOfObject),
                  let indexOfObject = sectionOfObject.indexOfObject(object),
                  let sectionOfAfterObject = self.section(containingObject: afterObject),
                  let sectionIndexOfAfterObject = self.indexOfSection(sectionOfAfterObject),
                  let indexOfAfterItem = sectionOfAfterObject.indexOfObject(afterObject) else { return }
            oldIndexPath = IndexPath(row: indexOfObject, section: sectionIndex)
            newIndexPath = IndexPath(row: indexOfAfterItem + 1, section: sectionIndexOfAfterObject)
            if sectionOfObject == sectionOfAfterObject {
                sectionOfObject.moveObject(object, afterObject: afterObject)
            } else {
                sectionOfObject.deleteObjects([object])
                sectionOfAfterObject.insertObjects([object], afterObject: afterObject)
            }
        } delegateUpdate: {
            guard let oldIndexPath, var newIndexPath, oldIndexPath != newIndexPath else { return }
            if oldIndexPath.section == newIndexPath.section, oldIndexPath.row < newIndexPath.row {
                newIndexPath = IndexPath(row: newIndexPath.row - 1, section: newIndexPath.section)
            }
            self.delegate?.container(self, didChange: object, at: oldIndexPath, for: .move, newIndexPath: newIndexPath)
        }
    }
    
    /// Replaces an object with a new object in the container.
    /// - Parameters:
    ///   - object: The object to be replaced.
    ///   - newObject: The new object to replace with.
    public func replaceObject(_ object: ObjectType, with newObject: ObjectType) {
        var indexPath: IndexPath?
        
        performContainerUpdate {
            if (!self.contains(newObject) || object.hashValue == newObject.hashValue),
               let sectionWithObject = self.section(containingObject: object),
               let sectionIndex = self.indexOfSection(sectionWithObject),
               let objectIndex = sectionWithObject.indexOfObject(object) {
                sectionWithObject.replaceObject(object, with: newObject)
                indexPath = IndexPath(row: objectIndex, section: sectionIndex)
            }
        } delegateUpdate: {
            guard let indexPath else { return }
            self.delegate?.container(self, didChange: newObject, at: indexPath, for: .reload, newIndexPath: nil)
        }
    }
    
    /// Reloads the specified objects in the container.
    /// - Parameter objects: The objects to be reloaded.
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
    
    /// Reconfigures the specified objects in the container.
    /// - Parameter objects: The objects to be reconfigured.
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
    
    /// Appends the specified sections to the container.
    /// - Parameter sections: The sections to be appended.
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
    
    /// Inserts the specified sections before the given section.
    /// - Parameters:
    ///   - sections: The sections to be inserted.
    ///   - beforeSection: The section before which the new sections should be inserted.
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
    
    /// Inserts the specified sections after the given section.
    /// - Parameters:
    ///   - sections: The sections to be inserted.
    ///   - afterSection: The section after which the new sections should be inserted.
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
    
    /// Deletes the specified sections from the container.
    /// - Parameter sections: The sections to be deleted.
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
    
    /// Moves a section before another section in the container.
    /// - Parameters:
    ///   - section: The section to be moved.
    ///   - beforeSection: The section before which the specified section should be moved.
    public func moveSection(_ section: Section, beforeSection: Section) {
        var sectionIndex: Int?
        var movedSectionIndex: Int?
        
        performContainerUpdate {
            guard section != beforeSection, self.sectionsSet.contains(section), self.sectionsSet.contains(beforeSection) else { return }
            sectionIndex = self._sections.firstIndex(of: section)
            self._sections.removeAll { $0 == section }
            if let beforeSectionIndex = self._sections.firstIndex(of: beforeSection) {
                self._sections.insert(section, at: beforeSectionIndex)
                movedSectionIndex = beforeSectionIndex
            }
        } delegateUpdate: {
            guard let sectionIndex, let movedSectionIndex else { return }
            self.delegate?.container(self, didChange: section, atSectionIndex: sectionIndex, for: .delete)
            self.delegate?.container(self, didChange: section, atSectionIndex: movedSectionIndex, for: .insert)
        }
    }
    
    /// Moves a section after another section in the container.
    /// - Parameters:
    ///   - section: The section to be moved.
    ///   - afterSection: The section after which the specified section should be moved.
    public func moveSection(_ section: Section, afterSection: Section) {
        var sectionIndex: Int?
        var movedSectionIndex: Int?
        
        performContainerUpdate {
            guard section != afterSection, self.sectionsSet.contains(section), self.sectionsSet.contains(afterSection) else { return }
            sectionIndex = self._sections.firstIndex(of: section)
            self._sections.removeAll { $0 == section }
            if let afterSectionIndex = self._sections.firstIndex(of: afterSection) {
                if afterSectionIndex + 1 == self._sections.count {
                    self._sections.append(section)
                } else {
                    self._sections.insert(section, at: afterSectionIndex + 1)
                }
                movedSectionIndex = afterSectionIndex + 1
            }
        } delegateUpdate: {
            guard let sectionIndex, let movedSectionIndex else { return }
            self.delegate?.container(self, didChange: section, atSectionIndex: sectionIndex, for: .delete)
            self.delegate?.container(self, didChange: section, atSectionIndex: movedSectionIndex, for: .insert)
        }
    }
    
    /// Reloads the specified sections in the container.
    /// - Parameter sections: The sections to be reloaded.
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
    
    // MARK: - Helper methods
    
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
    
    // MARK: - HashableDataSourceContainer Section Implementation
    
    public class Section: Hashable, DataSourceSectionInfo {
        
        // MARK: - DataSourceSectionInfo protocol implementation
        
        public private(set) var sender: Any?
        public private(set) var name: String
        public private(set) var indexTitle: String?
        public var numberOfObjects: Int { _objects.count }
        public var objects: [Any]? { _objects }
        
        // MARK: - Storage
        
        fileprivate var _objects: [ObjectType] = []
        
        // MARK: - Computed Set
        
        fileprivate var objectsSet: Set<ObjectType> { Set(_objects) }
        
        // MARK: - Initialzier
        
        public init(sender: Any? = nil, name: String = .init(), indexTitle: String? = nil, objects: [ObjectType] = []) {
            self.sender = sender
            self.name = name
            self.indexTitle = indexTitle
            self._objects = objects
        }
        
        // MARK: - Methods to interact with section
        
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
            objects.forEach { object in
                guard let index = _objects.firstIndex(of: object) else { return }
                _objects.remove(at: index)
            }
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
        
        // MARK: - Hashable implementation
        
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
