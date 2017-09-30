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
    private var drillListMap = [String:[DrillListItem]]()
    private var _selectedDrillItem = DrillListItem(json: [:])
    private var listId: Int?
    public var selectedDrillItem : DrillListItem {
        set(value)
        {
            _selectedDrillItem = value
        }
        get {
            return _selectedDrillItem!
        }
    }
    public var selectedListId : Int? = -1
    public var selectedListTitle : String? = ""
    public var selectedListImage : String? = ""
    public var selectedListDescription : String? = ""
    public var selectedListLeaderboardSource : String? = ""
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.navigationController?.navigationBar.topItem?.title = "Drill List";
        drillTableView.dataSource = self
        drillTableView.delegate = self
        getDrillList(optimize: true)
        checkSegueToUserGuide()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func getDrillListMap(drillListArray: [DrillListItem]) -> [String:[DrillListItem]] {
        var map = [String:[DrillListItem]]()
        for item in drillListArray {
            let index = String(item.title[item.title.startIndex])
            if (map[index] != nil) {
                map[index]?.append(item)
            } else {
                map[index] = [DrillListItem]()
                map[index]?.append(item)
            }
        }
        return map
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if self.listId != nil || self.drillListArray.count < 15 {
            return 1
        }
        return self.drillListMap.keys.count
    }
    
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return index
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if ((drillListArray.count) > 0) {
            if self.listId != nil || self.drillListArray.count < 15 {
                return drillListArray.count
            }
            return drillListMap[drillListMap.keys.sorted()[section]]!.count
        }
        return 0
    }
    
    private func tableViewWithListId(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "drillCell", for: indexPath)
        let drillTableCell = (cell as? DrillListTableViewCell)
        let cellLabel = cell.viewWithTag(1) as! UILabel
        if (drillListArray.count > 0) {
            cellLabel.text = drillListArray[indexPath.row].title
            drillTableCell?.drillId = drillListArray[indexPath.row].drillID
            drillTableCell?.drillList = drillListArray[indexPath.row].primaryList
            drillTableCell?.difficulty = drillListArray[indexPath.row].primaryList.difficulty
            drillTableCell?.occlusion = drillListArray[indexPath.row].occlusion
        }
        else {
            cellLabel.text = ""
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if self.listId != nil || self.drillListArray.count < 15 {
            return tableViewWithListId(tableView, cellForRowAt: indexPath)
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "drillCell", for: indexPath)
        let drillTableCell = (cell as? DrillListTableViewCell)
        let cellLabel = cell.viewWithTag(1) as! UILabel
        if (drillListArray.count > 0) {
//            let drillCell = drillListArray[indexPath.row]
            let drillCell = drillListMap[drillListMap.keys.sorted()[indexPath.section]]?[indexPath.row]
            cellLabel.text = drillCell?.title
            drillTableCell?.drillId = drillCell?.drillID
            drillTableCell?.drillList = drillCell?.primaryList
            drillTableCell?.difficulty = (drillCell?.primaryList.difficulty)!
            drillTableCell?.occlusion = (drillCell?.occlusion)!
        }
        else {
            cellLabel.text = ""
        }
        return cell
    }

    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if self.listId != nil || self.drillListArray.count < 15 {
            return nil
        }
        return [String](self.drillListMap.keys).sorted()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.listId != nil || self.drillListArray.count < 15 {
            self.selectedDrillItem = drillListArray[indexPath.row]
        } else {
            self.selectedDrillItem = (drillListMap[drillListMap.keys.sorted()[indexPath.section]]?[indexPath.row])!
       }
    }

    
    private func getDrillList(optimize: Bool = false)
    {
        self.listId = nil
        // get the list id if receiving from pitcher detail
        for vc in (self.navigationController?.viewControllers)! {
            if let pitcherDetailViewController = vc as? PitcherDetailViewController {
                if pitcherDetailViewController.selectedListId != -1 {
                    self.listId = pitcherDetailViewController.selectedListId
                }
            }
        }
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        SharedNetworkConnection.apiGetDrillList(apiToken: appDelegate.apiToken, limit: (optimize ? 13 : 0), listId: listId, completionHandler: { data, response, error in
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
            self.drillListMap = self.getDrillListMap(drillListArray: self.drillListArray)
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
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let id = segue.identifier
        if id == "pitcherdetail" {
            let buttonView = (sender as! UIPitcherListButton)
            setDrillList(drillList: buttonView.drillList)
        } else if id == "VideoPlayer" {
            SharedNetworkConnection.apiGetDrillListTask?.cancel()
        }
    }
    
    func setDrillList(drillList: DrillList?) {
        self.selectedListId = drillList?.id
        self.selectedListTitle = drillList?.title
        self.selectedListImage = drillList?.image
        self.selectedListDescription = drillList?.description
        self.selectedListLeaderboardSource = drillList?.leaderboardSource
    }
    
    public func selectNextListId() {
        var index = self.drillListArray.index(where: {$0.primaryList.id == self.selectedListId})!
        while self.drillListArray[index].primaryList.id == self.selectedListId ||
              self.drillListArray[index].primaryList.id == 0 ||
              // remove "All gS Drills"
              self.drillListArray[index].primaryList.id == 20 {
            index = self.drillListArray.index(after: index)
            if index == self.drillListArray.count {
                index = 0
            }
        }
        let item = self.drillListArray[index]
        setDrillList(drillList: item.primaryList)
    }
    
    public func selectPreviousListId() {
        var index = self.drillListArray.index(where: {$0.primaryList.id == self.selectedListId})!
        while self.drillListArray[index].primaryList.id == self.selectedListId ||
            self.drillListArray[index].primaryList.id == 0 ||
            // remove "All gS Drills"
            self.drillListArray[index].primaryList.id == 20 {
                index = self.drillListArray.index(before: index)
                if index == -1 {
                    index = self.drillListArray.count - 1
                }
        }
        let item = self.drillListArray[index]
        setDrillList(drillList: item.primaryList)
    }
    
    private func checkSegueToUserGuide() {
        if UserDefaults.standard.object(forKey: Constants.kHasSeenUserGuide) as? Int != 1 {
            UserDefaults.standard.setValue(1, forKey: Constants.kHasSeenUserGuide)
            performSegue(withIdentifier: "userguidewelcome", sender: self)
        }
    }
    
}

class UIPitcherListButton : UIButton
{
    var drillList : DrillList? = nil
}
