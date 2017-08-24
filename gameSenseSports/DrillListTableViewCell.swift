//
//  DrillListTableViewCell.swift
//  gameSenseSports
//
//  Created by Paul Kohlhoff on 6/1/17.
//  Copyright © 2017 gameSenseSports. All rights reserved.
//

import UIKit

class DrillListTableViewCell: UITableViewCell {
    
    @IBOutlet weak var difficultyView: UIView!
    
    var _difficulty = 0
    public var difficulty:Int {
        get {
            return _difficulty
        }
        set(value) {
            var numCircles = 0
            for i in 0..<(value+1) {
                if i % 2 == 0 && i != 0 {
                    let image = UIImage(named: "full_circle_1.png")
                    let imageView = UIImageView(image: image)
                    imageView.frame = CGRect(x: numCircles*10, y: 0, width: 9, height: 9)
                    difficultyView.addSubview(imageView)
                    numCircles += 1
                }
                
                if i == value && (value % 2 == 1) {
                    let image = UIImage(named: "half_circle_1.png")
                    let imageView = UIImageView(image: image)
                    imageView.frame = CGRect(x: numCircles*10, y: 0, width: 5, height: 9)
                    difficultyView.addSubview(imageView)
                }
            }
            _difficulty = value
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
