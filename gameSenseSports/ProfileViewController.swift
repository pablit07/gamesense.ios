//
//  ProfileViewController.swift
//  gameSenseSports
//
//  Created by Ra on 8/14/17.
//  Copyright © 2017 gameSenseSports. All rights reserved.
//

import UIKit

class ProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var menuView: UIView!
    public var selected = 0
    var animated = false
    
    @IBOutlet weak var username: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let userDefault = UserDefaults.standard.object(forKey: Constants.kUsernameKey) as? String {
            username.text = userDefault
        }
        
        menuView.frame.origin.x = 0 - menuView.frame.size.width
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
         UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut, animations: {
            self.menuView.frame.origin.x = 0
         }, completion: { finished in
            self.menuView.layer.masksToBounds = false
            self.menuView.layer.shadowColor = UIColor.black.cgColor
            self.menuView.layer.shadowOpacity = 0.5
            self.menuView.layer.shadowOffset = CGSize(width: -1, height: 1)
            self.menuView.layer.shadowRadius = 1
            self.menuView.layer.shadowPath = UIBezierPath(rect: self.menuView.bounds).cgPath
            self.menuView.layer.shouldRasterize = true
            self.menuView.layer.rasterizationScale = UIScreen.main.scale
         })

    }
    
    func numberOfSectionsInTableView(in tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "menuCell", for: indexPath)
        let label = cell.viewWithTag(2) as! UILabel
        let icon = cell.viewWithTag(1) as! UIImageView
        switch (indexPath.row) {
        case 0:
            label.text = "Home"
            let image = UIImage(named:"home.png")
            icon.image = image
            break
        case 1:
            label.text = "Account"
            let image = UIImage(named:"account.png")
            icon.image = image
            break
        case 2:
            label.text = "Statistics"
            let image = UIImage(named:"charts.png")
            icon.image = image
            break
        case 3:
            label.text = "Log Out"
            let image = UIImage(named:"logout.png")
            icon.image = image
            break
        default:
            break
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //Home
        if (indexPath.row == 0) {
            self.dismissMenu()
        }
        
        //Web View
        if (indexPath.row == 1 || indexPath.row == 2) {
            self.selected = indexPath.row
            self.performSegue(withIdentifier: "profileWebview", sender: nil)
        }
        
        //Logout
        if (indexPath.row == 3) {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.apiToken = ""
            self.view.window!.rootViewController?.dismiss(animated: false, completion: nil)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func dismissMenu(sender: UIButton) {
        self.dismissMenu()
    }
    
    func dismissMenu()
    {
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut, animations: {
            self.menuView.frame.origin.x = 0 - self.menuView.frame.size.width
        }, completion: { finished in
            self.dismiss(animated: false, completion: nil)
        })
    }
}
