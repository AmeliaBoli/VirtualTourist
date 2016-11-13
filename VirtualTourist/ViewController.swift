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
    var stack: CoreDataStack!

    var pinLocations = [AnnotationWithObject]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
            fatalError("Could not find the AppDelegate")
        }

        stack = delegate.stack

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
                let annotation = AnnotationWithObject()
                annotation.coordinate = location.coordinate
                annotation.pinLocation = location
                self.pinLocations.append(annotation)
            }
        }

        loadMap()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        navigationController?.setNavigationBarHidden(true, animated: false)
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

        guard sender.state == .began else {
            return
        }

        let point = sender.location(in: mapView)
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
        print("=====\n--- 1. coordinate is \(coordinate)")

//        // if a pin with that coordinate already exists, cancel
//        let pinFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "PinLocation")
//        let coordinatePredicate = NSPredicate(format: "latitude == %@", coordinate.latitude)
//        pinFetchRequest.predicate = coordinatePredicate
//
//        do {
//            if let existingPins = try stack.context.fetch(pinFetchRequest) as? [PinLocation] {
//                print("--- 2. coordinate is \(existingPins.first?.coordinate.latitude)")
//                if existingPins.count > 0 {
//                    return
//                }
//            }
//        } catch {
//            #if DEBUG
//                print(error.localizedDescription)
//            #endif
//            return
//        }

        let pinLocation = PinLocation(coordinate: coordinate, context: stack.context)

        let annotation = AnnotationWithObject()
        annotation.coordinate = coordinate
        annotation.pinLocation = pinLocation
        pinLocations.append(annotation)
        mapView.addAnnotation(annotation)
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        mapView.deselectAnnotation(view.annotation, animated: false)
        performSegue(withIdentifier: "showPhotos", sender: view)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPhotos",
            let annotationView = sender as? MKAnnotationView,
            let pinLocation = (annotationView.annotation as? AnnotationWithObject)?.pinLocation,
            let controller = segue.destination as? PhotosViewController {
                controller.pinLocation = pinLocation
        }
    }
}

