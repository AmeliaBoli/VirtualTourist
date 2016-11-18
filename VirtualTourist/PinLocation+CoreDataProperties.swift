//
//  PinLocation+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by Amelia Boli on 11/13/16.
//  Copyright © 2016 Appogenic. All rights reserved.
//

import Foundation
import CoreData


extension PinLocation {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PinLocation> {
        return NSFetchRequest<PinLocation>(entityName: "PinLocation");
    }

    @NSManaged public var flickrPlaceId: String?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var flickrStats: FlickrStats?
    @NSManaged public var photo: NSSet?

}

// MARK: Generated accessors for photo
extension PinLocation {

    @objc(addPhotoObject:)
    @NSManaged public func addToPhoto(_ value: Photo)

    @objc(removePhotoObject:)
    @NSManaged public func removeFromPhoto(_ value: Photo)

    @objc(addPhoto:)
    @NSManaged public func addToPhoto(_ values: NSSet)

    @objc(removePhoto:)
    @NSManaged public func removeFromPhoto(_ values: NSSet)

}
