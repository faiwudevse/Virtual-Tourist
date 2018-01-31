//
//  Photo+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by Fai Wu on 11/27/17.
//  Copyright © 2017 Fai Wu. All rights reserved.
//
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo")
    }

    @NSManaged public var image: NSData?
    @NSManaged public var name: String?
    @NSManaged public var url: String?
    @NSManaged public var pin: Pin?

}
