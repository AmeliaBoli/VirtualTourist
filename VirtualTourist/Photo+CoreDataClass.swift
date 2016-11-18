//
//  Photo+CoreDataClass.swift
//  VirtualTourist
//
//  Created by Amelia Boli on 11/5/16.
//  Copyright © 2016 Appogenic. All rights reserved.
//  This file was automatically generated and should not be edited.
//

import UIKit
import CoreData


public class Photo: NSManagedObject {

    convenience init(photoId: Int64?, url: String, context: NSManagedObjectContext) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            let stack = appDelegate.stack else {
                fatalError("Photo: init: The App Delegate or stack could not be found")
        }

        let context = stack.context

        if let entity = NSEntityDescription.entity(forEntityName: "Photo", in: context) {
            self.init(entity: entity, insertInto: context)
            self.photoId = photoId
            self.url = url
        } else {
            fatalError("A Photo could not be created")
        }
    }
}
