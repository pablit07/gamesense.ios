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
    @IBOutlet weak var occlusionImage: UIImageView!
    
    var _difficulty = 0
    public var difficulty:Int {
        get {
            return _difficulty
        }
        set(value) {
            for view in difficultyView.subviews {
                view.removeFromSuperview()
            }
            var numCircles = 0
            var code: Int = 0

            if value <= 4 {
                code = 4
            } else if value <= 6 {
                code = 3
            } else if value <= 8 {
                code = 2
            } else if value > 8 {
                code = 1
            }
            
            for i in 0..<(value+1) {
                if i % 2 == 0 && i != 0 {
                    let image = UIImage(named: "full_circle_\(code).png")
                    let imageView = UIImageView(image: image)
                    imageView.frame = CGRect(x: numCircles*10, y: 0, width: 9, height: 9)
                    difficultyView.addSubview(imageView)
                    numCircles += 1
                }
                
                if i == value && (value % 2 == 1) {
                    let image = UIImage(named: "half_circle_\(code).png")
                    let imageView = UIImageView(image: image)
                    imageView.frame = CGRect(x: numCircles*10, y: 0, width: 5, height: 9)
                    difficultyView.addSubview(imageView)
                }
            }
            _difficulty = value
        }
    }
    
    var _occlusion = 0
    public var occlusion:Int {
        get {
            return _occlusion
        }
        set (value) {
            occlusionImage.image = UIImage(named: "occlusion_\(value).png")
            _occlusion = value
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
