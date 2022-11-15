//
//  MapViewDataSource.swift
//  launchOptions
//
//  Created by Aleksey Bakhtin on 12/20/17.
//  Copyright © 2018 launchOptions. All rights reserved.
//

#if os(iOS)
import UIKit
import MapKit

open class MapViewDataSource<ObjectType>: NSObject, DataSource, MKMapViewDelegate, DataSourceContainerDelegate where ObjectType: MKAnnotation {
    
    // MARK: - Initializer
    
    public init(mapView: MKMapView? = nil,
                annotationViewClass: AnyClass? = nil,
                container: DataSourceContainer<ObjectType>? = nil,
                delegate: AnyMapViewDataSourceDelegate<ObjectType>? = nil) {
        self.container = container
        self.delegate = delegate
        self.mapView = mapView
        self.annotationViewClass = annotationViewClass
        super.init()
    }
    
    // MARK: - Public properties

    public var mapView: MKMapView? {
        didSet {
            mapView?.delegate = self
            reloadAnnotations()
        }
    }

    public var annotationViewClass: AnyClass?
    public var delegate: AnyMapViewDataSourceDelegate<ObjectType>?

    open func showAnnotations(_ objects: [ObjectType]) {
        mapView?.showAnnotations(objects, animated: true)
    }
    
    open func addAnnotations(_ objects: [ObjectType]) {
        mapView?.addAnnotations(objects)
    }

    // MARK: - DataSource implementation
    
    public var container: DataSourceContainer<ObjectType>? {
        didSet {
            container?.delegate = self
            reloadAnnotations()
        }
    }
    
    public var noDataView: UIView? {
        didSet {
            showNoDataViewIfNeeded()
        }
    }
    
    open func setNoDataView(hidden: Bool) {
        guard let noDataView = noDataView, let mapView = mapView else {
            return
        }
        
        mapView.addSubview(noDataView)
        noDataView.isHidden = hidden
        if let superview = noDataView.superview {
            noDataView.centerXAnchor.constraint(equalTo: superview.centerXAnchor).isActive = true
            noDataView.centerYAnchor.constraint(equalTo: superview.centerYAnchor).isActive = true
            noDataView.leftAnchor.constraint(equalTo: superview.leftAnchor).isActive = true
            noDataView.rightAnchor.constraint(equalTo: superview.rightAnchor).isActive = true
            noDataView.topAnchor.constraint(equalTo: superview.topAnchor).isActive = true
            noDataView.bottomAnchor.constraint(equalTo: superview.bottomAnchor).isActive = true
        }
    }
    
    //Not implemented
    public var refreshingView: UIView?
    
    public func invertExpanding(at indexPath: IndexPath) {
        fatalError()
    }
    
    // MARK: - Private
    
    private func reloadAnnotations() {
        guard mapView != nil,
            let container = container,
            annotationViewClass != nil else {
            return;
        }

        if let objects = container.fetchedObjects {
            addAnnotations(objects)
            showAnnotations(objects)
        }
    }
    
    // MARK: - Container delegate
    
    open func containerWillChangeContent(_ container: DataSourceContainerProtocol) {
        if let mapView = mapView {
            mapView.removeAnnotations(mapView.annotations)
        }
        reloadAnnotations()
    }
    
    open func container(_ container: DataSourceContainerProtocol, didChange anObject: Any, at indexPath: IndexPath?, for type: DataSourceObjectChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            if let annotation = anObject as? MKAnnotation {
                mapView?.addAnnotation(annotation)
            }
        case .delete:
            if let annotation = anObject as? MKAnnotation {
                mapView?.removeAnnotation(annotation)
            }
        case .reloadAll:
            reloadAnnotations()
        case .move, .update, .reload:
            if let annotation = anObject as? MKAnnotation {
                mapView?.removeAnnotation(annotation)
                mapView?.addAnnotation(annotation)
            }
        }
    }
    
    open func container(_ container: DataSourceContainerProtocol, didChange sectionInfo: DataSourceSectionInfo, atSectionIndex sectionIndex: Int, for type: DataSourceObjectChangeType) {
        switch type {
        case .insert:
            if let annotations = sectionInfo.objects as? [MKAnnotation] {
                mapView?.addAnnotations(annotations)
            }
        case .delete:
            if let annotations = sectionInfo.objects as? [MKAnnotation] {
                mapView?.removeAnnotations(annotations)
            }
        case .move, .update, .reload, .reloadAll:
            reloadAnnotations()
        }
    }
    
    open func container(_ container: DataSourceContainerProtocol, sectionIndexTitleForSectionName sectionName: String) -> String? {
        fatalError("You can't use this delegate method with MapViewDataSource")
    }
    
    open func containerDidChangeContent(_ container: DataSourceContainerProtocol) {
        showNoDataViewIfNeeded()
    }
    
    // MARK: - MKMapViewDelegate
    
    public func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        guard let annotation = view.annotation as? ObjectType else { return }
        delegate?.dataSource(self, didSelect: annotation)
    }
    
}
#endif
