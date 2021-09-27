//
//  QRCodeTests.swift
//  EventAdmissionTests
//
//  Created by Jakub Dolejs on 27/09/2021.
//

import XCTest
@testable import EventAdmission

class QRCodeTests: XCTestCase {

    func testGenerateQRCode() throws {
        XCTAssertNoThrow(try QRCodeGenerator.default.generateQRCode(payload: "Hello"))
    }

    func testReadQRCode() throws {
        let message = "Hello"
        let image = try QRCodeGenerator.default.generateQRCode(payload: message)
        let decodedMessage = try QRCodeReader.default.readQRCode(in: image)
        XCTAssertEqual(decodedMessage, message)
    }
}
