//
//  DrillListTableViewCell.swift
//  gameSenseSports
//
//  Created by Paul Kohlhoff on 6/1/17.
//  Copyright © 2017 gameSenseSports. All rights reserved.
//

import UIKit

class DrillListTableViewCell: UITableViewCell {

    
    var drillId : Int? = nil
    var drillList : DrillList? = nil
    
    @IBOutlet weak var pitcherButton: UIPitcherListButton!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        self.pitcherButton.drillList = self.drillList
        // Configure the view for the selected state
    }

}
