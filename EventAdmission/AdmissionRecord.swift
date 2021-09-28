//
//  AdmissionRecord.swift
//  EventAdmission
//
//  Created by Jakub Dolejs on 28/09/2021.
//

import UIKit
import CoreData

public class AdmissionRecord: NSManagedObject {
    
    @NSManaged public var attendee: String!
    @NSManaged public var event: String!
    @NSManaged public var image: Data?
    @NSManaged public var admissionTime: Date!
}
