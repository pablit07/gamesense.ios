//
//  RegistrationWebViewController.swift
//  gameSenseSports
//
//  Created by Ra on 11/16/16.
//  Copyright © 2016 gameSenseSports. All rights reserved.
//

import UIKit

class RegistrationWebViewController: UIViewController {
    
    @IBOutlet weak var webView: UIWebView!
    @IBAction func cancelButtonPressed(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: {})
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let url = NSURL(string: "https://app.gamesensesports.com/account/register/")
        let requestObj = NSURLRequest(url: url! as URL)
        webView.loadRequest(requestObj as URLRequest)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}
