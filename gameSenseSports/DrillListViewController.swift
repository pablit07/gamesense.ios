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
    private var drillListCacheData:DrillListTableViewData? = nil
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
        getDrillList()
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
        let drillTableCell = (cell as? DrillListTableViewCell)
        let cellLabel = cell.viewWithTag(1) as! UILabel
        if (drillListArray.count > 0) {
            cellLabel.text = drillListArray[indexPath.row].title
            drillTableCell?.title = drillListArray[indexPath.row].title
            drillTableCell?.drillId = drillListArray[indexPath.row].drillID
        }
        else {
            cellLabel.text = ""
        }
        // set up view state for each reusable cell
        drillTableCell?.cacheData = drillListCacheData
        drillTableCell?.progressView.isHidden = (drillListCacheData?.cacheFlags[indexPath.row].numberToDownload)! == 0
        drillTableCell?.startDownload.isHidden = !(drillTableCell?.progressView.isHidden)!
        drillListCacheData?.checkCache(drillId: drillTableCell?.drillId, index: indexPath.row, update: (drillTableCell?.updateIsCached)!)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedDrillItem = drillListArray[indexPath.row]
    }
    
    private func showAlert(alert: UIAlertController) {
        self.present(alert, animated: true, completion: nil)
    }

    
    private func getDrillList()
    {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        SharedNetworkConnection.apiGetDrillList(apiToken: appDelegate.apiToken, completionHandler: { data, response, error in
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
            // initialize cache data on startup
            self.drillListCacheData = DrillListTableViewData(cacheFlags: self.drillListArray.map { d in DrillListCellCacheModel(drillId: d.drillID) }, parentController: self)
            DispatchQueue.main.async {
                self.drillTableView.reloadData()
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

class DrillListCellCacheModel {
    var isCached = false
    let drillId: Int?
    var numberToDownload = 0
    var completedDownloads = 0
    
    init(drillId: Int?) {
        self.drillId = drillId
    }
    
    func clearNumberForDownload() {
        self.numberToDownload = 0
    }
}

class DrillListTableViewData {
    var cacheFlags: [DrillListCellCacheModel]
    var errorAlert = UIAlertController(title: "Download Failed", message: "", preferredStyle: .alert)
    var parentController:DrillListViewController
    
    init(cacheFlags: [DrillListCellCacheModel], parentController: DrillListViewController) {
        self.cacheFlags = cacheFlags
        self.parentController = parentController
    }
    
    func checkCache(drillId: Int?, index: Int, update: @escaping (_ isCached:Bool)->()) {
        let isCached = self.cacheFlags[index].isCached
        
        if isCached {
            update(true)
            return
        }
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        SharedNetworkConnection.apiGetDrillQuestions(apiToken: appDelegate.apiToken, drillID: drillId!, completionHandler: { data, response, error in
            guard let data = data, error == nil else {                                                 // check for fundamental networking error
                print("error=\(error)")
                return
            }
            
            let drillQuestionsParser = DrillQuestionParser(jsonString: String(data: data, encoding: .utf8)!)
            let drillQuestionsArray = (drillQuestionsParser?.getDrillQuestionArray())!
            var filenameArray = [String]()
            for drillQuestion in drillQuestionsArray {
                filenameArray.append(drillQuestion.occludedVideo)
            }
            for filename in filenameArray {
                DispatchQueue.main.async {
                    var cacheDirectory = try! FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                    cacheDirectory.appendPathComponent(filename)
                    if (!FileManager.default.fileExists(atPath: cacheDirectory.path)) {
                        self.cacheFlags[index].isCached = false
                        update(false)
                    } else {
                        self.cacheFlags[index].isCached = true
                        update(true)
                    }
                }
            }
        })
    }
    
    func populateCache(drillId: Int?, progress: @escaping (_ numberToDownload:Float, _ completedDownloads:Float)->(), onerror: @escaping (_:UIAlertController, _:DrillListViewController)->()) {
        var cellCache = self.cacheFlags.first(where: {$0.drillId == drillId!})
        cellCache?.clearNumberForDownload()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        SharedNetworkConnection.apiGetDrillQuestions(apiToken: appDelegate.apiToken, drillID: drillId!, completionHandler: { data, response, error in
            guard let data = data, error == nil else {                                                 // check for fundamental networking error
                print("error=\(error)")
                return
            }
            
            let drillQuestionsParser = DrillQuestionParser(jsonString: String(data: data, encoding: .utf8)!)
            let drillQuestionsArray = (drillQuestionsParser?.getDrillQuestionArray())!
            cellCache?.numberToDownload = drillQuestionsArray.count * 2
            progress(Float((cellCache?.numberToDownload)!), Float((cellCache?.completedDownloads)!))
            var filenameArray = [String]()
            for drillQuestion in drillQuestionsArray {
                filenameArray.append(drillQuestion.occludedVideo)
                filenameArray.append(drillQuestion.fullVideo)
            }
            for filename in filenameArray {
                var cacheDirectory = try! FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                cacheDirectory.appendPathComponent(filename)
                SharedNetworkConnection.downloadVideo(resourceFilename: filename, completionHandler: { data, response, error in
                    guard let data = data, error == nil else {                                                 // check for fundamental networking error
                        print("error=\(error)")
                        onerror(self.errorAlert, self.parentController)
                        return
                    }
                    
                    if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
                        // 403 on no token
                        print("statusCode should be 200, but is \(httpStatus.statusCode)")
                        print("response = \(response)")
                    }
                    
                    try? data.write(to: cacheDirectory)

                    cellCache?.completedDownloads += 1
                    DispatchQueue.main.async {
                        progress(Float((cellCache?.numberToDownload)!), Float((cellCache?.completedDownloads)!))
                        if cellCache?.numberToDownload == cellCache?.completedDownloads {
                            cellCache?.isCached = true
                            cellCache?.clearNumberForDownload()
                        }
                    }
                })
            }
            
        })
    }
}
