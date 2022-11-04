//
//  DataSourceContainer.swift
//  DPDataStorage
//
//  Created by Alexey Bakhtin on 10/6/17.
//  Copyright © 2018 launchOptions. All rights reserved.
//

#if os(iOS)
import Foundation
import CoreData

public protocol DataSourceSectionInfo: NSFetchedResultsSectionInfo {
    var sender: Any? { get }
}

private class BaseDataSourceSectionInfo: DataSourceSectionInfo {
    var sender: Any? = nil
    var name: String = String()
    var indexTitle: String? = nil
    var numberOfObjects: Int = 0
    var objects: [Any]? = nil
}

public extension NSFetchedResultsSectionInfo {
    func asDataSourceSectionInfo() -> DataSourceSectionInfo {
        let base = BaseDataSourceSectionInfo()
        base.name = name
        base.indexTitle = indexTitle
        base.numberOfObjects = numberOfObjects
        base.objects = objects
        return base
    }
}

public enum DataSourceObjectChangeType {
    case insert
    case delete
    case move
    case update
    case reload
    case reloadAll

    static func fromFRCChangeType(_ type: NSFetchedResultsChangeType) -> DataSourceObjectChangeType {
        switch type {
        case .insert:   return .insert
        case .delete:   return .delete
        case .move:     return .reloadAll
        // WORKAROUND FOR COREDATA UPDATE CHANGE TYPE AS IT CAUSSES DUPLICATION
        // FOR SOME UNKNOWN REASON
        case .update:   return .reload
        default:        return .reloadAll
        }
    }
}

public protocol DataSourceContainerProtocol { }

public class DataSourceContainer<ResultType>: DataSourceContainerProtocol {
    
    // MARK: Initializer
    
    init(delegate: DataSourceContainerDelegate? = nil) {
        self.delegate = delegate
    }

    // MARK: Delegate

    public weak var delegate: DataSourceContainerDelegate?

    // MARK: Methods for overriding in subclasses
    
    open var sections: [DataSourceSectionInfo]? {
        get {
            assertionFailure("Should be overriden in subclasses")
            return nil
        }
    }
    
    open var fetchedObjects: [ResultType]? {
        get {
            assertionFailure("Should be overriden in subclasses")
            return nil
        }
    }

    open var hasData: Bool {
        get {
            if let fetchedObjects = fetchedObjects {
                return fetchedObjects.count > 0
            }
            return false
        }
    }

    open func object(at indexPath: IndexPath) -> ResultType? {
        assertionFailure("Should be overriden in subclasses")
        return nil
    }
    
    open func indexPath(for object: ResultType) -> IndexPath? {
        assertionFailure("Should be overriden in subclasses")
        return nil
    }

    open func numberOfSections() -> Int? {
        assertionFailure("Should be overriden in subclasses")
        return nil
    }
    
    open func numberOfItems(in section: Int) -> Int? {
        assertionFailure("Should be overriden in subclasses")
        return nil
    }

    open func search(_ block:(IndexPath, ResultType) -> Bool) -> IndexPath? {
        fatalError("Should be overriden in subclasses")
    }

    open func enumerate(_ block:(IndexPath, ResultType) -> Void) {
        fatalError("Should be overriden in subclasses")
    }
}

// MARK: DataSourceContainerDelegate

public protocol DataSourceContainerDelegate: AnyObject {
    
    // MARK: - Optional

    func containerWillChangeContent(_ container: DataSourceContainerProtocol)
    
    func container(_ container: DataSourceContainerProtocol,
                   didChange anObject: Any,
                   at indexPath: IndexPath?,
                   for type: DataSourceObjectChangeType,
                   newIndexPath: IndexPath?)
    
    func container(_ container: DataSourceContainerProtocol,
                   didChange sectionInfo: DataSourceSectionInfo,
                   atSectionIndex sectionIndex: Int,
                   for type: DataSourceObjectChangeType)
    
    func container(_ container: DataSourceContainerProtocol,
                   sectionIndexTitleForSectionName sectionName: String) -> String?
    
    // MARK: - Required
    
    func containerDidChangeContent(_ container: DataSourceContainerProtocol)

}

public extension DataSourceContainerDelegate {
    func containerWillChangeContent(_ container: DataSourceContainerProtocol) { }
    
    func container(_ container: DataSourceContainerProtocol,
                   didChange anObject: Any,
                   at indexPath: IndexPath?,
                   for type: DataSourceObjectChangeType,
                   newIndexPath: IndexPath?) { }
    
    func container(_ container: DataSourceContainerProtocol,
                   didChange sectionInfo: DataSourceSectionInfo,
                   atSectionIndex sectionIndex: Int,
                   for type: DataSourceObjectChangeType) { }
    
    func container(_ container: DataSourceContainerProtocol,
                   sectionIndexTitleForSectionName sectionName: String) -> String? { return nil }

}
#endif
