//
//  PinLocation+CoreDataClass.swift
//  VirtualTourist
//
//  Created by Amelia Boli on 10/22/16.
//  Copyright © 2016 Appogenic. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation

public class PinLocation: NSManagedObject {

    convenience init(coordinate: CLLocationCoordinate2D, context: NSManagedObjectContext) {

        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            let stack = appDelegate.stack else {
                fatalError("PinLocation: init: The App Delegate or stack could not be found")
        }

        let context = stack.context

        if let entity = NSEntityDescription.entity(forEntityName: "PinLocation", in: context) {
            self.init(entity: entity, insertInto: context)
            self.latitude = coordinate.latitude
            self.longitude = coordinate.longitude
            self.flickrStats = FlickrStats(context: context)
        } else {
            fatalError("A PinLocation could not be created")
        }
    }

    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
    }
}
