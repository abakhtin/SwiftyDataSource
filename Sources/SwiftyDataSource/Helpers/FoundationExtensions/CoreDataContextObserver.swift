//
//  CoreDataContextObserver.swift
//  SwiftyDataSource
//
//  Created by Alexey Bakhtin on 04/01/2020.
//  Copyright © 2020 launchOptions. All rights reserved.
//

import Foundation
import CoreData

public struct CoreDataContextObserverState: OptionSet {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    
    public static let inserted = CoreDataContextObserverState(rawValue: 1 << 0)
    public static let updated = CoreDataContextObserverState(rawValue: 1 << 1)
    public static let deleted = CoreDataContextObserverState(rawValue: 1 << 2)
    public static let refreshed = CoreDataContextObserverState(rawValue: 1 << 3)
    public static let all: CoreDataContextObserverState  = [inserted, updated, deleted, refreshed]
}

public typealias CoreDataContextObserverContextChangeBlock = (_ notification: NSNotification, _ changedObjects: [CoreDataObserverObjectChange]) -> ()

public enum CoreDataObserverObjectChange {
    case updated(NSManagedObject)
    case refreshed(NSManagedObject)
    case inserted(NSManagedObject)
    case deleted(NSManagedObject)
    
    public func managedObject() -> NSManagedObject {
        switch self {
            case let .updated(value): return value
            case let .inserted(value): return value
            case let .refreshed(value): return value
            case let .deleted(value): return value
        }
    }
}

public class CoreDataContextObserver<T> where T: NSManagedObject {
    
    private struct CoreDataObserverAction<T> {
        var state: CoreDataContextObserverState
        var completionBlock: ObserverCallbackType<T>
    }

    public var enabled: Bool = true
    public var contextChangeBlock: CoreDataContextObserverContextChangeBlock?
    
    private(set) var context: NSManagedObjectContext
    private(set) weak var persistentStoreCoordinator: NSPersistentStoreCoordinator?
    private var notificationObserver: NSObjectProtocol?
    private var actionsForManagedObjectID: Dictionary<NSManagedObjectID,[CoreDataObserverAction<T>]> = [:]
    
    deinit {
        unobserveAllObjects()
        if let notificationObserver = notificationObserver {
            NotificationCenter.default.removeObserver(notificationObserver)
        }
    }
    
    public init(context: NSManagedObjectContext) {
        self.context = context
        self.persistentStoreCoordinator = context.persistentStoreCoordinator
        
        notificationObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: context, queue: nil) { [weak self] notification in
            self?.handleContextObjectDidChangeNotification(notification: notification as NSNotification)
        }
    }
    
    private func handleContextObjectDidChangeNotification(notification: NSNotification) {
        guard let incomingContext = notification.object as? NSManagedObjectContext,
            let persistentStoreCoordinator = persistentStoreCoordinator,
            let incomingPersistentStoreCoordinator = incomingContext.persistentStoreCoordinator,
            enabled && persistentStoreCoordinator == incomingPersistentStoreCoordinator else {
            return
        }

        let insertedObjectsSet = notification.userInfo?[NSInsertedObjectsKey] as? Set<NSManagedObject> ?? Set<NSManagedObject>()
        let updatedObjectsSet = notification.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject> ?? Set<NSManagedObject>()
        let deletedObjectsSet = notification.userInfo?[NSDeletedObjectsKey] as? Set<NSManagedObject> ?? Set<NSManagedObject>()
        let refreshedObjectsSet = notification.userInfo?[NSRefreshedObjectsKey] as? Set<NSManagedObject> ?? Set<NSManagedObject>()
        
        var combinedObjectChanges = insertedObjectsSet.map({ CoreDataObserverObjectChange.inserted($0) })
        combinedObjectChanges += updatedObjectsSet.map({ CoreDataObserverObjectChange.updated($0) })
        combinedObjectChanges += deletedObjectsSet.map({ CoreDataObserverObjectChange.deleted($0) })
        combinedObjectChanges += refreshedObjectsSet.map({ CoreDataObserverObjectChange.refreshed($0) })

        contextChangeBlock?(notification, combinedObjectChanges)
        
        let combinedSet = insertedObjectsSet.union(updatedObjectsSet).union(deletedObjectsSet).union(refreshedObjectsSet)
        let allObjectIDs = Array(actionsForManagedObjectID.keys)
        let filteredObjects = combinedSet.filter({ allObjectIDs.contains($0.objectID) })
        
        for object in filteredObjects {
            guard let actionsForObject = actionsForManagedObjectID[object.objectID], let object = object as? T else { continue }

            for action in actionsForObject {
                if action.state.contains(.inserted) && insertedObjectsSet.contains(object) {
                    action.completionBlock(object, .inserted)
                } else if action.state.contains(.updated) && updatedObjectsSet.contains(object) {
                    action.completionBlock(object, .updated)
                } else if action.state.contains(.deleted) && deletedObjectsSet.contains(object) {
                    action.completionBlock(object, .deleted)
                } else if action.state.contains(.refreshed) && refreshedObjectsSet.contains(object) {
                    action.completionBlock(object, .refreshed)
                }
            }
        }
    }
    
    public typealias ObserverCallbackType<T> = (T, CoreDataContextObserverState) -> ()

    public func observe(object: T, for state: CoreDataContextObserverState = .all, completion: @escaping ObserverCallbackType<T>) {
        let action = CoreDataObserverAction(state: state, completionBlock: completion)
        if var actionArray = actionsForManagedObjectID[object.objectID] {
            actionArray.append(action)
            actionsForManagedObjectID[object.objectID] = actionArray
        } else {
            actionsForManagedObjectID[object.objectID] = [action]
        }
        
    }
    
    public func unobserve(object: T, for state: CoreDataContextObserverState = .all) {
        if state == .all {
            actionsForManagedObjectID.removeValue(forKey: object.objectID)
        } else if let actionsForObject = actionsForManagedObjectID[object.objectID] {
            actionsForManagedObjectID[object.objectID] = actionsForObject.filter({ !$0.state.contains(state) })
        }
    }
    
    public func unobserveAllObjects() {
        actionsForManagedObjectID.removeAll()
    }
}
