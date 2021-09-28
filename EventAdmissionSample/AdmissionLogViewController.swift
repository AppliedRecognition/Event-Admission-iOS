//
//  AdmissionLogViewController.swift
//  EventAdmissionSample
//
//  Created by Jakub Dolejs on 28/09/2021.
//

import UIKit
import EventAdmission

class AdmissionLogViewController: UITableViewController {

    var log: [AdmissionRecord] = []
    let dateFormatter = DateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dateFormatter.dateStyle = .none
        self.dateFormatter.timeStyle = .medium
        Event.create(identifier: "test") { result in
            switch result {
            case .success(let event):
                do {
                    self.log = try event.admissionLog()
                    self.tableView.reloadData()
                } catch {
                    self.showMessage("Failed to load admission log: \(error.localizedDescription)", title: "Error")
                }
            case .failure(let error):
                self.showMessage("Failed to load event: \(error.localizedDescription)", title: "Error")
            }
        }
    }
    
    func showMessage(_ message: String, title: String, actions: [UIAlertAction]? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        if let `actions` = actions, !actions.isEmpty {
            actions.forEach({
                alert.addAction($0)
            })
        } else {
            alert.addAction(UIAlertAction(title: "OK", style: .default))
        }
        self.present(alert, animated: true)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.log.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "admissionRecord", for: indexPath) as? AdmissionRecordCell else {
            return UITableViewCell()
        }
        let record = self.log[indexPath.row]
        cell.nameLabel.text = record.attendee
        cell.timeLabel.text = record.admissionTime != nil ? self.dateFormatter.string(from: record.admissionTime!) : ""
        cell.faceImage.image = record.image != nil ? UIImage(data: record.image!) : nil
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        72
    }

}
