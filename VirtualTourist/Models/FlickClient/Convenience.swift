//
//  Convenience.swift
//  VirtualTourist
//
//  Created by Fai Wu on 11/25/17.
//  Copyright © 2017 Fai Wu. All rights reserved.
//

import Foundation
import UIKit

extension Client {
    func downloadNewPhotos(_ latitude: Double, _ longitude: Double, _ pin: Pin, _ completionHandlerFordownloadNewPhotos: @escaping (_ result: Bool, _ error: String?) -> Void ){
        let parameters = [Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod,
                          Constants.FlickrParameterKeys.BoundingBox: bboxString(latitude, longitude),
                          Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
                          Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey,
                          Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback,
                          Constants.FlickrParameterKeys.PerPage: Constants.FlickrParameterValues.PhotosPerPage,
                          Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL,
                          Constants.FlickrParameterKeys.Page: "\(arc4random_uniform(50))"]
        let _ = taskForGetMethod(parameters as [String: AnyObject]) { (result, error) in
            
            
            if let error = error {
                completionHandlerFordownloadNewPhotos(false, error.localizedDescription)
            }else{
                guard let photosDictionary = result![Constants.FlickrResponseKeys.Photos] as? [String: AnyObject] else {
                    completionHandlerFordownloadNewPhotos(false, "Cannot find keys '\(Constants.FlickrResponseKeys.Photos)'")
                    return
                }
                guard let photosArray = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String: AnyObject]] else {
                    completionHandlerFordownloadNewPhotos(false, "Cannot find keys '\(Constants.FlickrResponseKeys.Photo)'")
                    return
                }
                var itemsCnt = 0
                for photo in photosArray {
                    guard let photoURL = photo[Constants.FlickrResponseKeys.MediumURL] as? String else {
                        completionHandlerFordownloadNewPhotos(false, "Cannot find keys '\(Constants.FlickrResponseKeys.MediumURL)'")
                        return
                    }
                    
                    guard let photoTitle = photo[Constants.FlickrResponseKeys.Title] as? String else {
                        completionHandlerFordownloadNewPhotos(false, "Cannot find keys '\(Constants.FlickrResponseKeys.Title)'")
                        return
                    }
                    self.downloadImageFromUrl(photoURL){ (data,error) in
                        guard let data = data else {
                             completionHandlerFordownloadNewPhotos(false, "Cannot download this url '\(photoURL)'")
                            return
                        }
                        if error != nil{
                            completionHandlerFordownloadNewPhotos(false, error)
                        }
                        self.stack.performBackgroundBatchOperation() { (workerContext) in
                            let photo = Photo(url: photoURL, name: photoTitle, image: data, context: self.stack.context)
                                photo.pin = pin
                            self.stack.save()
                            itemsCnt += 1
                            if itemsCnt == photosArray.count{
                                completionHandlerFordownloadNewPhotos(true, nil)
                            }
                        }
                    }
                }
            }
            
        }
    }
    func searchPhotosByCoordinate(_ latitude: Double, _ longitude: Double, _ completionHandlerForSearchPhotosByCoordinate: @escaping (_ photosInfo: [[String]]?, _ error: String?) -> Void ){
        let parameters = [Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod,
                          Constants.FlickrParameterKeys.BoundingBox: bboxString(latitude, longitude),
                          Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
                          Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey,
                          Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback,
                          Constants.FlickrParameterKeys.PerPage: Constants.FlickrParameterValues.PhotosPerPage,
                          Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL,
                          Constants.FlickrParameterKeys.Page: "\(arc4random_uniform(50))"]
        let _ = taskForGetMethod(parameters as [String: AnyObject]) { (result, error) in
            
            
            if let error = error {
                completionHandlerForSearchPhotosByCoordinate(nil, error.localizedDescription)
            }else{
                guard let photosDictionary = result![Constants.FlickrResponseKeys.Photos] as? [String: AnyObject] else {
                    completionHandlerForSearchPhotosByCoordinate(nil, "Cannot find keys '\(Constants.FlickrResponseKeys.Photos)'")
                    return
                }
                guard let photosArray = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String: AnyObject]] else {
                    completionHandlerForSearchPhotosByCoordinate(nil, "Cannot find keys '\(Constants.FlickrResponseKeys.Photo)'")
                    return
                }
                var photosInfo = [[String]]()
                
                for photo in photosArray {
                    guard let photoURL = photo[Constants.FlickrResponseKeys.MediumURL] as? String else {
                        completionHandlerForSearchPhotosByCoordinate(nil, "Cannot find keys '\(Constants.FlickrResponseKeys.MediumURL)'")
                        return
                    }
                    
                    guard let photoTitle = photo[Constants.FlickrResponseKeys.Title] as? String else {
                        completionHandlerForSearchPhotosByCoordinate(nil, "Cannot find keys '\(Constants.FlickrResponseKeys.Title)'")
                        return
                    }
                    
                    var photoRowInfo = [String]()
                    photoRowInfo.append(photoURL)
                    photoRowInfo.append(photoTitle)
                    photosInfo.append(photoRowInfo)
                }
                completionHandlerForSearchPhotosByCoordinate(photosInfo, nil)
            }
            
        }
    }
    
    func downloadImageFromUrl(_ url: String, _ completionHandlerForDownloadImageFromUrl: @escaping (_ data: NSData?, _ error: String?) -> Void ){
        let url = URL(string: url)
        
        let task = session.dataTask(with: url!){ (data, response, error) in
            if error == nil{
                completionHandlerForDownloadImageFromUrl(data as NSData?, nil)
            } else{
                completionHandlerForDownloadImageFromUrl(nil, "Not able to download the image")
            }
        }
        
        task.resume()
    }
    
    
    private func bboxString(_ latidue: Double, _ longitude: Double) -> String{
        let maxLongitude = longitude + Constants.Flickr.SearchBBoxHalfWidth
        let minLongitude = longitude - Constants.Flickr.SearchBBoxHalfWidth
        let maxLatidue = latidue + Constants.Flickr.SearchBBoxHalfHeight
        let minLatidue = latidue - Constants.Flickr.SearchBBoxHalfHeight
        let bboxStringValues = "\(minLongitude),\(minLatidue),\(maxLongitude),\(maxLatidue)"
        return bboxStringValues
    }
}
