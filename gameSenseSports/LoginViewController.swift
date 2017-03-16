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
    

    private var loginComplete: Bool = false
    private var loginInProgress: Bool = false
    
    var alertController: UIAlertController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        NotificationCenter.default.addObserver(self, selector: #selector(LoginViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(LoginViewController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0{
                self.view.frame.origin.y -= keyboardSize.height
            }
        }
        
    }
    
    func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y != 0{
                self.view.frame.origin.y += keyboardSize.height
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        self.loginComplete = false
        self.idField.text = ""
        self.handSegment.selectedSegmentIndex = 1
        showLoginActiveView(shouldAppear: false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        showLoginActiveView(shouldAppear: true)
        if (self.idField.text == Constants.adminPassPhrase)
        {
            if (identifier == "login")
            {
                self.showPasswordAlert()
                return false
            }
            else if (identifier == "admin")
            {
                return true
            }
        }
        
        if (self.idField.text?.isEmpty)!
        {
            showLoginActiveView(shouldAppear: false)
            self.showIDAlert()
            return false
        }
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.userID = self.idField.text!
        if (handSegment.selectedSegmentIndex == 1)
        {
            appDelegate.batterHand = "right"
        }
        else
        {
            appDelegate.batterHand = "left"
        }
        return true
    }
    
    private func showPasswordAlert()
    {
        alertController = UIAlertController(title: "Administrator",
                                            message: "Please enter your password",
                                            preferredStyle: .alert)
        alertController!.addTextField(
            configurationHandler: {(textField: UITextField!) in
                textField.placeholder = "Password"
        })
        let action = UIAlertAction(title: "Submit",
                                   style: UIAlertActionStyle.default,
                                   handler: {[weak self]
                                    (paramAction:UIAlertAction!) in
                                    if let textFields = self?.alertController?.textFields{
                                        let theTextFields = textFields as [UITextField]
                                        let enteredText = theTextFields[0].text
                                        if (enteredText == Constants.adminPassword)
                                        {
                                            self?.performSegue(withIdentifier: "admin", sender: nil)
                                        }
                                        else
                                        {
                                            self?.showLoginActiveView(shouldAppear: false)
                                            self?.dismissKeyboard()
                                            self?.alertController!.dismiss(animated: false, completion: nil)
                                        }
                                    }
        })
        alertController?.addAction(action)
        
        self.present(alertController!,
                     animated: true,
                     completion: nil)
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

