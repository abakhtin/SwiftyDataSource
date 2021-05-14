//
//  CollectionViewDataSource.swift
//  DPDataStorage
//
//  Created by Alexey Bakhtin on 12/19/17.
//  Copyright © 2018 launchOptions. All rights reserved.
//

#if os(iOS)
import UIKit

open class CollectionViewDataSource<ObjectType>: NSObject, DataSource, UICollectionViewDataSource, UICollectionViewDelegate {
    
    // MARK: Initializer
    
    public init(collectionView: UICollectionView? = nil,
                container: DataSourceContainer<ObjectType>? = nil,
                delegate: AnyCollectionViewDataSourceDelegate<ObjectType>? = nil,
                cellIdentifier: String? = nil,
                headerIdentifier: String? = nil) {
        self.collectionView = collectionView
        self.delegate = delegate
        self.cellIdentifier = cellIdentifier
        self.headerIdentifier = headerIdentifier
        self.container = container
        super.init()
        self.collectionView?.dataSource = self
        self.collectionView?.delegate = self
        self.container?.delegate = self
    }

    // MARK: Public properties
    
    public var container: DataSourceContainer<ObjectType>? {
        didSet {
            container?.delegate = self
            collectionView?.reloadData()
        }
    }

    public var collectionView: UICollectionView? {
        didSet {
            self.collectionView?.dataSource = self
            self.collectionView?.delegate = self
        }
    }
    
    public var cellIdentifier: String? {
        didSet {
            self.collectionView?.reloadData()
        }
    }
    
    public var headerIdentifier: String? {
        didSet {
            self.collectionView?.reloadData()
        }
    }
    
    public var delegate: AnyCollectionViewDataSourceDelegate<ObjectType>?

    // MARK: Implementing of datasource methods
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        guard let numberOfSections = numberOfSections else {
            return 0
        }
        return numberOfSections
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let numberOfItems = numberOfItems(in: section) else {
            return 0
        }
        return numberOfItems
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let object = object(at: indexPath) else {
            fatalError("Could not retrieve object at \(indexPath)")
        }
        let cellIdentifier = delegate?.dataSource(self, cellIdentifierFor: object, at: indexPath) ?? self.cellIdentifier
        guard let identifier = cellIdentifier else {
            fatalError("Cell identifier is empty")
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) 
        guard let configurableCell = cell as? DataSourceConfigurable else {
            fatalError("Cell is not implementing DataSourceConfigurable protocol")
        }
        configurableCell.configure(with: object)
        return cell
    }
    
    // MARK: NoDataView processing
    
    public var noDataView: UIView?
    
    open func setNoDataView(hidden: Bool) {
        guard let _ = noDataView, let _ = collectionView else {
            return
        }
        fatalError("Not implemented")
    }

    public func invertExpanding(at indexPath: IndexPath) {
        fatalError("Not implemented")
    }
    
    // MARK: Selection
    
    open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let object = object(at: indexPath) else { return }
        self.delegate?.dataSource(self, didSelect: object, at: indexPath)
    }
    open func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard let object = object(at: indexPath) else { return }
        self.delegate?.dataSource(self, didDeselect: object, at: indexPath)
    }
    
    // MARK: Header
    
    open func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let identifier = headerIdentifier, let sectionInfo = sectionInfo(at: indexPath.section) else {
            return UICollectionReusableView()
        }
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: identifier, for: indexPath)
        
        guard let configurableView = view as? DataSourceConfigurable else {
            fatalError("\(identifier) is not implementing DataSourceConfigurable protocol")
        }
        configurableView.configure(with: sectionInfo)
        return view
    }
    
    private var blockOperations: [BlockOperation] = []

}

extension CollectionViewDataSource: DataSourceContainerDelegate {
    
    public func containerWillChangeContent(_ container: DataSourceContainerProtocol) {
        blockOperations.removeAll(keepingCapacity: false)
    }
    
    public func container(_ container: DataSourceContainerProtocol, didChange sectionInfo: DataSourceSectionInfo, atSectionIndex sectionIndex: Int, for type: DataSourceObjectChangeType) {
        switch (type) {
        case .insert:
            // iOS bug workaround https://stackoverflow.com/questions/19199985/invalid-update-invalid-number-of-items-on-uicollectionview
            if (self.collectionView?.numberOfSections == 0) {
                self.collectionView?.reloadData()
            } else {
                blockOperations.append(BlockOperation { self.collectionView?.insertSections(IndexSet(integer: sectionIndex)) })
            }
        case .delete:
            blockOperations.append(BlockOperation { self.collectionView?.deleteSections(IndexSet(integer: sectionIndex)) })
        case .update: fallthrough
        case .reload:
            blockOperations.append(BlockOperation { self.collectionView?.reloadSections(IndexSet(integer: sectionIndex)) })
        case .move: fallthrough
        case .reloadAll:
            blockOperations.append(BlockOperation { self.collectionView?.reloadData() })
        }
    }
    
    public func container(_ container: DataSourceContainerProtocol, didChange anObject: Any, at indexPath: IndexPath?, for type: DataSourceObjectChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            if let newIndexPath = newIndexPath {
                // iOS bug workaround https://stackoverflow.com/questions/19199985/invalid-update-invalid-number-of-items-on-uicollectionview
                if (self.collectionView?.numberOfSections == 0) {
                    self.collectionView?.reloadData()
                } else {
                    blockOperations.append(BlockOperation { self.collectionView?.insertItems(at: [newIndexPath]) })
                }
            }
        case .delete:
            if let indexPath = indexPath {
                blockOperations.append(BlockOperation { self.collectionView?.deleteItems(at: [indexPath]) })
            }
        case .move:
            if let indexPath = indexPath, let newIndexPath = newIndexPath {
                blockOperations.append(BlockOperation { self.collectionView?.moveItem(at: indexPath, to: newIndexPath) })
            }
        case .update:
            if let indexPath = indexPath, let cell = collectionView?.cellForItem(at: indexPath) as? DataSourceConfigurable, let object = object(at: indexPath) {
                cell.configure(with: object)
            }
          
        case .reload:
            if let indexPath = indexPath {
                blockOperations.append(BlockOperation { self.collectionView?.reloadItems(at: [indexPath]) })
            }
        case .reloadAll:
            collectionView?.reloadData()
        }
    }
    
    public func containerDidChangeContent(_ container: DataSourceContainerProtocol) {
        self.collectionView?.performBatchUpdates({
            self.blockOperations.forEach { $0.start() }
        }, completion: { finished in
            self.blockOperations.removeAll(keepingCapacity: false)
        })
        showNoDataViewIfNeeded()
    }
  
}
#endif
