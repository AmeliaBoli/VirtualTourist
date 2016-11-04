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
    @IBOutlet weak var photosCollectionView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!

    var pinLocation: PinLocation!
    var coordinate: CLLocationCoordinate2D!

    let flickrManager = FlickrInterface.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.setNavigationBarHidden(false, animated: false)

        coordinate = CLLocationCoordinate2D(latitude: pinLocation.latitude, longitude: pinLocation.longitude)

        loadMap()

        // if fetching images { newCollectionButton.isEnabled = false }

         //once fetching images is complete { newCollectionButton.isEnabled = true } and
        if photosCollectionView.numberOfItems(inSection: 0) == 0 {
            label.isHidden = false
        }

        var nextPage = 1

        if let flickrStats = pinLocation.flickrStats {
            flickrStats.currentPage += 1
            nextPage = Int(flickrStats.currentPage)
        }
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
    }
}
