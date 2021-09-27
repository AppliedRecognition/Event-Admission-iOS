//
//  Errors.swift
//  EventAdmission
//
//  Created by Jakub Dolejs on 27/09/2021.
//

import Foundation

public enum TicketScanError: Int, Error {
    case cameraAccessDenied,
         cameraAccessRestricted,
         failedToAddCaptureSessionInput,
         failedToAddCaptureSessionOutput,
         unavailableSymbology,
         requestedCameraDeviceUnavailable,
         failedToDecodeUTF8String,
         captureSessionRuntimeError,
         captureSessionInterrupted
}

public enum EventError: Int, Error {
    case failedToLoadModelFromBundle,
         failedToInitializeModel
}

public enum EventAdmissionError: Error {
    case attendeeAlreadyAdmitted(time: Date)
    case entityNotFound
}

public enum QRCodeGenerationError: Int, Error {
    case failedToConvertPayloadToData,
         failedToCreateQRCodeGenerator,
         failedToCreateQRCodeImage
}

public enum QRCodeReadingError: Int, Error {
    case failedToCreateQRCodeDetector,
         failedToConvertImageToCIImage,
         failedToDetectQRCode,
         failedToReadQRCodeMessage
}
