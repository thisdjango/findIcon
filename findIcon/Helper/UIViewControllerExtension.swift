//
//  UIViewControllerExtension.swift
//  findIcon
//
//  Created by Diana Tsarkova on 13.07.2024.
//

import UIKit.UIViewController

extension UIViewController {
    func showAlert(title: String = .error, message: String, completion: (() -> Void)? = nil) {
        let viewController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        viewController.addAction(UIAlertAction(title: .ok, style: .default))
        viewController.modalPresentationStyle = .overCurrentContext
        viewController.modalTransitionStyle = .crossDissolve
        present(viewController, animated: true)
    }
}
