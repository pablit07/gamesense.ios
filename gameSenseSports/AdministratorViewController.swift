//
//  AdministratorViewController.swift
//  gameSenseSports
//
//  Created by Ra on 3/15/17.
//  Copyright © 2017 gameSenseSports. All rights reserved.
//

import Foundation
import UIKit

class AdministratorViewController: UIViewController {

    
    @IBOutlet weak var teamName: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    
    
    @IBAction func uploadFile(_ sender: Any) {
        
    }
    
    @IBAction func closeModal(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
