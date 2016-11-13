//
//  FlickrStats+CoreDataClass.swift
//  VirtualTourist
//
//  Created by Amelia Boli on 10/24/16.
//  Copyright © 2016 Appogenic. All rights reserved.
//

import UIKit
import CoreData


public class FlickrStats: NSManagedObject {
    convenience init(context: NSManagedObjectContext) {

        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            let stack = appDelegate.stack else {
                fatalError("PinLocation: init: The App Delegate or stack could not be found")
        }

        let context = stack.context

        if let entity = NSEntityDescription.entity(forEntityName: "FlickrStats", in: context) {
            self.init(entity: entity, insertInto: context)
            self.totalImages = 0
            self.currentPage = 0
        } else {
            fatalError("A FlickrStats could not be created")
        }
    }

}
