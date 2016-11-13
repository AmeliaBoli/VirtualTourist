//
//  PhotosViewController.swift
//  VirtualTourist
//
//  Created by Amelia Boli on 10/22/16.
//  Copyright © 2016 Appogenic. All rights reserved.
//

import UIKit
import MapKit

class PhotosViewController: UIViewController {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    @IBOutlet weak var noImagesLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    var pinLocation: PinLocation!
    var coordinate: CLLocationCoordinate2D!

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.setNavigationBarHidden(false, animated: false)

        coordinate = CLLocationCoordinate2D(latitude: pinLocation.latitude, longitude: pinLocation.longitude)

        loadMap()
    }

    func loadMap() {

        let viewRegion = MKCoordinateRegionMakeWithDistance(coordinate, 75000, 75000)
        let adjustedRegion = mapView.regionThatFits(viewRegion)
        mapView.setRegion(adjustedRegion, animated: false)

        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
    }

    @IBAction func newCollectionPressed(_ sender: UIBarButtonItem) {
        let children = childViewControllers
        let photosCollectionVC = (children.flatMap() { $0 as? PhotosCollectionViewController }).first
        photosCollectionVC?.refreshPhotos()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "photoCollection",
            let controller = segue.destination as? PhotosCollectionViewController {
            controller.pinLocation = pinLocation
            controller.parentPhotosViewController = self
        }
    }
}
