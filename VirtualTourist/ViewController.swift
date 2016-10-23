//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Amelia Boli on 10/22/16.
//  Copyright © 2016 Appogenic. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class ViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!

    let mapManager = MapStateManager.sharedInstance

    var pinLocations = [MKPointAnnotation]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
            fatalError("Could not find the AppDelegate")
        }

        let stack = delegate.stack

        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "PinLocation")

        var pinLocations: [Any]?
        do {
            pinLocations = try stack?.context.fetch(fetchRequest)
        } catch {
            #if DEBUG
                print("ViewController: viewDidLoad: The locations could not be fetched: \(error.localizedDescription)")
            #endif
        }

        if let pinLocations = pinLocations as? [PinLocation] {
            for location in pinLocations {
                let annotation = MKPointAnnotation()
                annotation.coordinate = location.coordinate
                self.pinLocations.append(annotation)
            }
        }

        loadMap()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        saveMapState()
    }

    func loadMap() {
        if !checkForFirstLaunch(),
            let region = mapManager.getRegion() {
            mapView.setRegion(region, animated: false)
            mapView.addAnnotations(pinLocations)
            return
        }

        mapManager.setRegion(region: mapView.region)
    }

    func checkForFirstLaunch() -> Bool {
        let userDefaults = UserDefaults.standard
        if userDefaults.bool(forKey: "hasLaunchedBefore") {
            return false
        } else {
            userDefaults.set(true, forKey: "hasLaunchedBefore")
            saveMapState()
            return true
        }
    }

    func saveMapState() {
        let currentRegion = mapView.region
        mapManager.setRegion(region: currentRegion)
    }

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        mapManager.setRegion(region: mapView.region)
    }

    // I got this code from this Stack Overflow post: http://stackoverflow.com/questions/34431459/ios-swift-how-to-add-pinpoint-to-map-on-touch-and-get-detailed-address-of-th
    @IBAction func didPressAndHold(_ sender: UILongPressGestureRecognizer) {

        guard sender.state == .ended else {
            return
        }

        let point = sender.location(in: mapView)
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)

        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
    }
}

