//
//  PhotosCollectionViewController.swift
//  VirtualTourist
//
//  Created by Amelia Boli on 11/6/16.
//  Copyright © 2016 Appogenic. All rights reserved.
//

import UIKit
import CoreData

class PhotosCollectionViewController: CoreDataCollectionViewController, UICollectionViewDelegateFlowLayout {

    let flickrInterface = FlickrInterface.sharedInstance
    var pinLocation: PinLocation!
    var context: NSManagedObjectContext

    var parentPhotosViewController: PhotosViewController?

    var showPlaceholders = true
    let defaultNumberOfItemsToShow = 15

    let numberOfColumns: CGFloat = 3
    let spacing: CGFloat = 10

    override func viewDidLoad() {
        super.viewDidLoad()

        // Get the stack
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            let stack = appDelegate.stack else {
                #if DEBUG
                    print("There was a problem finding the app delegate")
                #endif
                return
        }
        context = stack.context

        // Create a fetchrequest
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        fetchRequest.predicate = NSPredicate(format: "pinLocation = %@", argumentArray: [pinLocation])
        fetchRequest.sortDescriptors = []

        // Create the FetchedResultsController
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)

        if let fetchedObjects = fetchedResultsController?.fetchedObjects {
            if fetchedObjects.count == 0 {
                getPhotos() { success in
                    guard success else {
                        #if DEBUG
                            print("There was a problem with getPhotos()")
                        #endif
                        return
                    }
                    self.loadImages()
                }
            }
        }
    }

    func getPhotos(completionHandler: @escaping (_ success: Bool) -> Void) {

        //showPlaceholders = true

//        DispatchQueue.main.async {
//            self.collectionView?.reloadData()
//        }
        //collectionView?.reloadData()

        if let parentVC = parent as? PhotosViewController {
            parentVC.newCollectionButton.isEnabled = false
            parentVC.activityIndicator.startAnimating()
            parentVC.noImagesLabel.isHidden = true
        }

        flickrInterface.getPhotos(pinLocation: pinLocation) { success, error, photos in

            //            if let parentVC = self.parent as? PhotosViewController {
            //                parentVC.newCollectionButton.isEnabled = true
            //            }

            guard success,
                error == nil,
                photos != nil else {
                    var generalError = "There was a problem retrieving photos from Flickr"

                    if let error = error {
                        generalError = error
                    }

                    #if DEBUG
                        print(generalError)
                    #endif
                    if let parentVC = self.parent as? PhotosViewController {
                        DispatchQueue.main.sync {
                            parentVC.activityIndicator.stopAnimating()
                        }
                        DispatchQueue.main.sync {
                            parentVC.noImagesLabel.isHidden = false
                            parentVC.newCollectionButton.isEnabled = true
                            //self.showPlaceholders = false
                        }
                    }
                    completionHandler(false)
                    return
            }

            if let fetchedResults = self.fetchedResultsController?.fetchedObjects {

                if fetchedResults.count == 0,
                    let parentVC = self.parent as? PhotosViewController {
                    DispatchQueue.main.sync {
                        parentVC.activityIndicator.stopAnimating()
                    }
                    DispatchQueue.main.sync {
                        parentVC.newCollectionButton.isEnabled = true
                    }
                }
            }

            //self.showPlaceholders = false
            self.collectionView?.reloadData()
            completionHandler(true)
        }
    }

    func refreshPhotos() {
        //        if let parentVC = self.parent as? PhotosViewController {
        //            parentVC.noImagesLabel.isHidden = true
        //            //parentVC.activityIndicator.startAnimating()
        //        }

        guard let photos = fetchedResultsController?.fetchedObjects as? [Photo] else {
            #if DEBUG
                print("The photos fetched by the fetchedResultsController could not be retrieved")
            #endif
            return
        }

        for photo in photos {
            stack.context.delete(photo)
        }

        //collectionView?.reloadData()

        getPhotos() { success in
            guard success else {
                #if DEBUG
                    print("There was a problem with getPhotos()")
                #endif
                return
            }
            //self.collectionView?.reloadData()
            self.loadImages()
        }
    }

    func loadImages() {
        guard let photos = fetchedResultsController?.fetchedObjects as? [Photo] else {
            #if DEBUG
                print("The photos could not be found")
            #endif
            return
        }

        for photo in photos {
            flickrInterface.fetchImage(photo: photo)
            if let thisPhotosIndexPath = fetchedResultsController?.indexPath(forObject: photo) {
                DispatchQueue.main.async {
                    self.collectionView?.reloadItems(at: [thisPhotosIndexPath])
                }
            } else {
                DispatchQueue.main.async {
                    self.collectionView?.reloadData()
                }
            }
        }
    }

//    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        if showPlaceholders {
//            return defaultNumberOfItemsToShow
//        } else {
//            if let fetchedObjects = fetchedResultsController?.fetchedObjects {
//                return fetchedObjects.count
//            } else {
//                return 0
//            }
//        }
//    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell = PhotoCollectionViewCell()

        if let reusableCell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as? PhotoCollectionViewCell {
            cell = reusableCell
        }

        if let photo = fetchedResultsController?.object(at: indexPath) as? Photo {
            if let imageData = photo.image {
                cell.activityIndicator.stopAnimating()
                cell.backgroundColor = UIColor.clear
                let image = UIImage(data: imageData as Data)
                cell.imageView.image = image
            } else {
                cell.backgroundColor = UIColor(red: 0.3477, green: 0.4883, blue: 0.5664, alpha: 1)
                cell.imageView.image = nil
                cell.activityIndicator.startAnimating()
            }
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let collectionViewWidth = collectionView.frame.width
        let totalHorizontalSpacing = (2 * spacing) + (numberOfColumns - 1)
        let cellSide = (collectionViewWidth - totalHorizontalSpacing) / numberOfColumns
        return CGSize(width: cellSide, height: cellSide)
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let photoToDelete = fetchedResultsController?.object(at: indexPath) as! Photo
        fetchedResultsController?.managedObjectContext.delete(photoToDelete)
    }

    override func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        print("\(newIndexPath?.row) \(type.rawValue)")
        super.controller(controller, didChange: anObject, at: indexPath, for: type, newIndexPath: newIndexPath)
    }

    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let visibleCells = collectionView.visibleCells
        if visibleCells.count == 0,
            let fetchedResults = fetchedResultsController?.fetchedObjects,
            fetchedResults.count > 0,
            let parentVC = self.parent as? PhotosViewController {
            parentVC.noImagesLabel.isHidden = true
            parentVC.activityIndicator.stopAnimating()
            parentVC.newCollectionButton.isEnabled = true
        }
    }
}
