//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Fai Wu on 11/22/17.
//  Copyright © 2017 Fai Wu. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsMapViewController: UIViewController {
    
    // MARK: Outlooks
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    // MARK: Properties
    let stack = (UIApplication.shared.delegate as! AppDelegate).stack
    var lastPin : MKPointAnnotation?
    // MARK: Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
        // add long press gesure recoginzer to the map
        mapView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(self.addPin)))
        
        // Load the pins from context to map
        loadPins()
    }
    
    // MARK: Navigationbar button
    @IBAction func editPressed(_ sender: Any) {
        editButton.title = editButton.title == "Done" ? "Edit" : "Done"
        if editButton.title == "Done" {
            view.frame.origin.y -= 68
        }
        else {
            view.frame.origin.y = 0
        }
    }
    @objc func addPin(gesture: UIGestureRecognizer) {
        let touchPoint = gesture.location(in: mapView)
        let coordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        let pointAnnotation:MKPointAnnotation = MKPointAnnotation()
        pointAnnotation.coordinate = coordinate
        
        if editButton.title == "Edit"{
            if gesture.state == UIGestureRecognizerState.began {
                self.mapView.addAnnotation(pointAnnotation)
                lastPin = pointAnnotation
            }
            else if gesture.state == UIGestureRecognizerState.changed {
                if lastPin != nil {
                    self.mapView.removeAnnotation(lastPin!)
                    self.mapView.addAnnotation(pointAnnotation)
                    lastPin = pointAnnotation
                }
            }
            else if gesture.state == UIGestureRecognizerState.ended {
                self.mapView.removeAnnotation(lastPin!)
                lastPin = nil
                let annotation = Pin(latitude: pointAnnotation.coordinate.latitude, longitude: pointAnnotation.coordinate.longitude, context: stack.context)
                self.mapView.addAnnotation(annotation)
                stack.save()
            }
        }
    }
}

extension TravelLocationsMapViewController: MKMapViewDelegate {
    
    // perform
    func loadPins() {
        var pins = [Pin]()
        let pinsFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        
        do {
            pins =  try stack.context.fetch(pinsFetch) as! [Pin]
        }catch{
            fatalError("Failed to Load Pins")
        }
        
        mapView.addAnnotations(pins)
    }
    
    // set up the pin properties
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"

        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView

        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.pinTintColor = .red
        }
        else {
            pinView!.annotation = annotation
        }

        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let selectPin = view.annotation as! Pin
        
        if editButton.title == "Edit" {
            
            mapView.deselectAnnotation(selectPin, animated: false)
            
            let controller = storyboard?.instantiateViewController(withIdentifier: "PhotoAlbumViewController") as! PhotoAlbumViewController
            
            controller.pin = selectPin
            
            navigationController?.pushViewController(controller, animated: true)
        }
        else if editButton.title == "Done" {
            stack.context.delete(selectPin)
            stack.save()
            mapView.removeAnnotation(selectPin)
        }
        
    }
}

