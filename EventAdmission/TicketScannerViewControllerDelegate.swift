//
//  TicketScannerViewControllerDelegate.swift
//  EventAdmission
//
//  Created by Jakub Dolejs on 27/09/2021.
//

import Foundation

public protocol TicketScannerViewControllerDelegate: AnyObject {
    
    func ticketScannerViewController(_ ticketScannerViewController: TicketScannerViewController, didScanCode: String)
    
    func ticketScannerViewController(_ ticketScannerViewController: TicketScannerViewController, didFailWithError error: Error)
}
