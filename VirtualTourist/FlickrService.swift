//
//  FlickrService.swift
//  VirtualTourist
//
//  Created by Amelia Boli on 10/23/16.
//  Copyright © 2016 Appogenic. All rights reserved.
//

import UIKit
import CoreLocation

class FlickrService: Networking {

    // MARK: Singleton
    static var sharedInstance = FlickrService()
    private init () { }

    // MARK: Properties
    // ids, keys, anything else the whole class needs access too
    let secret = "519234fcdf52e6a1"

    let session = URLSession.shared

    // Constants
    struct Constants {
        static let Scheme = "https"
        static let Host = "api.flickr.com"
        static let Path = "/services/rest"

        static let ApiKey = "516e6620e0207110c47304d7cf1d7cdd"

        static let ImagesPerPage = 15 //Arbitrary amount to allow for scrolling at 3 images accross in the collection view
    }

    // Methods
    struct Methods {
        // https://www.flickr.com/services/api/flickr.photos.search.html
        static let PhotosSearch = "flickr.photos.search"
        // https://www.flickr.com/services/api/flickr.places.findByLatLon.html
        static let PlacesFindByLatLon = "flickr.places.findByLatLon"
    }

   // Parameter Keys
    struct ParameterKeys {
        static let Method = "method"
        static let ApiKey = "api_key"
        static let Lat = "lat"
        static let Lon = "lon"
        static let Format = "format"
        static let NoJSONCallback = "nojsoncallback"
        static let PlaceId = "place_id"
        static let Extras = "extras"
        static let PerPage = "per_page"
        static let Page = "page"
    }

    // Parameter Values
    struct ParameterValues {
        static let Json = "json"
        static let DisableJSONCallback = "1" /* 1 means "yes" */
        static let MediumUrl = "url_m"
        static let DateUpload = "date_upload"
    }

    // JSON Body Keys
    struct JSONBodyKeys {
        // don't remember but shows UniqueKey = "uniqueKey" maybe for parseing?
    }

    // GET Calls
    func getPlacesFindByLatLong(latitude: Double, longitude: Double, completionHandlerForPlaces: @escaping (_ success: Bool, _ placeId: String?, _ error: NSError?) -> Void) {

        let domain = "getPlacesFindByLatLong"

        let parameters: [String: Any] = [ParameterKeys.Method: Methods.PlacesFindByLatLon,
                                         ParameterKeys.ApiKey: Constants.ApiKey,
                                         ParameterKeys.Lat: String(latitude),
                                         ParameterKeys.Lon: String(longitude),
                                         ParameterKeys.Format: ParameterValues.Json,
                                         ParameterKeys.NoJSONCallback: ParameterValues.DisableJSONCallback]

        guard let url = urlFromComponents(scheme: Constants.Scheme, host: Constants.Host, path: Constants.Path, withPathExtension: nil, parameters: parameters) else {
            let error = "There was a problem creating the url to make the request"
            let nsError = createError(error: error, domain: domain, code: 2)
            completionHandlerForPlaces(false, nil, nsError)
            return
        }

        let request = URLRequest(url: url)

        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        #if DEBUG
            print("Flickr service starting")
        #endif
        _ = taskForHTTPMethod(request: request) { result, error in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            guard error == nil else {
                #if DEBUG
                    print("There was an error with taskForHTTPMethod")
                #endif
                completionHandlerForPlaces(false, nil, error! as NSError)
                return
            }

            guard let serializedData = result else {
                let error = "There was an error acessing the returned data"
                let nsError = self.createError(error: error, domain: domain, code: 2)
                completionHandlerForPlaces(false, nil, nsError)
                return
            }

            self.deserializeJSONWithCompletionHandler(data: serializedData) { result, error in
                guard error == nil else {
                    #if DEBUG
                        print("There was an error with deserializing the JSON")
                    #endif
                    completionHandlerForPlaces(false, nil, error! as NSError)
                    return
                }

                guard let jsonData = result as? [String: Any],
                    let placeDataDict = jsonData["places"] as? [String: Any],
                    let placeData = placeDataDict["place"] as? [[String: Any]] else {
                        let error = "There was an error with results key in \(result)"
                        let nsError = self.createError(error: error, domain: domain, code: 2)
                        completionHandlerForPlaces(false, nil, nsError)
                        return
                }

                guard placeData.count > 0 else {
                    let error = "There were no place ids for the location"
                    let nsError = self.createError(error: error, domain: domain, code: 3)
                    completionHandlerForPlaces(false, nil, nsError)
                    return
                }

                for data in placeData {
                    if let placeId = data["place_id"] as? String {
                        completionHandlerForPlaces(true, placeId, nil)
                    } else {
                        let error = "There was an error finding the place ID in the deserialized data"
                        let nsError = self.createError(error: error, domain: domain, code: 2)
                        completionHandlerForPlaces(false, nil, nsError)
                        return
                    }
                }
            }
        }
    }

    func getPhotos(placeId: String, nextPage: Int, completionHandlerForGetPhotos: @escaping (_ success: Bool, _ photoData: [String: Any]?, _ error: NSError?) -> Void) {

        let domain = "getPhotos"

        let parameters: [String: Any] = [ParameterKeys.Method: Methods.PhotosSearch,
                                         ParameterKeys.ApiKey: Constants.ApiKey,
                                         ParameterKeys.PlaceId: placeId,
                                         ParameterKeys.PerPage: Constants.ImagesPerPage,
                                         ParameterKeys.Page: nextPage,
                                         ParameterKeys.Extras: "\(ParameterValues.MediumUrl), \(ParameterValues.DateUpload)",
                                         ParameterKeys.Format: ParameterValues.Json,
                                         ParameterKeys.NoJSONCallback: ParameterValues.DisableJSONCallback]

        guard let url = urlFromComponents(scheme: Constants.Scheme, host: Constants.Host, path: Constants.Path, withPathExtension: nil, parameters: parameters) else {
            let error = "There was a problem creating the url to make the request"
            let nsError = createError(error: error, domain: domain, code: 2)
            completionHandlerForGetPhotos(false, nil, nsError)
            return
        }

        let request = URLRequest(url: url)

        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        _ = taskForHTTPMethod(request: request) { result, error in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false

            guard error == nil else {
                #if DEBUG
                    print("There was an error with taskForHTTPMethod")
                #endif
                completionHandlerForGetPhotos(false, nil, error! as NSError)
                return
            }

            guard let serializedData = result else {
                let error = "There was an error acessing the returned data"
                let nsError = self.createError(error: error, domain: domain, code: 2)
                completionHandlerForGetPhotos(false, nil, nsError)
                return
            }

            self.deserializeJSONWithCompletionHandler(data: serializedData) { result, error in
                guard error == nil else {
                    #if DEBUG
                        print("There was an error with deserializing the JSON")
                    #endif
                    completionHandlerForGetPhotos(false, nil, error! as NSError)
                    return
                }

                guard let jsonData = result as? [String: Any] else {
                        let error = "There was an error with parsing the data in \(result)"
                    let nsError = self.createError(error: error, domain: domain, code: 2)
                        completionHandlerForGetPhotos(false, nil, nsError)
                        return
                }

                completionHandlerForGetPhotos(true, jsonData, nil)
            }
        }
    }

    // Helper Method
    func createError(error: String, domain: String, code: Int) -> NSError {
        #if DEBUG
            print(error)
        #endif
        let domain = domain
        let userInfo = [NSLocalizedDescriptionKey : error]
        let nsError = NSError(domain: domain, code: code, userInfo: userInfo)
        return nsError
    }
}
