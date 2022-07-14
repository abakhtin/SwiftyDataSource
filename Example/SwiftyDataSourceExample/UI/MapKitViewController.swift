//
//  MapKitViewController.swift
//  MapsDataSourceTest
//
//  Created by Dima Shelkov on 3/26/20.
//  Copyright © 2020 Dima Shelkov. All rights reserved.
//

import UIKit
import MapKit

class MapKitViewController: UIViewController, MapViewDataSourceDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    let noDataView: NoDataView = NoDataView.fromNib()
    var testMark = TestMark(coordinate: CLLocationCoordinate2D(latitude: 53.89, longitude: 27.57), title: "Test")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dataContainer.delegate = dataSource
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        testMark = TestMark(coordinate: CLLocationCoordinate2D(latitude: 40.89, longitude: 20.57), title: "Test")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
//        dataContainer.add(sectionObjects: [testMark])
//        dataContainer.removeAll()
//        try? dataContainer.replace(sectionObjects: [testMark], at: 0)
    }
    
    typealias ObjectType = TestMark
    
    private let dataContainer = ArrayDataSourceContainer<TestMark>()
    
    private lazy var dataSource: MapViewDataSource<TestMark> = {
        let dataSource = MapViewDataSource<TestMark>(mapView: mapView,
                                                     annotationViewClass: MKAnnotationView.self,
                                                     container: dataContainer,
                                                     delegate: AnyMapViewDataSourceDelegate(self))
        dataSource.noDataView = noDataView
        return dataSource
    }()
}
