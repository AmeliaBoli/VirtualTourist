//
//  AlertController Extension.swift
//  VirtualTourist
//
//  Created by Amelia Boli on 11/19/16.
//  Copyright © 2016 Appogenic. All rights reserved.
//

import UIKit

protocol AlertController {
    func createAlertControllerWithNoActions(message: String?)
    func presentAlertWithTryAgainAction(errorMessage: String, handler: @escaping (UIAlertAction) -> Void)
}

extension AlertController where Self: UIViewController {

    func createAlertControllerWithNoActions(message: String?) {
        let alert = UIAlertController(title: "There was a problem", message: message, preferredStyle: .alert)

        let cancel = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
        alert.addAction(cancel)

        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }

    func presentAlertWithTryAgainAction(errorMessage: String, handler: @escaping (UIAlertAction) -> Void) {
        let alert = UIAlertController(title: "Sorry!", message: errorMessage, preferredStyle: .alert)

        let tryAgainAction = UIAlertAction(title: "Try Again", style: .default, handler: handler)
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        alert.addAction(cancel)
        alert.addAction(tryAgainAction)

        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
}
