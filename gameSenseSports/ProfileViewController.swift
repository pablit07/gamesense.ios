//
//  ProfileViewController.swift
//  gameSenseSports
//
//  Created by Ra on 8/14/17.
//  Copyright © 2017 gameSenseSports. All rights reserved.
//

import UIKit

enum NavOrder: Int {
    case home = 0
    case account = 1
    case userGuide = 2
    case myScores = 3
    case logout = 4
}

class ProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var menuView: UIView!
    public var selected = 0
    var animated = false
    
    @IBOutlet weak var tableView: UITableView!
    var soundSwitch: UISwitch!
    @IBOutlet weak var username: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.soundSwitch = UISwitch(frame: CGRect(x: 30, y: 8, width: 39, height: 41))
        self.soundSwitch.addTarget(self, action: #selector(changeSwitch(_:)), for: .valueChanged)
        self.soundSwitch.isOn = UserDefaults.standard.object(forKey: Constants.kSound) as? Int == 1
        
        self.tableView.tableFooterView = self.getFooter()
        
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
        return 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "menuCell", for: indexPath)
        let label = cell.viewWithTag(2) as! UILabel
        let icon = cell.viewWithTag(1) as! UIImageView
        switch (NavOrder(rawValue: indexPath.row)!) {
        case NavOrder.home:
            label.text = "Home"
            let image = UIImage(named:"home.png")
            icon.image = image
            break
        case NavOrder.account:
            label.text = "Account"
            let image = UIImage(named:"account.png")
            icon.image = image
            break
        case NavOrder.userGuide:
            label.text = "User Guide"
            let image = UIImage(named:"tutorial-icon.png")
            icon.image = image
            break
        case NavOrder.myScores:
            label.text = "My Scores"
            let image = UIImage(named:"charts.png")
            icon.image = image
            break
        case NavOrder.logout:
            label.text = "Log Out"
            let image = UIImage(named:"logout.png")
            icon.image = image
            break
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //Home
        let row = NavOrder(rawValue: indexPath.row)
        if (row == NavOrder.home) {
            let presentingViewController = self.presentingViewController as! UINavigationController
            var rootDrillListViewController: DrillListViewController?
            
            for vc in presentingViewController.viewControllers.reversed() {
                if vc is DrillListViewController {
                    rootDrillListViewController = vc as? DrillListViewController
                }
            }
            presentingViewController.popToViewController(rootDrillListViewController!, animated: false)
            self.dismissMenu()
        }
        
        // Safari
        if row == NavOrder.account || row == NavOrder.myScores {
            var url = ""
            switch row! {
            case NavOrder.account:
                url = "https://app.gamesensesports.com/dashboard/subscriptions"
                break
            case NavOrder.myScores:
                url = "https://app.gamesensesports.com/dashboard/score-chart"
                break
            default:
                break
            }
            
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(NSURL(string:url)! as URL, options: [:], completionHandler: nil)
            } else {
                // Fallback on earlier versions
                UIApplication.shared.openURL(NSURL(string:url)! as URL)
            }
        }
        
        //Web View (not used)
//        if (false) {
//            self.selected = indexPath.row
//            self.performSegue(withIdentifier: "profileWebview", sender: nil)
//        }
        
        //User Guide
        if (row == NavOrder.userGuide) {
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "userguide", sender: self)
            }
        }
        
        //Logout
        if (row == NavOrder.logout) {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.apiToken = ""
            self.view.window!.rootViewController?.dismiss(animated: false, completion: nil)
        }
    }
    
    func getFooter() -> UIView? {
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: 171, height: 50))
        
        
        footerView.addSubview(self.soundSwitch)
        
        let soundLabel = UILabel(frame: CGRect(x: 85, y: 14, width: 50, height: 21))
        soundLabel.text = "Sound"
        soundLabel.textColor = UIColor.white
        footerView.addSubview(soundLabel)
        
        return footerView
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func dismissMenu(sender: UIButton) {
        self.dismissMenu()
    }
    
    @IBAction func changeSwitch(_ sender: UISwitch) {
        if sender.isOn {
            UserDefaults.standard.setValue(1, forKey: Constants.kSound)
        } else {
            UserDefaults.standard.setValue(0, forKey: Constants.kSound)
        }
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
