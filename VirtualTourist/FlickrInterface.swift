//
//  FlickrInterface2.swift
//  VirtualTourist
//
//  Created by Amelia Boli on 11/3/16.
//  Copyright © 2016 Appogenic. All rights reserved.
//

import Foundation
import MapKit

class FlickrInterface {

    // MARK: Singleton
    static var sharedInstance = FlickrInterface()

    // MARK: Init
    private init() {
        guard let delegate = UIApplication.shared.delegate as? AppDelegate,
            let stack = delegate.stack else {
                fatalError("The AppDelegate or Core Data Stack could not be found")
        }
        self.stack = stack
    }

    // MARK: Properties
    let flickrManager = FlickrService.sharedInstance
    let stack: CoreDataStack!

    // MARK: Methods
    func getPhotos(pinLocation: PinLocation, completionHandler: @escaping (_ success: Bool, _ error: String?, _ photos: [Photo]?) -> Void) {

        //var pinLocation = pinLocation

        if pinLocation.flickrPlaceId == nil {
            flickrManager.getPlacesFindByLatLong(latitude: pinLocation.latitude, longitude: pinLocation.longitude) { success, result, error in
                guard error == nil else {
                    // Todo
                    print(error!.localizedDescription)
                    completionHandler(false, error!.localizedDescription, nil)
                    return
                }

                guard let placeId = result else {
                    // TODO
                    print("There was an error with the place id")
                    completionHandler(false, "There was an error with the place id", nil)
                    return
                }

                pinLocation.flickrPlaceId = placeId

                self.callPhotoService(pinLocation: pinLocation) { success, error, photos in
                    completionHandler(success, error, photos)
                }
            }
        } else {
            callPhotoService(pinLocation: pinLocation) { success, error, photos in
                completionHandler(success, error, photos)
            }
        }
    }

    func callPhotoService(pinLocation: PinLocation, completionHandler: @escaping (_ success: Bool, _ error: String?, _ photos: [Photo]?) -> Void) {
        guard let placeId = pinLocation.flickrPlaceId else {
            #if DEBUG
                print("There flickr place id could not be found")
            #endif
            return
        }

        var nextPage = 1

        if let flickrStats = pinLocation.flickrStats {
            nextPage = self.determineNextPage(flickrStats: flickrStats)
        }

        self.flickrManager.getPhotos(placeId: placeId, nextPage: nextPage, completionHandlerForGetPhotos: { success, result, error in


            guard success,
                error == nil,
                let result = result else {
                    var generalError = "There was a problem retrieving photos from Flickr"

                    if let error = error {
                        generalError = error.localizedDescription
                    }
                    completionHandler(false, generalError, nil)
                    return
            }

            guard let photosDataDict = result["photos"] as? [String: Any] else {
                completionHandler(false, "blah", nil)
                return
            }

            guard let page = photosDataDict["page"] as? Int16,
                let totalNumberOfPhotos = photosDataDict["total"] as? String else {
                    completionHandler(false, "Something went wrong with parsing the data for the photos", nil)
                    return
            }

            var photosToDisplay = [Photo]()

            if let photos = photosDataDict["photo"] as? [[String: Any]] {
                for photo in photos {
                    guard let photoToSave = self.parseIndividualPhotoInfo(photoDict: photo, pinLocation: pinLocation) else {
                        #if DEBUG
                            print("There was a problem creating the Photo object for photo: \(photo)")
                        #endif
                        completionHandler(false, "There was a problem creating the Photo object for photo: \(photo)", nil)
                        return
                    }
                    photosToDisplay.append(photoToSave)
                }
            } else if let photo = photosDataDict["photo"] as? [String: Any] {
                guard let photoToSave = self.parseIndividualPhotoInfo(photoDict: photo, pinLocation: pinLocation) else {
                    #if DEBUG
                        print("There was a problem creating the Photo object for photo: \(photo)")
                    #endif
                    completionHandler(false, "There was a problem creating the Photo object for photo: \(photo)", nil)
                    return
                }
                photosToDisplay.append(photoToSave)
            }

            // Save Stats
            pinLocation.flickrStats?.currentPage = page
            if let total = Int16(totalNumberOfPhotos) {
                pinLocation.flickrStats?.totalImages = total
            }

            completionHandler(true, nil, photosToDisplay)
        })
    }

    func determineNextPage(flickrStats: FlickrStats) -> Int {
        var nextPage = 1

        let potentialNextPage = Int(flickrStats.currentPage) + 1
        if potentialNextPage <= Int(ceil(Double(flickrStats.totalImages) / Double(FlickrService.Constants.ImagesPerPage))) {
            nextPage = potentialNextPage
        }
        return nextPage
    }

    func parseIndividualPhotoInfo(photoDict: [String: Any], pinLocation: PinLocation) -> Photo? {
        guard let photoId = photoDict["id"] as? String,
            let photoUrl = photoDict["url_m"] as? String else {
                #if DEBUG
                    print("Something went wrong with parsing the data for photo: \(photoDict)")
                #endif
                return nil
        }

        var id: Int64? = nil

        if let thisId = Int64(photoId) {
            id = thisId
        }

        let photoToSave = Photo(photoId: id, url: photoUrl, context: stack.context)
        pinLocation.addToPhoto(photoToSave)
        return photoToSave
    }

    func fetchImage(photo: Photo) {
        guard let photoUrl = photo.url,
            let url = URL(string: photoUrl) else {
            #if DEBUG
                print("There was a problem creating the url from \(photo.url)")
            #endif
            return
        }

        var imageData: NSData? = nil

        do {
            imageData = try NSData(contentsOf: url, options: .mappedIfSafe)
        } catch {
            #if DEBUG
                print("There was a problem fetching the data from the image url: \(url)")
            #endif
        }

        photo.image = imageData
    }
}
