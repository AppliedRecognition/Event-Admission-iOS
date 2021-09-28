//
//  QRCodeGenerator.swift
//  EventAdmission
//
//  Created by Jakub Dolejs on 27/09/2021.
//

import Foundation
import UIKit

/// QR code generator
public class QRCodeGenerator {
    
    /// Default singleton instance of the QR code generator
    public static let `default` = QRCodeGenerator()
    
    /// Generate a QR code image
    /// - Parameter payload: Payload to encode in the QR code
    /// - Returns: Image with QR code
    public func generateQRCode(payload: String) throws -> UIImage {
        guard let data = payload.data(using: .utf8) else {
            throw QRCodeGenerationError.failedToConvertPayloadToData
        }
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            throw QRCodeGenerationError.failedToCreateQRCodeGenerator
        }
        filter.setValue(data, forKey: "inputMessage")
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        
        guard let output = filter.outputImage?.transformed(by: transform) else {
            throw QRCodeGenerationError.failedToCreateQRCodeImage
        }
        return UIImage(ciImage: output)
    }
}
