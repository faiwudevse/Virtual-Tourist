//
//  Photo+CoreDataClass.swift
//  VirtualTourist
//
//  Created by Fai Wu on 11/27/17.
//  Copyright © 2017 Fai Wu. All rights reserved.
//
//

import Foundation
import CoreData

public class Photo: NSManagedObject {
    convenience init(url: String, name: String, context: NSManagedObjectContext){
        // An EntityDescription is an object that has access to all
        // the information you provided in the Entity part of the model
        // you need it to create an instance of this class.
        if let ent = NSEntityDescription.entity(forEntityName: "Photo", in: context){
            self.init(entity: ent, insertInto: context)
            self.url = url
            self.image = nil
            self.name = name
        }else{
            fatalError("Unable to find Entity name!")
        }
    }
    convenience init(url: String, name: String, image: NSData, context: NSManagedObjectContext){
        // An EntityDescription is an object that has access to all
        // the information you provided in the Entity part of the model
        // you need it to create an instance of this class.
        if let ent = NSEntityDescription.entity(forEntityName: "Photo", in: context){
            self.init(entity: ent, insertInto: context)
            self.url = url
            self.image = image 
            self.name = name
        }else{
            fatalError("Unable to find Entity name!")
        }
    }
}
