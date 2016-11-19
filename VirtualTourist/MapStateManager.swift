//
//  MapStateManager.swift
//  VirtualTourist
//
//  Created by Amelia Boli on 10/22/16.
//  Copyright © 2016 Appogenic. All rights reserved.
//

import Foundation
import MapKit

class MapStateManager {

    static let sharedInstance = MapStateManager()
    private init() { }

    private var region: MKCoordinateRegion? = nil

    let userDefaults = UserDefaults.standard

    func setRegion(region: MKCoordinateRegion) {
        self.region = region
        saveMapState()
    }

    func getRegion() -> MKCoordinateRegion? {
        retrieveSavedMapState()
        return self.region
    }

    func saveMapState() {

        guard let region = region else {
            #if DEBUG
            print("MapStateManager: saveMapState: There was no region to save")
            #endif
            return
        }

        let center = region.center
        let centerLatitude = Float(center.latitude)
        let centerLongitude = Float(center.longitude)
        let centerCoordinate = ["latitude": centerLatitude, "longitude": centerLongitude]

        let span = region.span
        let latitudeDelta = Float(span.latitudeDelta)
        let longitudeDelta = Float(span.longitudeDelta)
        let coordinateSpan = ["latitudeDelta": latitudeDelta, "longitudeDelta": longitudeDelta]

        let state = ["center": centerCoordinate, "span": coordinateSpan] as [String : Any]
        userDefaults.set(state, forKey: "state")
    }

    func retrieveSavedMapState() {

        guard let state = userDefaults.dictionary(forKey: "state"),
            let center = state["center"] as? [String: Float],
            let latitude = center["latitude"],
            let longitude = center["longitude"],
            let span = state["span"] as? [String: Float],
            let latitudeDelta = span["latitudeDelta"],
            let longitudeDelta = span["longitudeDelta"] else {

                #if DEBUG
                    print("MapStateManager: retrieveSavedMapState: There was a problem retrieving the saved region from user defaults")
                #endif
                return
        }

        let centerCoordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(latitude), longitude: CLLocationDegrees(longitude))
        let spanCoordinates = MKCoordinateSpan(latitudeDelta: CLLocationDegrees(latitudeDelta), longitudeDelta: CLLocationDegrees(longitudeDelta))
        let region = MKCoordinateRegion(center: centerCoordinate, span: spanCoordinates)
        self.region = region
    }
}
