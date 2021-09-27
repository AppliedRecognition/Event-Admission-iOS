//
//  EventTests.swift
//  EventAdmissionTests
//
//  Created by Jakub Dolejs on 27/09/2021.
//

import XCTest
@testable import EventAdmission

class EventTests: XCTestCase {
    
    var event: Event!
    let attendee = "testAttendee"
    
    override func setUp(completion: @escaping (Error?) -> Void) {
        Event.create(identifier: "test") { result in
            switch result {
            case .success(let event):
                self.event = event
                completion(nil)
            case .failure(let error):
                completion(error)
            }
        }
    }
    
    override func tearDown(completion: @escaping (Error?) -> Void) {
        self.event.clearAdmissionLog { result in
            if case .failure(let error) = result {
                completion(error)
            } else {
                completion(nil)
            }
        }
    }
    
    func testAdmitAttendee() throws {
        let expectation = XCTestExpectation()
        self.event.admitAttendee(attendee, faceImage: UIImage()) { result in
            if case .failure(let error) = result {
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
        let time = try self.event.admissionTimeForAttendee(attendee)
        XCTAssertNotNil(time)
    }
    
    func testFailToRepeatedlyAdmitAttendee() throws {
        let expectation = XCTestExpectation()
        self.event.admitAttendee(attendee, faceImage: UIImage()) { result in
            if case .failure(let error) = result {
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
        let expectationRepeat = XCTestExpectation()
        self.event.admitAttendee(attendee, faceImage: UIImage()) { result in
            if case .success() = result {
                XCTFail()
            }
            expectationRepeat.fulfill()
        }
        wait(for: [expectationRepeat], timeout: 2.0)
    }
    
    func testGetAdmissionLog() throws {
        let expectation = XCTestExpectation()
        self.event.admitAttendee(attendee, faceImage: UIImage()) { result in
            if case .failure(let error) = result {
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
        let log = try self.event.admissionLog()
        XCTAssertEqual(log.count, 1)
        XCTAssertEqual(log[0].attendee, attendee)
    }
}
