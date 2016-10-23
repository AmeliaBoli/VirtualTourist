//
//  PinLocation+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by Amelia Boli on 10/22/16.
//  Copyright © 2016 Appogenic. All rights reserved.
//

import Foundation
import CoreData


extension PinLocation {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PinLocation> {
        return NSFetchRequest<PinLocation>(entityName: "PinLocation");
    }

    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double

}
