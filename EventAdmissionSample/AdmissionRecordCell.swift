//
//  AdmissionRecordCell.swift
//  EventAdmissionSample
//
//  Created by Jakub Dolejs on 28/09/2021.
//

import UIKit

class AdmissionRecordCell: UITableViewCell {
    
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var faceImage: UIImageView!
    @IBOutlet var timeLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
