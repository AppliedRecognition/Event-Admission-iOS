//
//  RegistrationViewController.swift
//  EventAdmissionSample
//
//  Created by Jakub Dolejs on 28/09/2021.
//

import UIKit
import VerIDCore
import VerIDUI
import EventAdmission

class RegistrationViewController: UIViewController, VerIDSessionDelegate {
    
    var verID: VerID?
    @IBOutlet var nameTextField: UITextField!
    @IBOutlet var extraUsersSwitch: UISwitch!
    private lazy var concurrentQueue = DispatchQueue(label: "com.appliedrec.faceGenerator", qos: .default, attributes: .concurrent)

    override func viewDidLoad() {
        super.viewDidLoad()
        if self.nameTextField.canBecomeFirstResponder {
            self.nameTextField.becomeFirstResponder()
        }
    }
    
    @IBAction func register() {
        guard let name = self.nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else {
            let alert = UIAlertController(title: nil, message: "Please enter a name", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                if self.nameTextField.canBecomeFirstResponder {
                    self.nameTextField.becomeFirstResponder()
                }
            })
            return
        }
        guard let verID = self.verID else {
            return
        }
        self.deleteAllFaces { _ in
            self.registerRandomFaces(count: 100) { result in
                if case .failure(let error) = result {
                    return
                }
                let settings = RegistrationSessionSettings(userId: name)
                settings.bearingsToRegister = [.straight]
                settings.faceCaptureCount = 1
                let session = VerIDSession(environment: verID, settings: settings)
                session.delegate = self
                session.start()
            }
        }
    }
    
    // MARK: -
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? AdmissionViewController, let (qrCode,name) = sender as? (UIImage,String) {
            vc.qrCode = qrCode
            vc.userName = name
            vc.verID = self.verID
        }
    }
    
    // MARK: - VerIDSessionDelegate
    
    func didFinishSession(_ session: VerIDSession, withResult result: VerIDSessionResult) {
        if let error = result.error {
            return
        }
        guard let face = result.faces(withBearing: .straight).first, let name = (session.settings as? RegistrationSessionSettings)?.userId else {
            return
        }
        if self.extraUsersSwitch.isOn {
            self.registerFacesSimilarTo(face, count: 3) { result in
                if case .failure(let error) = result {
                    return
                }
                self.generateQRCode(name: name)
            }
        } else {
            self.generateQRCode(name: name)
        }
    }
    
    // MARK: -
    
    func generateQRCode(name: String) {
        do {
            let qrCode = try QRCodeGenerator.default.generateQRCode(payload: name)
            self.performSegue(withIdentifier: "qrCode", sender: (qrCode,name))
        } catch {
            
        }
    }
    
    // MARK: - Face registration
    
    func deleteAllFaces(completion: @escaping (Error?) -> Void) {
        guard let verID = self.verID else {
            return
        }
        do {
            let users = try verID.userManagement.users()
            verID.userManagement.deleteUsers(users) { error in
                completion(error)
            }
        } catch {
            completion(error)
        }
    }
    
    func registerFacesSimilarTo(_ face: Recognizable, count: Int, completion: @escaping (Result<[String],Error>) -> Void) {
        guard let faceRecognition = self.verID?.faceRecognition as? VerIDFaceRecognition, let userManagement = self.verID?.userManagement else {
            preconditionFailure()
        }
        self.concurrentQueue.async {
            var err: Error?
            var registeredUsers: [String] = []
            DispatchQueue.concurrentPerform(iterations: count) { i in
                do {
                    let face = try faceRecognition.generateRandomFaceTemplateWithScore(NSNumber(value: Float.random(in: 5.0..<5.5)), againstFace: face)
                    let semaphore = DispatchSemaphore(value: 0)
                    let userId = UUID().uuidString
                    userManagement.assignFaces([face], toUser: userId) { error in
                        if error != nil {
                            DispatchQueue.main.async {
                                err = error
                            }
                        }
                        semaphore.signal()
                    }
                    guard semaphore.wait(timeout: .now()+2.0) == .success else {
                        throw NSError(domain: kVerIDErrorDomain, code: 1, userInfo: nil)
                    }
                    DispatchQueue.main.async {
                        registeredUsers.append(userId)
                    }
                } catch {
                    err = error
                }
            }
            DispatchQueue.main.async {
                if let error = err {
                    completion(.failure(error))
                } else {
                    completion(.success(registeredUsers))
                }
            }
        }
    }
    
    func registerRandomFaces(count: Int, completion: @escaping (Result<Void,Error>) -> Void) {
        guard let faceRecognition = self.verID?.faceRecognition as? VerIDFaceRecognition, let userManagement = self.verID?.userManagement else {
            preconditionFailure()
        }
        let register: () -> Void = {
            var err: Error?
            self.concurrentQueue.async {
                DispatchQueue.concurrentPerform(iterations: count) { _ in
                    do {
                        let face = try faceRecognition.generateRandomFaceTemplate(version: .V20)
                        let semaphore = DispatchSemaphore(value: 0)
                        userManagement.assignFaces([face], toUser: UUID().uuidString) { error in
                            if error != nil {
                                DispatchQueue.main.async {
                                    err = error
                                }
                            }
                            semaphore.signal()
                        }
                        guard semaphore.wait(timeout: .now()+2.0) == .success else {
                            throw NSError(domain: kVerIDErrorDomain, code: 1, userInfo: nil)
                        }
                    } catch {
                        DispatchQueue.main.async {
                            err = error
                        }
                    }
                }
                DispatchQueue.main.async {
                    if let error = err {
                        completion(.failure(error))
                    } else {
                        completion(.success(()))
                    }
                }
            }
        }
        do {
            let users = try userManagement.users()
            if !users.isEmpty {
                userManagement.deleteUsers(users) { _ in
                    register()
                }
            } else {
                register()
            }
        } catch {
            DispatchQueue.main.async {
                completion(.failure(error))
            }
        }
    }
}
