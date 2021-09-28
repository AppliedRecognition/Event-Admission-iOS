//
//  AdmissionViewController.swift
//  EventAdmissionSample
//
//  Created by Jakub Dolejs on 28/09/2021.
//

import UIKit
import VerIDUI
import VerIDCore
import EventAdmission

class AdmissionViewController: UIViewController, VerIDSessionDelegate, TicketScannerViewControllerDelegate {
    
    var qrCode: UIImage?
    var verID: VerID?
    var userName: String?
    @IBOutlet var codeImage: UIImageView!
    @IBOutlet var attendButton: UIButton!
    var event: Event?
    var identifiedUsers: [String] = []
    var faceImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.codeImage.image = self.qrCode
        Event.create(identifier: "test") { result in
            switch result {
            case .success(let event):
                event.clearAdmissionLog { _ in
                    self.event = event
                    self.attendButton.isEnabled = true
                }
            case .failure(let error):
                self.showMessage("Failed to load event: \(error.localizedDescription)", title: "Error")
            }
        }
    }
    
    @IBAction func attendEvent() {
        guard let verID = self.verID else {
            return
        }
        let settings = LivenessDetectionSessionSettings()
        settings.maxDuration = 3600
        settings.faceCaptureCount = 1
        let session = VerIDSession(environment: verID, settings: settings)
        session.delegate = self
        session.start()
    }
    
    @IBAction func exportQRCode(_ button: UIBarButtonItem) {
        guard let image = self.qrCode else {
            return
        }
        let activityViewController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        activityViewController.popoverPresentationController?.barButtonItem = button
        self.present(activityViewController, animated: true)
    }
    
    // MARK: - VerIDSessionDelegate
    
    func didFinishSession(_ session: VerIDSession, withResult result: VerIDSessionResult) {
        if let error = result.error {
            self.showMessage("Face detection session failed: \(error.localizedDescription)", title: "Stop")
            return
        }
        guard let verID = self.verID, let faceCapture = result.faceCaptures.first(where: { $0.bearing == .straight }) else {
            return
        }

        let identification = UserIdentification(verid: verID)
        identification.identifyUsersInFace(faceCapture.face, progress: nil) { result in
            switch result {
            case .success(let identifiedUsers):
                let selector = IdentifiedUserSelector()
                selector.minScoreDistance = 1.0
                if let bestMatch = selector.selectBestMatch(candidates: identifiedUsers) {
                    self.event?.admitAttendee(bestMatch, faceImage: faceCapture.faceImage, completion: self.onAdmitAttendeeResult)
                } else {
                    self.identifiedUsers = identifiedUsers.map({ $0.key })
                    self.faceImage = faceCapture.faceImage
                    self.scanTicket()
                }
            case .failure(let error):
                self.showMessage("Identification failed: \(error.localizedDescription)", title: "Error")
            }
        }
    }
    
    // MARK: -
    
    func scanTicket() {
        let ticketScanner = TicketScannerViewController()
        ticketScanner.delegate = self
        ticketScanner.title = "Show your ticket code"
        self.navigationController?.pushViewController(ticketScanner, animated: true)
    }
    
    func onAdmitAttendeeResult(_ result: Result<Void,Error>) {
        switch result {
        case .success():
            self.showMessage("Please proceed", title: "Success")
        case .failure(let error):
            switch error {
            case EventAdmissionError.attendeeAlreadyAdmitted(let time):
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .none
                dateFormatter.timeStyle = .medium
                self.showMessage("\(self.userName!) has already been admitted to the event at \(dateFormatter.string(from: time))", title: "Stop")
            default:
                self.showMessage("Admission failed", title: "Stop")
            }
        }
    }
    
    func showMessage(_ message: String, title: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
    }
    
    // MARK: - TicketScannerViewControllerDelegate
    
    func ticketScannerViewController(_ ticketScannerViewController: TicketScannerViewController, didScanCode code: String) {
        self.navigationController?.popToViewController(self, animated: true)
        if self.identifiedUsers.contains(code), let faceImage = self.faceImage {
            self.event?.admitAttendee(code, faceImage: faceImage, completion: self.onAdmitAttendeeResult)
        } else {
            self.showMessage("Your face hasn't been recognized", title: "Stop")
        }
    }
    
    func ticketScannerViewController(_ ticketScannerViewController: TicketScannerViewController, didFailWithError error: Error) {
        self.navigationController?.popToViewController(self, animated: true)
        self.showMessage("Failed to scan ticket code: \(error.localizedDescription)", title: "Error")
    }
}
