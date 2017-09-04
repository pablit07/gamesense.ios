//
//  ProfileWebViewController.swift
//  gameSenseSports
//
//  Created by Ra on 8/15/17.
//  Copyright © 2017 gameSenseSports. All rights reserved.
//

import UIKit

class ProfileWebViewController: UIViewController {
    @IBOutlet weak var profileWebView: UIWebView!
    @IBOutlet weak var navBar: UINavigationItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let pvc = self.presentingViewController as! ProfileViewController
        switch pvc.selected {
        case 1:
            let url = NSURL(string: "https://app.gamesensesports.com/dashboard/subscriptions")
            let requestObj = NSURLRequest(url: url! as URL)
            profileWebView.loadRequest(requestObj as URLRequest)
            navBar.title = "Account"
            break
        case 2:
            let url = NSURL(string: "https://app.gamesensesports.com/dashboard/score-chart")
            let requestObj = NSURLRequest(url: url! as URL)
            profileWebView.loadRequest(requestObj as URLRequest)
            navBar.title = "Statistics"
            break
        default:
            break
        }
        super.viewWillAppear(animated)
    }
    
    @IBAction func cancelButtonPressed(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: {})
    }
}
