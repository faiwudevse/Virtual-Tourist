//
//  Pin+CoreDataClass.swift
//  VirtualTourist
//
//  Created by Fai Wu on 11/27/17.
//  Copyright © 2017 Fai Wu. All rights reserved.
//
//

import Foundation
import CoreData
import MapKit

public class Pin: NSManagedObject, MKAnnotation {
    public var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2DMake(latitude , longitude )
    }
    
    convenience init(latitude: Double, longitude: Double,  context : NSManagedObjectContext){
        
        // An EntityDescription is an object that has access to all
        // the information you provided in the Entity part of the model
        // you need it to create an instance of this class.
        if let ent = NSEntityDescription.entity(forEntityName: "Pin", in: context){
            self.init(entity: ent, insertInto: context)
            self.latitude = latitude
            self.longitude = longitude
        }else{
            fatalError("Unable to find Entity name!")
        }
        
    }
    
}
