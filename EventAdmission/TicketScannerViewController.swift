//
//  TicketScannerViewController.swift
//  EventAdmission
//
//  Created by Jakub Dolejs on 27/09/2021.
//

import UIKit
import AVFoundation

public class TicketScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    public weak var delegate: TicketScannerViewControllerDelegate?
    public var cameraPosition: AVCaptureDevice.Position = .front
    lazy var scanQueue = DispatchQueue(label: "com.appliedrec.ticketScan")
    let captureSession = AVCaptureSession()
    
    private var avCaptureVideoOrientation: AVCaptureVideoOrientation {
        guard let uiOrientation: UIInterfaceOrientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation else {
            return AVCaptureVideoOrientation.portrait
        }
        switch uiOrientation {
        case .unknown:
            return AVCaptureVideoOrientation.portrait
        case .portrait:
            return AVCaptureVideoOrientation.portrait
        case .portraitUpsideDown:
            return AVCaptureVideoOrientation.portraitUpsideDown
        case .landscapeLeft:
            return AVCaptureVideoOrientation.landscapeLeft
        case .landscapeRight:
            return AVCaptureVideoOrientation.landscapeRight
        @unknown default:
            return AVCaptureVideoOrientation.portrait
        }
    }
    
    private var sessionRunningObserveContext = 0
    
    private var observeSession: Bool = false {
        didSet {
            if oldValue != observeSession && observeSession {
                NotificationCenter.default.addObserver(self, selector: #selector(sessionRuntimeError), name: Notification.Name("AVCaptureSessionRuntimeErrorNotification"), object: self.captureSession)
                
                /*
                 A session can only run when the app is full screen. It will be interrupted
                 in a multi-app layout, introduced in iOS 9, see also the documentation of
                 AVCaptureSessionInterruptionReason. Add observers to handle these session
                 interruptions and show a preview is paused message. See the documentation
                 of AVCaptureSessionWasInterruptedNotification for other interruption reasons.
                 */
                NotificationCenter.default.addObserver(self, selector: #selector(sessionWasInterrupted), name: Notification.Name("AVCaptureSessionWasInterruptedNotification"), object: self.captureSession)
            } else if oldValue != observeSession {
                NotificationCenter.default.removeObserver(self)
            }
        }
    }
    
    public init() {
        let frameworkBundle = Bundle(for: type(of: self))
        guard let bundleURL = frameworkBundle.url(forResource: "EventAdmissionResources", withExtension: "bundle") else {
            preconditionFailure()
        }
        guard let bundle = Bundle(url: bundleURL) else {
            preconditionFailure()
        }
        super.init(nibName: "TicketScannerViewController", bundle: bundle)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.startCamera()
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.stopCamera()
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animateAlongsideTransition(in: self.view, animation: nil) { [weak self] context in
            guard let `self` = self else {
                return
            }
            if !context.isCancelled, let previewLayer = self.view.layer.sublayers?.first(where: { $0 is AVCaptureVideoPreviewLayer }) as? AVCaptureVideoPreviewLayer, let connection = previewLayer.connection {
                connection.videoOrientation = self.avCaptureVideoOrientation
            }
        }
    }
    
    @objc func sessionRuntimeError(notification: NSNotification) {
        guard let errorValue = notification.userInfo?[AVCaptureSessionErrorKey] as? NSError else {
            self.scanDidFail(error: TicketScanError.captureSessionRuntimeError)
            return
        }
        let error = AVError(_nsError: errorValue)
        self.scanDidFail(error: error)
    }
    
    @objc func sessionWasInterrupted(notification: NSNotification) {
        self.scanDidFail(error: TicketScanError.captureSessionInterrupted)
    }
    
    func startCamera() {
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        switch authStatus {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    self.startScan()
                } else {
                    self.scanDidFail(error: TicketScanError.cameraAccessDenied)
                }
            }
        case .restricted:
            self.scanDidFail(error: TicketScanError.cameraAccessRestricted)
        case .denied:
            self.scanDidFail(error: TicketScanError.cameraAccessDenied)
        case .authorized:
            self.startScan()
        @unknown default:
            preconditionFailure()
        }
    }
    
    func stopCamera() {
        self.scanQueue.async {
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
        }
    }
    
    func startScan() {
        self.scanQueue.async {
            do {
                guard !self.captureSession.isRunning else {
                    return
                }
                guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: self.cameraPosition) else {
                    throw TicketScanError.requestedCameraDeviceUnavailable
                }
                let videoInput = try AVCaptureDeviceInput(device: camera)
                try camera.lockForConfiguration()
                if camera.isFocusModeSupported(AVCaptureDevice.FocusMode.continuousAutoFocus) {
                    camera.focusMode = .continuousAutoFocus
                } else if camera.isFocusModeSupported(AVCaptureDevice.FocusMode.autoFocus) {
                    camera.focusMode = .autoFocus
                }
                if camera.isFocusPointOfInterestSupported {
                    camera.focusPointOfInterest = CGPoint(x: 0.5, y: 0.5)
                }
                camera.unlockForConfiguration()
                guard self.captureSession.canAddInput(videoInput) else {
                    throw TicketScanError.failedToAddCaptureSessionInput
                }
                self.captureSession.addInput(videoInput)
                let barcodeOutput = AVCaptureMetadataOutput()
                barcodeOutput.setMetadataObjectsDelegate(self, queue: self.scanQueue)
                guard self.captureSession.canAddOutput(barcodeOutput) else {
                    throw TicketScanError.failedToAddCaptureSessionOutput
                }
                self.captureSession.addOutput(barcodeOutput)
                guard barcodeOutput.availableMetadataObjectTypes.contains(where: { $0 == AVMetadataObject.ObjectType.qr }) else {
                    throw TicketScanError.unavailableSymbology
                }
                barcodeOutput.metadataObjectTypes = [.qr]
                self.captureSession.startRunning()
                DispatchQueue.main.async {
                    let previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
                    previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
                    previewLayer.frame = self.view.bounds
                    if previewLayer.connection != nil && previewLayer.connection!.isVideoOrientationSupported {
                        previewLayer.connection!.videoOrientation = self.avCaptureVideoOrientation
                    }
                    self.view.layer.masksToBounds = true
                    while let sub = self.view.layer.sublayers?.first {
                        sub.removeFromSuperlayer()
                    }
                    self.view.layer.addSublayer(previewLayer)
                }
            } catch {
                self.scanDidFail(error: error)
            }
        }
    }
    
    func scanDidFail(error: Error) {
        DispatchQueue.main.async {
            self.delegate?.ticketScannerViewController(self, didFailWithError: error)
            self.delegate = nil
        }
    }
    
    func scanDidSucceed(ticketIdentifier: String) {
        DispatchQueue.main.async {
            self.delegate?.ticketScannerViewController(self, didScanCode: ticketIdentifier)
            self.delegate = nil
        }
    }
    
    // MARK: - AVCaptureMetadataOutputObjectsDelegate
    
    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let codeValue = (metadataObjects.first(where: { $0 is AVMetadataMachineReadableCodeObject && $0.type == AVMetadataObject.ObjectType.qr }) as? AVMetadataMachineReadableCodeObject)?.stringValue {
            self.stopCamera()
            self.scanDidSucceed(ticketIdentifier: codeValue)
        }
    }
    
    // MARK: -
}
