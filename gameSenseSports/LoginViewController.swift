//
//  LoginViewController.swift
//  gameSenseSports
//
//  Created by Ra on 11/15/16.
//  Copyright © 2016 gameSenseSports. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var Password: UITextField!
    @IBOutlet weak var loginActiveView: UIView!
    @IBOutlet weak var Username: UITextField!
    

    private var loginComplete : Bool = false
    private var loginInProgress : Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        NotificationCenter.default.addObserver(self, selector: #selector(LoginViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(LoginViewController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        if let userDefault = UserDefaults.standard.object(forKey: Constants.kUsernameKey) as? String {
            if let passwordDefault = UserDefaults.standard.object(forKey: Constants.kPasswordKey) as? String {
                self.Username.text = userDefault
                self.Password.text = passwordDefault
                if (!self.shouldPerformSegue(withIdentifier: "login", sender: self)) {
                    return
                }
            }
        }
        
        self.Username.delegate = self
        self.Password.delegate = self
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
        if (self.loginInProgress) {
            return false
        }
        else if (identifier == "login" && !loginComplete) {
            view.endEditing(true)
            getLoginToken()
            return false
        }
        return true
    }
    
    private func getLoginToken()
    {
        self.showLoginActiveView(shouldAppear: true)
        var username = ""
        var password = ""
        if let userDefault = UserDefaults.standard.object(forKey: Constants.kUsernameKey) as? String {
            username = userDefault
        }
        else {
            username = Username.text!
            UserDefaults.standard.set(username, forKey: Constants.kUsernameKey)
        }
        if let passwordDefault = UserDefaults.standard.object(forKey: Constants.kPasswordKey) as? String {
            password = passwordDefault
        }
        else {
            password = Password.text!
            UserDefaults.standard.set(password, forKey: Constants.kPasswordKey)
        }
        
        SharedNetworkConnection.apiLogin(username: username, password: password, completionHandler: { data, response, error in
            guard let data = data, error == nil else {                                                 // check for fundamental networking error
                print("error=\(error)")
                self.showLoginActiveView(shouldAppear: false)
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                //status code 400
                let alert = UIAlertController(title: "Login Unsuccessful", message: "Your login could not be completed at this time. Please check your username and password and try again.\n\nIf problems persist, please check your internet connection or contact gamesenseSports at " + Constants.gamesenseSportsContact, preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
                UserDefaults.standard.removeObject(forKey: Constants.kUsernameKey)
                UserDefaults.standard.removeObject(forKey: Constants.kPasswordKey)
                
                DispatchQueue.main.async {
                    self.showLoginActiveView(shouldAppear: false)
                }
                self.present(alert, animated: true, completion: nil)
                print("response = \(response)")
                return
            }
            
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            
            let json = try? JSONSerialization.jsonObject(with: data, options: [])
            
            if let dictionary = json as? [String: Any] {
                if let apiToken = dictionary["token"] as? (String) {
                    appDelegate.apiToken = apiToken
                    self.loginComplete = true
                    self.performSegue(withIdentifier: "login", sender: self)
                    return
                }
            }
        })
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
    
    @IBAction func loginButtonPressed(_ sender: AnyObject) {
        let username = Username.text!
        UserDefaults.standard.set(username, forKey: Constants.kUsernameKey)
        
        let password = Password.text!
        UserDefaults.standard.set(password, forKey: Constants.kPasswordKey)
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
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.Username {
            self.Password.becomeFirstResponder()
        }
        return true
    }
    
}

