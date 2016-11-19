//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Amelia Boli on 10/22/16.
//  Copyright © 2016 Appogenic. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate {

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
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        navigationController?.setNavigationBarHidden(true, animated: false)
        loadMap()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        saveMapState()
    }

    func loadMap() {
        if !checkForFirstLaunch(),
            let region = mapManager.getRegion() {

            let adjustedLatitudeDelta = region.span.latitudeDelta * 0.86
            let adjustedLongitdueDelta = region.span.longitudeDelta * 0.86
            let adjustedSpan = MKCoordinateSpan(latitudeDelta: adjustedLatitudeDelta, longitudeDelta: adjustedLongitdueDelta)
            let adjustedRegion = MKCoordinateRegion(center: region.center, span: adjustedSpan)

            mapView.setRegion(adjustedRegion, animated: false)
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
        saveMapState()
    }

    // I got this code from this Stack Overflow post: http://stackoverflow.com/questions/34431459/ios-swift-how-to-add-pinpoint-to-map-on-touch-and-get-detailed-address-of-th
    @IBAction func didPressAndHold(_ sender: UILongPressGestureRecognizer) {

        guard sender.state == .began else {
            return
        }

        let point = sender.location(in: mapView)
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)

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

