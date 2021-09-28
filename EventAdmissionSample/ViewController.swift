//
//  ViewController.swift
//  EventAdmissionSample
//
//  Created by Jakub Dolejs on 27/09/2021.
//

import UIKit
import VerIDCore

class ViewController: UIViewController, VerIDFactoryDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let veridFactory = VerIDFactory()
        veridFactory.userManagementFactory = VerIDUserManagementFactory(disableEncryption: true)
        veridFactory.delegate = self
        veridFactory.createVerID()
    }
    
    func showFailure(error: Error) {
        let alert = UIAlertController(title: "Error", message: "Application failed to load: \(error.localizedDescription)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            fatalError()
        })
        self.present(alert, animated: true)
    }

    // MARK: - VerIDFactoryDelegate
    
    func veridFactory(_ factory: VerIDFactory, didCreateVerID verID: VerID) {
        guard self.isViewLoaded else {
            return
        }
        guard let registrationViewController = self.storyboard?.instantiateViewController(withIdentifier: "registration") as? RegistrationViewController else {
            return
        }
        registrationViewController.verID = verID
        self.navigationController?.setViewControllers([registrationViewController], animated: false)
    }

    func veridFactory(_ factory: VerIDFactory, didFailWithError error: Error) {
        self.showFailure(error: error)
    }
}
