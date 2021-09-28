//
//  Event.swift
//  EventAdmission
//
//  Created by Jakub Dolejs on 27/09/2021.
//

import Foundation
import UIKit
import CoreData

/// Class representing a ticketed event
public class Event {
    
    /// Event identifier
    public let identifier: String
    private let persistentContainer: NSPersistentContainer
    
    /// Create event
    /// - Parameters:
    ///   - identifier: Event identifier
    ///   - completion: Completion callback
    public static func create(identifier: String, completion: @escaping (Result<Event,Error>) -> Void) {
        do {
            let modelName = "AdmissionLog"
            guard var modelURL = Bundle(for: Event.self).url(forResource: modelName, withExtension: "momd") else {
                throw EventError.failedToLoadModelFromBundle
            }
            let versionInfoURL = modelURL.appendingPathComponent("VersionInfo.plist")
            if let versionInfoNSDictionary = NSDictionary(contentsOf: versionInfoURL), let version = versionInfoNSDictionary.object(forKey: "NSManagedObjectModel_CurrentVersionName") as? String {
                modelURL.appendPathComponent("\(version).mom")
            }
            guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
                throw EventError.failedToInitializeModel
            }
            let container: NSPersistentContainer = NSPersistentContainer(name: modelName, managedObjectModel: model)
            container.loadPersistentStores { (storeDescription, error) in
                if let error = error as NSError? {
                    // Replace this implementation with code to handle the error appropriately.
                    // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    
                    /*
                     Typical reasons for an error here include:
                     * The parent directory does not exist, cannot be created, or disallows writing.
                     * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                     * The device is out of space.
                     * The store could not be migrated to the current model version.
                     Check the error message to determine what the actual problem was.
                     */
                    completion(.failure(error))
                } else {
                    completion(.success(Event(identifier: identifier, persistentContainer: container)))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    private init(identifier: String, persistentContainer: NSPersistentContainer) {
        self.identifier = identifier
        self.persistentContainer = persistentContainer
    }
    
    /// Admit an event attendee
    /// - Parameters:
    ///   - attendee: Attendee identifier
    ///   - faceImage: Image of the attendee's face
    ///   - completion: Completion callback
    public func admitAttendee(_ attendee: String, faceImage: UIImage?, completion: @escaping (Result<Void,Error>) -> Void) {
        self.persistentContainer.performBackgroundTask { context in
            do {
                context.mergePolicy = NSMergePolicy.overwrite
                let request: NSFetchRequest = NSFetchRequest<AdmissionRecord>(entityName: "AdmissionRecord")
                request.returnsDistinctResults = true
                request.predicate = NSPredicate(format: "attendee = %@ AND event = %@", attendee, self.identifier)
                if let admissionTime = try context.fetch(request).first?.admissionTime {
                    throw EventAdmissionError.attendeeAlreadyAdmitted(time: admissionTime)
                }
                guard let entity = NSEntityDescription.entity(forEntityName: "AdmissionRecord", in: context) else {
                    throw EventAdmissionError.entityNotFound
                }
                let record = AdmissionRecord(entity: entity, insertInto: context)
                record.admissionTime = Date()
                record.attendee = attendee
                record.event = self.identifier
                record.image = faceImage?.jpegData(compressionQuality: 0.9)
                try context.save()
                OperationQueue.main.addOperation {
                    completion(.success(()))
                }
            } catch {
                OperationQueue.main.addOperation {
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Get the time the given attendee was admitted to the event
    /// - Parameter attendee: Attendee identifier
    /// - Returns: Date the attendee was admitted to the event or `nil` if the attendee hasn't yet been admitted
    public func admissionTimeForAttendee(_ attendee: String) throws -> Date? {
        let request: NSFetchRequest = NSFetchRequest<AdmissionRecord>(entityName: "AdmissionRecord")
        request.returnsDistinctResults = true
        request.predicate = NSPredicate(format: "attendee = %@ AND event = %@", attendee, self.identifier)
        if let admissionRecordDict: AdmissionRecord = try self.persistentContainer.viewContext.fetch(request).first {
            return admissionRecordDict.admissionTime
        }
        return nil
    }
    
    /// Get an admission log
    /// - Returns: Array of admission records
    public func admissionLog() throws -> [AdmissionRecord] {
        let request: NSFetchRequest = NSFetchRequest<AdmissionRecord>(entityName: "AdmissionRecord")
        request.returnsDistinctResults = true
        request.predicate = NSPredicate(format: "event = %@", self.identifier)
        request.sortDescriptors = [NSSortDescriptor(key: "admissionTime", ascending: false)]
        return try self.persistentContainer.viewContext.fetch(request)
    }
    
    /// Clear the event's admission log
    /// - Parameter completion: Completion callback
    public func clearAdmissionLog(completion: @escaping (Result<Void,Error>) -> Void) {
        self.persistentContainer.performBackgroundTask { context in
            do {
                context.mergePolicy = NSMergePolicy.overwrite
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "AdmissionRecord")
                fetchRequest.predicate = NSPredicate(format: "event = %@", self.identifier)
                let request = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                try context.execute(request)
                try context.save()
                OperationQueue.main.addOperation {
                    completion(.success(()))
                }
            } catch {
                OperationQueue.main.addOperation {
                    completion(.failure(error))
                }
            }
        }
    }
}
