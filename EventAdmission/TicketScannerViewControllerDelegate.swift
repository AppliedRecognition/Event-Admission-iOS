//
//  TicketScannerViewControllerDelegate.swift
//  EventAdmission
//
//  Created by Jakub Dolejs on 27/09/2021.
//

import Foundation

/// Ticket scanner view controller delegate
public protocol TicketScannerViewControllerDelegate: AnyObject {
    
    /// Called when the view controller successfully scans a QR code
    func ticketScannerViewController(_ ticketScannerViewController: TicketScannerViewController, didScanCode code: String)
    
    /// Called when the view controller fails to scan a QR code
    func ticketScannerViewController(_ ticketScannerViewController: TicketScannerViewController, didFailWithError error: Error)
}
