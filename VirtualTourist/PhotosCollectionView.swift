//
//  PhotosCollectionView.swift
//  VirtualTourist
//
//  Created by Amelia Boli on 10/24/16.
//  Copyright © 2016 Appogenic. All rights reserved.
//

import UIKit
import CoreData

class PhotosCollectionView: UICollectionView {

    // MARK: Properties

    var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult>? {
        didSet {
            // Whenever the frc changes, we execute the search and
            // reload the table
            //fetchedResultsController?.delegate = self
            //executeSearch()
            self.reloadData()
        }
    }

    // MARK: Initializers


    init(fetchedResultsController fc: NSFetchedResultsController<NSFetchRequestResult>) {
        fetchedResultsController = fc
        let layout = UICollectionViewFlowLayout()

        super.init(frame: CGRect.zero, collectionViewLayout: layout)
    }

    // Do not worry about this initializer. I has to be implemented
    // because of the way Swift interfaces with an Objective C
    // protocol called NSArchiving. It's not relevant.
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

// MARK: - PhotosCollectionView (For Subclasses)

extension PhotosCollectionView {

    override func cellForItem(at indexPath: IndexPath) -> UICollectionViewCell? {
        fatalError("This method MUST be implemented by a subclass of PhotosCollectionView")
    }
}

// MARK: - PhotosCollectionView (UICollectionViewDataSource)

extension PhotosCollectionView {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if let fc = fetchedResultsController {
            return (fc.sections?.count)!
        } else {
            return 0
        }
    }

    override func numberOfItems(inSection section: Int) -> Int {
        if let fc = fetchedResultsController {
            return fc.sections![section].numberOfObjects
        } else {
            return 0
        }
    }
}

// MARK: - PhotosCollectionView (Fetches)

extension PhotosCollectionView {

    func executeSearch() {
        if let fc = fetchedResultsController {
            do {
                try fc.performFetch()
            } catch let e as NSError {
                print("Error while trying to perform a search: \n\(e)\n\(fetchedResultsController)")
            }
        }
    }
}

// MARK: - PhotosCollectionView: NSFetchedResultsControllerDelegate

extension PhotosCollectionView: NSFetchedResultsControllerDelegate{

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.performBatchUpdates( { updates in
            self.reloadData()
        }, completion: nil)
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        let set = IndexSet(integer: sectionIndex)

        switch (type) {
        case .insert:
            self.insertSections(set)
        case .delete:
            self.deleteSections(set)
        default:
            // irrelevant in our case
            break
        }
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {

        switch(type) {

        case .insert:
            self.insertItems(at: [newIndexPath!])
        case .delete:
            self.deleteItems(at: [indexPath!])
        case .update:
            self.reloadItems(at: [indexPath!])
        case .move:
            self.deleteItems(at: [indexPath!])
            self.insertItems(at: [newIndexPath!])
        }
    }

//    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
//        self.endUpdates()
//    }
}

