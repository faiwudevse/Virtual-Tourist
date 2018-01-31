//
//  File.swift
//  VirtualTourist
//
//  Created by Fai Wu on 11/23/17.
//  Copyright © 2017 Fai Wu. All rights reserved.
//

import UIKit
import MapKit
import CoreData
import Foundation

class PhotoAlbumViewController: UIViewController {
    
    // MARK Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var toolbarButton: UIBarButtonItem!    
    @IBOutlet weak var collectionFlowLayout: UICollectionViewFlowLayout!
    
    // MARK: Properties
    var cnt = 0
    var pin : Pin? 
    var insertedIndexPaths: [IndexPath]!
    var deletedIndexPaths: [IndexPath]!
    var updatedIndexPaths: [IndexPath]!
    let stack = (UIApplication.shared.delegate as! AppDelegate).stack
    var selectedIndexPathes: Set<IndexPath> = []
    var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult>? {
        didSet {
            // Whenever the frc changes, we execute the search and
            // reload the table
            fetchedResultsController?.delegate = self
            executeSearch()
            collectionView?.reloadData()
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureLayout()
        
        mapView.delegate = self
        
        setMapRegion()
        
        // Get the stack
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let stack = delegate.stack
        
        
        // Create a fetchrequest
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        fr.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        fr.predicate = NSPredicate(format: "pin = %@", argumentArray: [self.pin!])
        
        // Create the FetchedResultsController
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if fetchedResultsController?.fetchedObjects?.count == 0 {
            getNewPhotos()
        }
    }
    
    // configure the flowlayout for each item
    func configureLayout(){
        let space: CGFloat  = 2.0
        let dimensionWidth = (self.view.frame.size.width - (2 * space)) / 3.0
        let dimensionHeight = (self.view.frame.size.height - (2 * space)) / 6.0

        collectionFlowLayout.minimumLineSpacing = space
        collectionFlowLayout.minimumInteritemSpacing = space
        collectionFlowLayout.itemSize = CGSize(width: dimensionWidth, height: dimensionHeight)
    }
    
    
    func executeSearch() {
        if let fc = fetchedResultsController {
            do {
                try fc.performFetch()
            } catch let e as NSError {
                print("Error while trying to perform a search: \n\(e)\n\(String(describing: fetchedResultsController))")
            }
        }
    }
    // MARK: toolbar button
    @IBAction func toolbarButtonPressed(_ sender: Any) {
        
        if toolbarButton.title == "New Collection" {
            deleteAllPhotos()
            getNewPhotos()
        }
        else if toolbarButton.title == "Remove" {
            selectDeletePhotos()
        }
        
        checkSelectedIndexPathsIsEmpty()
    }
    
    func getNewPhotos(){
        cnt = 0
        toolbarButton.isEnabled = false
        Client.sharedInstance().searchPhotosByCoordinate((pin?.coordinate.latitude)!, (pin?.coordinate.longitude)!){(photosInfo, error) in
            guard let photosInfo = photosInfo else {
                return
            }
            self.stack.performBackgroundBatchOperation() { (workerContext) in
                for photoInfo in photosInfo{
                    let photo = Photo(url: photoInfo[0], name: photoInfo[1], context: (self.fetchedResultsController?.managedObjectContext)!)
                    photo.pin = self.pin
                }
            }
        }
    }
    
    func deleteAllPhotos(){
        toolbarButton.isEnabled = false
        if let photos = fetchedResultsController?.fetchedObjects as? [Photo] {
            for photo in photos {
                self.stack.context.delete(photo)
            }
            self.stack.save()
        }
    }
    
    func selectDeletePhotos(){
        
        for index in selectedIndexPathes{
            let photo = fetchedResultsController!.object(at: index) as! Photo
            selectedIndexPathes.remove(index)
            self.stack.context.delete(photo)
            
        }
        self.stack.save()
    }
    
    func checkSelectedIndexPathsIsEmpty(){
        if selectedIndexPathes.isEmpty {
            toolbarButton.title = "New Collection"
        }
        else{
            toolbarButton.title = "Remove"
        }
    }
    
}

extension PhotoAlbumViewController: MKMapViewDelegate {
    
    func setMapRegion(){
        let coordinates:CLLocationCoordinate2D = pin!.coordinate
        let span:MKCoordinateSpan = MKCoordinateSpanMake(1 , 1)
        let region:MKCoordinateRegion = MKCoordinateRegionMake(coordinates, span)
        let pointAnnotation:MKPointAnnotation = MKPointAnnotation()
        pointAnnotation.coordinate = coordinates
        self.mapView.addAnnotation(pointAnnotation)
        self.mapView.centerCoordinate = coordinates
        self.mapView.setRegion(region, animated: true)
        self.mapView.selectAnnotation(pointAnnotation, animated: true)
    }
    
    // MARK: - MKMapViewDelegate
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = .red
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
}

extension PhotoAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource{
    
    // Mark collection view data source and cell configuration
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if let fc = fetchedResultsController {
            return fc.sections![section].numberOfObjects
        } else {
            return 0
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let photo = fetchedResultsController!.object(at: indexPath) as! Photo
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionViewCell", for: indexPath) as! PhotoCollectionViewCell
        
        if photo.image == nil {
            
            Client.sharedInstance().downloadImageFromUrl(photo.url!){(data, error) in
                guard let data = data else {
                    return
                }
                self.stack.performBackgroundBatchOperation() {(workerContext) in
                    photo.image = data
                }
                DispatchQueue.main.async {
                    self.cnt += 1
                    cell.imageView.image = UIImage(data:data as Data)
                    cell.activityIndicator.stopAnimating()
                    if self.cnt == 12 {
                        self.toolbarButton.isEnabled = true
                    }
                }
            }
        } else {
            cell.imageView.image = UIImage(data: (photo.image as Data?)!)
            cell.activityIndicator.stopAnimating()

        }
        
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedCell = collectionView.cellForItem(at: indexPath) as! PhotoCollectionViewCell
        if selectedIndexPathes.contains(indexPath) {
            selectedIndexPathes.remove(indexPath)
            selectedCell.alpha = 1.0
        }
        else{
            selectedIndexPathes.insert(indexPath)
            selectedCell.alpha = 0.5
        }
        checkSelectedIndexPathsIsEmpty()
    }
}

// MARK: - CoreDataCollectionViewController: NSFetchedResultsControllerDelegate
extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        insertedIndexPaths = []
        deletedIndexPaths = []
        updatedIndexPaths = []
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            insertedIndexPaths.append(newIndexPath!)
        case.update:
            updatedIndexPaths.append(indexPath!)
 
        case .delete:
            deletedIndexPaths.append(indexPath!)

        default:
            break
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView?.performBatchUpdates({
            for indexPath in self.insertedIndexPaths {
                collectionView?.insertItems(at:[indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                collectionView?.reloadItems(at: [indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                collectionView?.deleteItems(at:[indexPath])
            }
        }, completion: nil)
    }

}

