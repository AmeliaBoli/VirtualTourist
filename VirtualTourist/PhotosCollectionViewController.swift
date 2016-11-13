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
    var stack: CoreDataStack!

    var parentPhotosViewController: PhotosViewController?

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
        self.stack = stack

        // Create a fetchrequest
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        fetchRequest.predicate = NSPredicate(format: "pinLocation = %@", argumentArray: [pinLocation])
        fetchRequest.sortDescriptors = []

        // Create the FetchedResultsController
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        if collectionView?.numberOfItems(inSection: 0) == 0 {
            getPhotos()
        }
    }

    func getPhotos() {

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
                        }
                    }
                    return
            }

            if self.collectionView?.numberOfItems(inSection: 0) == 0,
                let parentVC = self.parent as? PhotosViewController {
                DispatchQueue.main.sync {
                    parentVC.activityIndicator.stopAnimating()
                }
                DispatchQueue.main.sync {
                    parentVC.noImagesLabel.isHidden = false
                    parentVC.newCollectionButton.isEnabled = true
                }
            }
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
        getPhotos()

        //        if let parentVC = self.parent as? PhotosViewController {
        //            parentVC.activityIndicator.stopAnimating()
        //        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell = PhotoCollectionViewCell()

        if let reusableCell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as? PhotoCollectionViewCell {
            cell = reusableCell
        }

        let photo = fetchedResultsController!.object(at: indexPath) as! Photo
        let image = UIImage(data: photo.image! as Data)
        cell.imageView.image = image

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
        if visibleCells.count == 0 && collectionView.numberOfItems(inSection: 0) > 0,
            let parentVC = self.parent as? PhotosViewController {
            parentVC.noImagesLabel.isHidden = true
            parentVC.activityIndicator.stopAnimating()
            parentVC.newCollectionButton.isEnabled = true
        }
    }
}
