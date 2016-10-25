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

    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: pinLocation.latitude, longitude: pinLocation.longitude)
    }

    let flickrManager = FlickrInterface.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.setNavigationBarHidden(false, animated: false)

        loadMap()

        // if fetching images { newCollectionButton.isEnabled = false }

         //once fetching images is complete { newCollectionButton.isEnabled = true } and
        if photosCollectionView.numberOfItems(inSection: 0) == 0 {
            label.isHidden = false
        }

        var nextPage = 1

        // TODO: Fetch next page for location
        if let flickrStats = pinLocation {
            nextPage = 1 //flickrStats.nextPage
        }

        flickrManager.getPlacesFindByLatLong(coordinate: coordinate, nextPage: nextPage) { success, result, error in
            guard error == nil else {
                // Todo
                print(error!.localizedDescription)
                return
            }

            guard let placeId = result else {
                // TODO
                print("There was an error with the place id")
                return
            }

            self.flickrManager.getPhotos(placeId: placeId, completionHandlerForGetPhotos: { success, result, error in
                if success {
                    print(result?[0])
                } else {
                    print(error?.localizedDescription)
                }
            })
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
