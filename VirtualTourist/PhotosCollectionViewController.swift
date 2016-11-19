//
//  PhotosCollectionViewController.swift
//  VirtualTourist
//
//  Created by Amelia Boli on 11/6/16.
//  Copyright © 2016 Appogenic. All rights reserved.
//

import UIKit
import CoreData

class PhotosCollectionViewController: CoreDataCollectionViewController, UICollectionViewDelegateFlowLayout, AlertController {

    let flickrInterface = FlickrInterface.sharedInstance
    var pinLocation: PinLocation!
    var context: NSManagedObjectContext!

    var parentPhotosViewController: PhotosViewController?

    var showPlaceholders = true
    let defaultNumberOfItemsToShow = 15

    let numberOfColumns: CGFloat = 3
    let spacing: CGFloat = 10

    var itemsAreSelected: Bool {
        guard let photos = fetchedResultsController?.fetchedObjects as? [Photo] else {
            #if DEBUG
                print("There were no fetched items to check for selection")
            #endif
            return false
        }

        for photo in photos {
            if photo.isSelected {
                return true
            }
        }
        return false
    }

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
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "dateUpload", ascending: false)]

        // Create the FetchedResultsController
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        loadPhotos()
    }

    func loadPhotos() {
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
        if let parentVC = parent as? PhotosViewController {
            parentVC.bottomButton.isEnabled = false
            parentVC.activityIndicator.startAnimating()
            parentVC.noImagesLabel.isHidden = true
        }

        flickrInterface.getPhotos(pinLocation: pinLocation) { success, error in

            guard success,
                error == nil else {
                    var generalError = "There was a problem retrieving photos from Flickr"

                    if let error = error {
                        generalError = error
                    }

                    #if DEBUG
                        print(generalError)
                    #endif

                    if generalError == ErrorCode.connection.userMessage {
                        self.presentAlertWithTryAgainAction(errorMessage: generalError, handler: self.tryAgain)
                    } else if generalError != ErrorCode.noPlaceId.userMessage {
                        self.createAlertControllerWithNoActions(message: generalError)
                    }

                    if let parentVC = self.parent as? PhotosViewController {
                        DispatchQueue.main.sync {
                            parentVC.activityIndicator.stopAnimating()
                        }
                        DispatchQueue.main.sync {
                            parentVC.noImagesLabel.isHidden = false
                            parentVC.bottomButton.isEnabled = true
                        }
                    }
                    completionHandler(false)
                    return
            }

            try? self.fetchedResultsController?.performFetch()
            if let fetchedResults = self.fetchedResultsController?.fetchedObjects {
                if fetchedResults.count == 0,
                    let parentVC = self.parent as? PhotosViewController {
                    DispatchQueue.main.sync {
                        parentVC.activityIndicator.stopAnimating()
                    }
                    DispatchQueue.main.sync {
                        parentVC.noImagesLabel.isHidden = false
                        parentVC.bottomButton.isEnabled = true
                    }
                }
            }

            self.collectionView?.reloadData()
            completionHandler(true)
        }
    }

    func tryAgain(alert: UIAlertAction) {
        loadPhotos()
    }

    func bottomButtonPressed() {
        if itemsAreSelected {
            deleteSelectedPhotos()
        } else {
            refreshPhotos()
        }
    }

    func refreshPhotos() {
        guard let photos = fetchedResultsController?.fetchedObjects as? [Photo] else {
            #if DEBUG
                print("The photos fetched by the fetchedResultsController could not be retrieved")
            #endif
            return
        }

        for photo in photos {
            context.delete(photo)
        }

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

    func deleteSelectedPhotos() {
        guard let photos = fetchedResultsController?.fetchedObjects as? [Photo] else {
            #if DEBUG
                print("There was a problem finding all of the current photos")
            #endif
            return
        }

        for photo in photos {
            if photo.isSelected == true {
                context.delete(photo)
            }
        }
    }

    func setBottomButtonTitle() {
        if let parentVC = self.parent as? PhotosViewController {
            if itemsAreSelected {
                parentVC.bottomButton.title = "Remove Selected Photos"
            } else {
                parentVC.bottomButton.title = "New Collection"
            }
        }
    }

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

                if photo.isSelected {
                    cell.maskingView.isHidden = false
                } else {
                    cell.maskingView.isHidden = true
                }
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
        if let photo = fetchedResultsController?.object(at: indexPath) as? Photo {
            if photo.isSelected {
                photo.isSelected = false
            } else {
                photo.isSelected = true
            }
            collectionView.reloadItems(at: [indexPath])
            setBottomButtonTitle()
        }
    }

    override func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
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
            parentVC.bottomButton.isEnabled = true
        }
    }

    override func controllerCleanupPostChanges(success: Bool) {
        setBottomButtonTitle()
    }
}
