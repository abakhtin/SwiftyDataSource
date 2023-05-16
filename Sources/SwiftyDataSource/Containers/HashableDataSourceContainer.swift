//
//  HashableDataSourceContainer.swift
//  SwiftyDataSource
//
//  Created by Yauheni Fiadotau on 13.05.23.
//  Copyright © 2023 EffectiveSoft. All rights reserved.
//

import Foundation

public class HashableDataSourceContainer<ObjectType: Hashable>: DataSourceContainer<ObjectType> {
    private var _sections: [Section] = []
    private var sectionsSet: Set<Section> { Set(_sections) }
    private var fetchedObjectsSet: Set<ObjectType> { Set(fetchedObjects ?? []) }
    
    public override var sections: [DataSourceSectionInfo]? { _sections }
    public override var fetchedObjects: [ObjectType]? { _sections.flatMap { $0._objects } }
    
    private var isExecutingTask = false
    private var taskArray: [DispatchWorkItem] = []
    private var updateTask: DispatchWorkItem?
    
    private func executeNextTask() {
        if !isExecutingTask {
            if let updateTask {
                isExecutingTask = true
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    updateTask.perform()
                    self.updateTask = nil
                    self.isExecutingTask = false
                    self.executeNextTask()
                }
            } else if let task = taskArray.first {
                isExecutingTask = true
                DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                    guard let self else { return }
                    task.perform()
                    DispatchQueue.main.async {
                        self.taskArray.removeFirst()
                        self.isExecutingTask = false
                        self.executeNextTask()
                    }
                }
            }
        }
    }
    
    private func addTask(_ task: @escaping () -> Void) {
        taskArray.append(.init(block: task))
        executeNextTask()
    }
    
    private func setUpdateTask(_ task: @escaping () -> Void) {
        updateTask = .init { [weak self] in
            guard let self else { return }
            self.delegate?.containerWillChangeContent(self)
            task()
            self.delegate?.containerDidChangeContent(self)
        }
    }
    
    public func performAfterUpdates(_ block: @escaping (_ container: HashableDataSourceContainer<ObjectType>) -> Void) {
        addTask { [weak self] in
            guard let self else { return }
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
        addTask { [weak self] in
            guard let self else { return }
            if let section, let sectionIndex = self.indexOfSection(section) {
                let objectsToAppend = self.getOnlyNewObjects(objects)
                if !objectsToAppend.isEmpty {
                    let objectsCountInSectionBeforeAppending = section.numberOfObjects
                    section.append(objectsToAppend)
                    self.setUpdateTask {
                        objectsToAppend.enumerated().forEach { index, object in
                            self.delegate?.container(
                                self,
                                didChange: object,
                                at: nil,
                                for: .insert,
                                newIndexPath: IndexPath(
                                    row: objectsCountInSectionBeforeAppending == .zero ? index : objectsCountInSectionBeforeAppending + index,
                                    section: sectionIndex
                                )
                            )
                        }
                    }
                }
            }
        }
    }
    
    public func insertObjects(_ objects: [ObjectType], beforeObject: ObjectType) {
        addTask { [weak self] in
            guard let self else { return }
            if let section = self.section(containingObject: beforeObject),
               let sectionIndex = self.indexOfSection(section),
               let beforeObjectIndex = section.indexOfObject(beforeObject) {
                let objectsToInsert = self.getOnlyNewObjects(objects)
                if !objectsToInsert.isEmpty {
                    section.insertObjects(objectsToInsert, beforeObject: beforeObject)
                    self.setUpdateTask {
                        objectsToInsert.enumerated().forEach { index, object in
                            self.delegate?.container(
                                self,
                                didChange: object,
                                at: nil,
                                for: .insert,
                                newIndexPath: IndexPath(row: beforeObjectIndex + index, section: sectionIndex)
                            )
                        }
                    }
                }
            }
        }
    }
    
    public func insertObjects(_ objects: [ObjectType], afterObject: ObjectType) {
        addTask { [weak self] in
            guard let self else { return }
            if let section = self.section(containingObject: afterObject),
               let sectionIndex = self.indexOfSection(section),
               let afterObjectIndex = section.indexOfObject(afterObject) {
                let objectsToInsert = self.getOnlyNewObjects(objects)
                if !objectsToInsert.isEmpty {
                    section.insertObjects(objectsToInsert, afterObject: afterObject)
                    self.setUpdateTask {
                        objectsToInsert.enumerated().forEach { index, object in
                            self.delegate?.container(
                                self,
                                didChange: object,
                                at: nil,
                                for: .insert,
                                newIndexPath: IndexPath(row: afterObjectIndex + index + 1, section: sectionIndex)
                            )
                        }
                    }
                }
            }
        }
    }
    
    public func deleteObjects(_ objects: [ObjectType]) {
        addTask { [weak self] in
            guard let self else { return }
            let objectsToDeleteDictionary = objects.uniqued().reduce(into: [Section: [ObjectType]]()) { result, object in
                if let section = self.section(containingObject: object) {
                    result[section, default: []].append(object)
                }
            }
            var indexesOfDeletedObjects: [Int: [(object: ObjectType, index: Int)]] = [:]
            var sectionsForDelete: [Int: Section] = [:]
            
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
            self.setUpdateTask {
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
    }
    
    public func deleteAllObjects() {
        addTask { [weak self] in
            guard let self else { return }
            let sections = self._sections
            self._sections = []
            if !sections.isEmpty {
                self.setUpdateTask {
                    sections.enumerated().forEach { index, section in
                        self.delegate?.container(self, didChange: section, atSectionIndex: index, for: .delete)
                    }
                }
            }
        }
    }
    
    public func moveObject(_ object: ObjectType, beforeObject: ObjectType) {
        addTask { [weak self] in
            guard let self else { return }
            if let sectionOfObject = self.section(containingObject: object),
               let sectionIndex = self.indexOfSection(sectionOfObject),
               let indexOfObject = sectionOfObject.indexOfObject(object),
               let sectionOfBeforeObject = self.section(containingObject: beforeObject),
               let sectionIndexOfBeforeObject = self.indexOfSection(sectionOfBeforeObject),
               let indexOfBeforeObject = sectionOfObject.indexOfObject(beforeObject) {
                let oldIndexPath = IndexPath(row: indexOfObject, section: sectionIndex)
                let newIndexPath = IndexPath(row: indexOfBeforeObject, section: sectionIndexOfBeforeObject)
                if oldIndexPath != newIndexPath {
                    if sectionOfObject == sectionOfBeforeObject {
                        sectionOfObject.moveObject(object, beforeObject: beforeObject)
                    } else {
                        sectionOfObject.deleteObjects([object])
                        sectionOfBeforeObject.insertObjects([object], beforeObject: beforeObject)
                    }
                    self.setUpdateTask {
                        self.delegate?.container(self, didChange: object, at: oldIndexPath, for: .move, newIndexPath: newIndexPath)
                    }
                }
            }
        }
    }
    
    public func moveObject(_ object: ObjectType, afterObject: ObjectType) {
        addTask { [weak self] in
            guard let self else { return }
            if let sectionOfObject = self.section(containingObject: object),
               let sectionIndex = self.indexOfSection(sectionOfObject),
               let indexOfObject = sectionOfObject.indexOfObject(object),
               let sectionOfAfterObject = self.section(containingObject: afterObject),
               let sectionIndexOfAfterObject = self.indexOfSection(sectionOfAfterObject),
               let indexOfAfterItem = sectionOfObject.indexOfObject(afterObject) {
                let oldIndexPath = IndexPath(row: indexOfObject, section: sectionIndex)
                let newIndexPath = IndexPath(row: indexOfAfterItem + 1, section: sectionIndexOfAfterObject)
                if oldIndexPath != newIndexPath {
                    if sectionOfObject == sectionOfAfterObject {
                        sectionOfObject.moveObject(object, afterObject: afterObject)
                    } else {
                        sectionOfObject.deleteObjects([object])
                        sectionOfAfterObject.insertObjects([object], afterObject: afterObject)
                        
                    }
                    self.setUpdateTask {
                        self.delegate?.container(self, didChange: object, at: oldIndexPath, for: .move, newIndexPath: newIndexPath)
                    }
                }
            }
        }
    }
    
    public func replaceObject(_ object: ObjectType, with newObject: ObjectType) {
        addTask { [weak self] in
            guard let self else { return }
            if let sectionWithObject = self.section(containingObject: object),
               let sectionIndex = self.indexOfSection(sectionWithObject),
               let objectIndex = sectionWithObject.indexOfObject(object) {
                sectionWithObject.replaceObject(object, with: newObject)
                let indexPath = IndexPath(row: objectIndex, section: sectionIndex)
                self.setUpdateTask {
                    self.delegate?.container(self, didChange: object, at: indexPath, for: .delete, newIndexPath: nil)
                    self.delegate?.container(self, didChange: newObject, at: indexPath, for: .insert, newIndexPath: indexPath)
                }
            }
        }
    }
    
    public func reloadObjects(_ objects: [ObjectType]) {
        addTask { [weak self] in
            guard let self else { return }
            let existingObjects = Set(objects).intersection(self.fetchedObjectsSet)
            if !existingObjects.isEmpty {
                self.setUpdateTask {
                    existingObjects.forEach { object in
                        self.delegate?.container(self, didChange: object, at: self.indexPath(for: object), for: .reload, newIndexPath: nil)
                    }
                }
            }
        }
    }
    
    public func reconfigureObjects(_ objects: [ObjectType]) {
        addTask { [weak self] in
            guard let self else { return }
            let existingObjects = Set(objects).intersection(self.fetchedObjectsSet)
            if !existingObjects.isEmpty {
                self.setUpdateTask {
                    existingObjects.forEach { object in
                        self.delegate?.container(self, didChange: object, at: self.indexPath(for: object), for: .update, newIndexPath: nil)
                    }
                }
            }
        }
    }
    
    public func appendSections(_ sections: [Section]) {
        addTask { [weak self] in
            guard let self else { return }
            let sectionsWithNewObjects = self.filterSectionsForExistedObjects(in: sections)
            if !sectionsWithNewObjects.isEmpty {
                self._sections.append(contentsOf: sectionsWithNewObjects)
                self.setUpdateTask {
                    self._sections.enumerated().filter { sectionsWithNewObjects.contains($0.element) }.forEach { sectionIndex, section in
                        self.delegate?.container(self, didChange: section, atSectionIndex: sectionIndex, for: .insert)
                    }
                }
            }
        }
    }
    
    public func insertSections(_ sections: [Section], beforeSection: Section) {
        addTask { [weak self] in
            guard let self else { return }
            let sectionsWithNewObjects = self.filterSectionsForExistedObjects(in: sections)
            if !sectionsWithNewObjects.isEmpty {
                if let beforeSectionIndex = self.indexOfSection(beforeSection) {
                    self._sections.insert(contentsOf: sectionsWithNewObjects, at: beforeSectionIndex)
                    self.setUpdateTask {
                        self._sections.enumerated().filter { sectionsWithNewObjects.contains($0.element) }.forEach { sectionIndex, section in
                            self.delegate?.container(self, didChange: section, atSectionIndex: sectionIndex, for: .insert)
                        }
                    }
                }
            }
        }
    }
    
    public func insertSections(_ sections: [Section], afterSection: Section) {
        addTask { [weak self] in
            guard let self else { return }
            let sectionsWithNewObjects = self.filterSectionsForExistedObjects(in: sections)
            if !sectionsWithNewObjects.isEmpty {
                if let afterSectionIndex = self.indexOfSection(afterSection) {
                    self._sections.insert(contentsOf: sectionsWithNewObjects, at: afterSectionIndex + 1)
                    self.setUpdateTask {
                        self._sections.enumerated().filter { sectionsWithNewObjects.contains($0.element) }.forEach { sectionIndex, section in
                            self.delegate?.container(self, didChange: section, atSectionIndex: sectionIndex, for: .insert)
                        }
                    }
                }
            }
        }
    }
    
    public func deleteSections(_ sections: [Section]) {
        addTask { [weak self] in
            guard let self else { return }
            let existingSections = Set(sections).intersection(self.sectionsSet)
            if !existingSections.isEmpty {
                let sectionsForRemove = existingSections.reduce(into: [Int: Section]()) { result, section in
                    if let sectionIndex = self.indexOfSection(section) {
                        result[sectionIndex] = section
                    }
                }
                self._sections.removeAll { Set(sectionsForRemove.values).contains($0) }
                self.setUpdateTask {
                    sectionsForRemove.forEach { index, section in
                        self.delegate?.container(self, didChange: section, atSectionIndex: index, for: .delete)
                    }
                }
            }
        }
    }
    
    public func moveSection(_ section: Section, beforeSection: Section) {
        addTask { [weak self] in
            guard let self else { return }
            if let sectionIndex = self.indexOfSection(section),
               let beforeSectionIndex = self.indexOfSection(beforeSection) {
                self._sections.remove(at: sectionIndex)
                self._sections.insert(section, at: beforeSectionIndex)
                
                self.setUpdateTask {
                    self.delegate?.container(self, didChange: section, atSectionIndex: sectionIndex, for: .delete)
                    self.delegate?.container(self, didChange: section, atSectionIndex: beforeSectionIndex, for: .insert)
                }
            }
        }
    }
    
    public func moveSection(_ section: Section, afterSection: Section) {
        addTask { [weak self] in
            guard let self else { return }
            if let sectionIndex = self.indexOfSection(section),
               let afterSectionIndex = self.indexOfSection(afterSection) {
                self._sections.remove(at: sectionIndex)
                if afterSectionIndex + 1 < self._sections.count {
                    self._sections.insert(section, at: afterSectionIndex + 1)
                } else {
                    self._sections.append(section)
                }
                
                self.setUpdateTask {
                    self.delegate?.container(self, didChange: section, atSectionIndex: sectionIndex, for: .delete)
                    self.delegate?.container(self, didChange: section, atSectionIndex: afterSectionIndex + 1, for: .insert)
                }
            }
        }
    }
    
    public func reloadSections(_ sections: [Section]) {
        addTask { [weak self] in
            guard let self else { return }
            let existingSections = Set(sections).intersection(self.sectionsSet)
            if !existingSections.isEmpty {
                self.setUpdateTask {
                    sections.forEach { section in
                        if let sectionIndex = self.indexOfSection(section) {
                            self.delegate?.container(self, didChange: section, atSectionIndex: sectionIndex, for: .reload)
                        }
                    }
                }
            }
        }
    }
    
    private func getOnlyNewObjects(_ objects: [ObjectType]) -> [ObjectType] {
        let objects = objects.uniqued()
        let newObjects = Set(objects).subtracting(fetchedObjectsSet)
        return objects.filter { newObjects.contains($0) }
    }
    
    private func filterSectionsForExistedObjects(in sections: [Section]) -> [Section] {
        var tempSet = Set<ObjectType>()
        return sections.reduce(into: [Section]()) { result, section in
            let objects = getOnlyNewObjects(section._objects)
            section._objects = objects.filter { !tempSet.contains($0) }
            tempSet = tempSet.union(objects)
            if !section._objects.isEmpty {
                result.append(section)
            }
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
