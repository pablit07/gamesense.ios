//
//  LoginViewController.swift
//  gameSenseSports
//
//  Created by Ra on 11/15/16.
//  Copyright © 2016 gameSenseSports. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {
    
    @IBOutlet weak var loginActiveView: UIView!
    @IBOutlet weak var idField: UITextField!
    @IBOutlet weak var handSegment: UISegmentedControl!
    

    private var loginComplete : Bool = false
    private var loginInProgress : Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        view.addGestureRecognizer(tap)
        idField.text = ""
        handSegment.selectedSegmentIndex = 1
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        self.loginComplete = false
        showLoginActiveView(shouldAppear: false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        showLoginActiveView(shouldAppear: true)
        if (self.idField.text?.isEmpty)!
        {
            showLoginActiveView(shouldAppear: false)
            self.showIDAlert()
            return false
        }
        return true
    }
    
    private func showLoginActiveView(shouldAppear: Bool)
    {
        if (shouldAppear) {
            self.loginInProgress = true
            self.loginActiveView.isUserInteractionEnabled = false
            UIView.animate(withDuration: 1.0, delay: 0, options: UIViewAnimationOptions.allowAnimatedContent, animations: {
                self.loginActiveView.alpha = 1
                },completion: { finished in
            })
        }
        else {
            self.loginInProgress = false
            self.loginActiveView.isUserInteractionEnabled = false
            UIView.animate(withDuration: 1.0, delay: 0, options: UIViewAnimationOptions.allowAnimatedContent, animations: {
                self.loginActiveView.alpha = 0
                },completion: { finished in
            })
        }
    }
    
    public func dismissKeyboard() {
        view.endEditing(true)
    }
    
    public func showIDAlert()
    {
        let alertController = UIAlertController(title: "Identification Required", message:
            "Please Enter an Identification Number", preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
}

