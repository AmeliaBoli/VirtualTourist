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
    func getPhotos(pinLocation: PinLocation, completionHandler: @escaping (_ success: Bool, _ error: String?) -> Void) {

        if pinLocation.flickrPlaceId == nil {
            flickrManager.getPlacesFindByLatLong(latitude: pinLocation.latitude, longitude: pinLocation.longitude) { success, result, error in
                guard error == nil else {
                    print(error!.localizedDescription)
                    if let userMessage = ErrorCode(rawValue: error!.code)?.userMessage {
                        completionHandler(false, userMessage)
                    } else {
                        completionHandler(false, error!.localizedDescription)
                    }
                    return
                }

                guard let placeId = result else {
                    print("There was an error with the place id")
                    if let userMessage = ErrorCode(rawValue: 2)?.userMessage {
                        completionHandler(false, userMessage)
                    } else {
                        completionHandler(false, "There was an error with the place id")
                    }
                    return
                }
                pinLocation.flickrPlaceId = placeId

                self.callPhotoService(pinLocation: pinLocation) { success, error in
                    completionHandler(success, error)
                }
            }
        } else {
            callPhotoService(pinLocation: pinLocation) { success, error in
                completionHandler(success, error)
            }
        }
    }

    func callPhotoService(pinLocation: PinLocation, completionHandler: @escaping (_ success: Bool, _ error: String?) -> Void) {
        guard let placeId = pinLocation.flickrPlaceId else {
            #if DEBUG
                print("The flickr place id could not be found")
            #endif
            if let userMessage = ErrorCode(rawValue: 2)?.userMessage {
                completionHandler(false, userMessage)
            } else {
                completionHandler(false, "The flickr place id could not be found")
            }
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
                        if let userMessage = ErrorCode(rawValue: error.code)?.userMessage {
                            generalError = userMessage
                        } else {
                            generalError = error.localizedDescription
                        }
                    }
                    completionHandler(false, generalError)
                    return
            }

            guard let photosDataDict = result["photos"] as? [String: Any] else {
                if let userMessage = ErrorCode(rawValue: 2)?.userMessage {
                    completionHandler(false, userMessage)
                } else {
                    completionHandler(false, "There was a problem parsing the data")
                }
                return
            }

            guard let page = photosDataDict["page"] as? Int16,
                let totalNumberOfPhotos = photosDataDict["total"] as? String else {
                    if let userMessage = ErrorCode(rawValue: 2)?.userMessage {
                        completionHandler(false, userMessage)
                    } else {
                        completionHandler(false, "Something went wrong with parsing the data for the photos")
                    }
                    return
            }

            if let photos = photosDataDict["photo"] as? [[String: Any]] {
                for photo in photos {
                    guard self.parseIndividualPhotoInfo(photoDict: photo, pinLocation: pinLocation) else {
                        #if DEBUG
                            print("There was a problem creating the Photo object for photo: \(photo)")
                        #endif
                        if let userMessage = ErrorCode(rawValue: 2)?.userMessage {
                            completionHandler(false, userMessage)
                        } else {
                            completionHandler(false, "There was a problem creating the Photo object for photo: \(photo)")
                        }
                        return
                    }
                }
            }

            // Save Stats
            pinLocation.flickrStats?.currentPage = page
            if let total = Int16(totalNumberOfPhotos) {
                pinLocation.flickrStats?.totalImages = total
            }
            completionHandler(true, nil)
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

    func parseIndividualPhotoInfo(photoDict: [String: Any], pinLocation: PinLocation) -> Bool {
        guard let photoId = photoDict["id"] as? String,
            let photoUrl = photoDict["url_m"] as? String,
            let secondsString = photoDict["dateupload"] as? String,
            let dateAsSeconds = Double(secondsString) else {
                #if DEBUG
                    print("Something went wrong with parsing the data for photo: \(photoDict)")
                #endif
                return false
        }

        var id: Int64? = nil

        if let thisId = Int64(photoId) {
            id = thisId
        }

        let date = Date(timeIntervalSince1970: dateAsSeconds)

        let photoToSave = Photo(photoId: id, url: photoUrl, dateUpload: date, context: stack.context)
        pinLocation.addToPhoto(photoToSave)

        return true
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
