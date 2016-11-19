//
//  Photo+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by Amelia Boli on 11/17/16.
//  Copyright © 2016 Appogenic. All rights reserved.
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo");
    }

    @NSManaged public var image: NSData?

    // Code for a accessors is from this StackOverflow post: http://stackoverflow.com/a/30651343/4480290
    public var photoId: Int64? {
        get {
            self.willAccessValue(forKey: "photoId")
            let value = self.primitiveValue(forKey: "photoId") as? Int64
            self.didAccessValue(forKey: "photoId")

            return (value != nil) ? value! : nil
        }
        set {
            self.willChangeValue(forKey: "photoId")

            let value : Int64? = (newValue != nil) ? newValue! : nil
            self.setPrimitiveValue(value, forKey: "photoId")

            self.didChangeValue(forKey: "photoId")
        }
    }

    @NSManaged public var url: String?
    @NSManaged public var isSelected: Bool
    @NSManaged public var pinLocation: PinLocation?
    @NSManaged public var dateUpload: Date

}
