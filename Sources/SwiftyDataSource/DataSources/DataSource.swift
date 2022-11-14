//
//  DataSource.swift
//  DPDataStorage
//
//  Created by Alexey Bakhtin on 10/19/17.
//  Copyright © 2018 launchOptions. All rights reserved.
//

#if os(iOS)
import UIKit

public protocol DataSourceConfigurable {
    func configure(with object: Any)
}

public protocol DataSourceProtocol {
}

public protocol DataSource: DataSourceProtocol {
    associatedtype ObjectType
    
    var container: DataSourceContainer<ObjectType>? { get set }
    var hasData: Bool { get }
    var numberOfSections: Int? { get }
    var noDataView: UIView? { get set }
    var refreshingView: UIView? { get set }
    var isRefreshing: Bool { get set }
    
    func numberOfItems(in section: Int) -> Int?
    func object(at indexPath: IndexPath) -> ObjectType?
    func showNoDataViewIfNeeded()
    func setNoDataView(hidden: Bool)

    func invertExpanding(at indexPath: IndexPath)
}

extension DataSource {
    
    public var hasData: Bool {
        guard let container = container else { return false }
        return container.hasData
    }
    
    public var numberOfSections: Int? {
        return container?.numberOfSections()
    }
    
    public func numberOfItems(in section: Int) -> Int? {
        return container?.numberOfItems(in: section)
    }
    
    public func object(at indexPath: IndexPath) -> ObjectType? {
        return container?.object(at: indexPath)
    }
    
    public func sectionInfo(at index: Int) -> DataSourceSectionInfo? {
        return container?.sections?[index]
    }
    
    public mutating func beginRefreshing() {
        isRefreshing = true
        showNoDataViewIfNeeded()
    }
    
    public func showNoDataViewIfNeeded() {
        setNoDataView(hidden: hasData)
    }
    
    public func setNoDataView(hidden: Bool, containerView: HasBackgroundView?) {
        if hidden {
            setView(refreshingView, containerView: containerView, hidden: hidden)
            setView(noDataView, containerView: containerView, hidden: hidden)
        } else {
            let refreshingOrNoData = isRefreshing ? refreshingView : noDataView
            let anotherView = (refreshingOrNoData == refreshingView) ? noDataView : refreshingView
            setView(anotherView, containerView: containerView, hidden: true)
            setView(refreshingOrNoData, containerView: containerView, hidden: false)
        }
    }
    
    public func setView(_ viewToAdd: UIView?, containerView: HasBackgroundView?, hidden: Bool) {
        guard let containerView = containerView, let viewToAdd = viewToAdd else { return }
        
        // Library allows to handle NoDataView and Refreshing view in two ways
        // 1. Add viewToAdd in client code to any view and library makes its hidden and visibly automatically
        if viewToAdd.superview != nil && viewToAdd.superview != containerView.backgroundView {
            viewToAdd.isHidden = hidden
            viewToAdd.superview?.bringSubviewToFront(viewToAdd)
            return
        }
        
        // 2. If viewToAdd is not added to another view it will be added to background view of collection view
        // Somewhy we need to create background view to add it. If set view as background view it will be twitched on refresh animation
        if viewToAdd.superview == nil && hidden == false {
            viewToAdd.translatesAutoresizingMaskIntoConstraints = false
            containerView.backgroundView = UIView(frame: containerView.bounds)
            containerView.backgroundView?.addSubview(viewToAdd)
            
            if let superview = viewToAdd.superview {
                viewToAdd.leftAnchor.constraint(equalTo: superview.leftAnchor).isActive = true
                viewToAdd.rightAnchor.constraint(equalTo: superview.rightAnchor).isActive = true
                viewToAdd.topAnchor.constraint(equalTo: superview.topAnchor).isActive = true
                viewToAdd.bottomAnchor.constraint(equalTo: superview.bottomAnchor).isActive = true
            }
        } else if viewToAdd.superview != nil && hidden == true {
            if viewToAdd == containerView.backgroundView {
                containerView.backgroundView = nil
            } else {
                viewToAdd.removeFromSuperview()
            }
        }
    }
    
}
#endif
