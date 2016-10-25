//
//  FlickrStats+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by Amelia Boli on 10/24/16.
//  Copyright © 2016 Appogenic. All rights reserved.
//

import Foundation
import CoreData

extension FlickrStats {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FlickrStats> {
        return NSFetchRequest<FlickrStats>(entityName: "FlickrStats");
    }

    @NSManaged public var totalImages: Int16
    @NSManaged public var currentPage: Int16
    @NSManaged public var pinLocation: PinLocation?

}
