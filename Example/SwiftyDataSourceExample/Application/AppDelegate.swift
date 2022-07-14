//
//  AppDelegate.swift
//  MapsDataSourceTest
//
//  Created by Dima Shelkov on 3/26/20.
//  Copyright © 2020 Dima Shelkov. All rights reserved.
//

import UIKit
import CoreData
//import GoogleMaps

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // get your own api key from https://developers.google.com/maps/documentation/ios-sdk/start
//        GMSServices.provideAPIKey("AIzaSyAkcDB6xqDH6_j-N5DsheaWElEzqQt7EMM")

        var car = NSEntityDescription.insertNewObject(forEntityName: "Car", into: container.viewContext) as! Car
        var car2 = NSEntityDescription.insertNewObject(forEntityName: "Car", into: container.viewContext) as! Car

        observer.observe(object: car) { object, state in
            print("changed \(car.id)")
        }
        
        car.id = 1
        try! container.viewContext.save()

        let objectId = car.objectID
        let context = container.newBackgroundContext()
        context.perform {
            let carInContext = context.object(with: objectId) as! Car
            carInContext.id = 2
            try! context.save()
        }
        return true
    }

    lazy var observer = CoreDataContextObserver(context: container.viewContext)


    let container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Model")
        container.loadPersistentStores { description, error in
            print(description)
            print(error as Any)
        }
        return container
    }()
}

