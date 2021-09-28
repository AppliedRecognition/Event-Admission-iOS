//
//  QRCodeReader.swift
//  EventAdmission
//
//  Created by Jakub Dolejs on 27/09/2021.
//

import Foundation
import UIKit

/// QR code reader
public class QRCodeReader {
    
    /// Default singleton instance of the QR code generator
    public static let `default` = QRCodeReader()
    
    /// Read QR code in image
    /// - Parameter image: Image containing the QR code
    /// - Returns: String encoded in the QR code
    public func readQRCode(in image: UIImage) throws -> String {
        guard let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy:CIDetectorAccuracyHigh, CIDetectorMaxFeatureCount:1]) else {
            throw QRCodeReadingError.failedToCreateQRCodeDetector
        }
        let ciImage: CIImage = image.ciImage ?? CIImage(cgImage: image.cgImage!)
        guard let features = detector.features(in: ciImage) as? [CIQRCodeFeature], !features.isEmpty else {
            throw QRCodeReadingError.failedToDetectQRCode
        }
        guard let message = features.first!.messageString else {
            throw QRCodeReadingError.failedToReadQRCodeMessage
        }
        return message
    }
}
