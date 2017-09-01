//
//  DrillListViewController.swift
//  gameSenseSports
//
//  Created by Ra on 11/15/16.
//  Copyright © 2016 gameSenseSports. All rights reserved.
//

import UIKit

class DrillListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate  {
    
    
    @IBOutlet weak var drillTableView: UITableView!
    @IBOutlet weak var logo: UIImageView!
    
    private var drillListParser = DrillListParser(jsonString: "")
    private var drillListArray = [DrillListItem]()
    private var _selectedDrillItem = DrillListItem(json: [:])
    public var selectedDrillItem : DrillListItem {
        set(value)
        {
            _selectedDrillItem = value
        }
        get {
            return _selectedDrillItem!
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        let verticalClass = self.traitCollection.verticalSizeClass
        let isLandscape = verticalClass == UIUserInterfaceSizeClass.compact
        if isLandscape {
            self.logo.isHidden = true
        } else {
            self.logo.isHidden = false
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.navigationController?.navigationBar.topItem?.title = "Drill List";
        drillTableView.dataSource = self
        drillTableView.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        getDrillList(optimize: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func numberOfSectionsInTableView(in tableView: UITableView) -> Int {
        return 1
    }

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if ((drillListParser?.getDrillListArray().count)! > 0) {
            return (drillListParser?.getDrillListArray().count)!
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "drillCell", for: indexPath)
        let cellLabel = cell.viewWithTag(1) as! UILabel
        if (drillListArray.count > 0) {
            cellLabel.text = drillListArray[indexPath.row].title
        }
        else {
            cellLabel.text = ""
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedDrillItem = drillListArray[indexPath.row]
    }

    
    private func getDrillList(optimize: Bool = false)
    {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        SharedNetworkConnection.apiGetDrillList(apiToken: appDelegate.apiToken, limit: (optimize ? 10 : 0), completionHandler: { data, response, error in
            guard let data = data, error == nil else {                                                 // check for fundamental networking error
                print("error=\(error)")
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
                // 403 on no token
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(response)")
                
                SharedNetworkConnection.apiLoginWithStoredCredentials(completionHandler: { data, response, error in
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    let json = try? JSONSerialization.jsonObject(with: data!, options: [])
                    if let dictionary = json as? [String: Any] {
                        if let apiToken = dictionary["token"] as? (String) {
                            appDelegate.apiToken = apiToken
                            self.getDrillList()
                        }
                    }
                })
                return
            }
            
            self.drillListParser = DrillListParser(jsonString: String(data: data, encoding: .utf8)!)
            self.drillListArray = (self.drillListParser?.getDrillListArray())!
            DispatchQueue.main.async {
                self.drillTableView.reloadData()
            }
            
            if optimize {
                self.getDrillList()
            }
        })
    }
    @IBAction func navSignOutPressed(_ sender: AnyObject) {
        // Logout
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.apiToken = ""
        self.dismiss(animated: true, completion: {})
    }
    
}
