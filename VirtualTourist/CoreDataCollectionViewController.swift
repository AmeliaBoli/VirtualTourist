//
//  CoreDataCollectionViewController.swift
//  VirtualTourist
//
//  Created by Amelia Boli on 10/24/16.
//  Copyright © 2016 Appogenic. All rights reserved.
//

import UIKit
import CoreData

class CoreDataCollectionViewController: UICollectionViewController {

    // MARK: Properties
    var insertedIndexPaths: [IndexPath]!
    var deletedIndexPaths: [IndexPath]!
    var updatedIndexPaths: [IndexPath]!

    var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult>? {
        didSet {
            // Whenever the frc changes, we execute the search and
            // reload the table
            fetchedResultsController?.delegate = self
            executeSearch()
            self.collectionView?.reloadData()
        }
    }

    // MARK: Initializers

    init(fetchedResultsController fc: NSFetchedResultsController<NSFetchRequestResult>) {
        fetchedResultsController = fc
        let layout = UICollectionViewFlowLayout()

        super.init(collectionViewLayout: layout)
    }

    // Do not worry about this initializer. I has to be implemented
    // because of the way Swift interfaces with an Objective C
    // protocol called NSArchiving. It's not relevant.
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

// MARK: - CoreDataCollectionViewController (For Subclasses)

extension CoreDataCollectionViewController {

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        fatalError("This method MUST be implemented by a subclass of CoreDataCollectionViewController")
    }
}

// MARK: - CoreDataCollectionViewController (UICollectionViewDataSource)

extension CoreDataCollectionViewController {

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        if let fc = fetchedResultsController {
            return (fc.sections?.count)!
        } else {
            return 0
        }
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let fc = fetchedResultsController,
            let section = fc.sections?[section] {
            return section.numberOfObjects
        } else {
            return 0
        }
    }
}

// MARK: - CoreDataCollectionViewController (Fetches)

extension CoreDataCollectionViewController {

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

// MARK: - CoreDataCollectionViewController: NSFetchedResultsControllerDelegate

extension CoreDataCollectionViewController: NSFetchedResultsControllerDelegate {

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        insertedIndexPaths = [IndexPath]()
        deletedIndexPaths = [IndexPath]()
        updatedIndexPaths = [IndexPath]()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {

        switch(type) {

        case .insert:
            insertedIndexPaths.append(newIndexPath!)
        case .delete:
            deletedIndexPaths.append(indexPath!)
        case .update:
            updatedIndexPaths.append(indexPath!)
        case .move:
            deletedIndexPaths.append(indexPath!)
            insertedIndexPaths.append(newIndexPath!)
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView?.performBatchUpdates({
            for indexPath in self.insertedIndexPaths {
                self.collectionView?.insertItems(at: [indexPath])
            }

            for indexPath in self.deletedIndexPaths {
                self.collectionView?.deleteItems(at: [indexPath])
            }

            for indexPath in self.updatedIndexPaths {
                self.collectionView?.reloadItems(at: [indexPath])
            }
        }, completion: nil)
    }
}

