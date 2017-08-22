//
//  PitcherDetailViewController.swift
//  gameSenseSports
//
//  Created by Paul Kohlhoff on 8/20/17.
//  Copyright © 2017 gameSenseSports. All rights reserved.
//

import UIKit

class PitcherDetailViewController : UIViewController
{
    @IBOutlet weak var myDescription: UILabel!
    @IBOutlet weak var pitcher: UILabel!
    @IBOutlet weak var thumbnail: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let parentViewController = self.navigationController?.viewControllers[0] as! DrillListViewController
        
    }
    
}
