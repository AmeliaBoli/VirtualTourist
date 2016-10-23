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

    private var region: MKCoordinateRegion? = nil

    let userDefaults = UserDefaults.standard

    private init() {

    }

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

        print("=========== Save Map\n---Region is \(region)")
        let center = region.center
        let centerLatitude = Double(center.latitude)
        let centerLongitude = Double(center.longitude)
        let centerCoordinate = ["latitude": centerLatitude, "longitude": centerLongitude]

        let span = region.span
        let latitudeDelta = Double(span.latitudeDelta)
        let longitudeDelta = Double(span.longitudeDelta)
        let coordinateSpan = ["latitudeDelta": latitudeDelta, "longitudeDelta": longitudeDelta]

        let state = ["center": centerCoordinate, "span": coordinateSpan] as [String : Any]
        print("---State is \(state)")
        userDefaults.set(state, forKey: "state")
    }

    func retrieveSavedMapState() {

        guard let state = userDefaults.dictionary(forKey: "state"),
            let center = state["center"] as? [String: Double],
            let latitude = center["latitude"],
            let longitude = center["longitude"],
            let span = state["span"] as? [String: Double],
            let latitudeDelta = span["latitudeDelta"],
            let longitudeDelta = span["longitudeDelta"] else {

                #if DEBUG
                    print("MapStateManager: retrieveSAvedMapState: There was a problem retrieving the saved region from user defaults")
                #endif
                return
        }

        print("============ Retrieve Map\nState is \(state)")
        let centerCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let spanCoordinates = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        let region = MKCoordinateRegion(center: centerCoordinate, span: spanCoordinates)
        print("---Region is \(region)")
        self.region = region
    }
}
