//
//  PitcherDetailViewController.swift
//  gameSenseSports
//
//  Created by Paul Kohlhoff on 8/20/17.
//  Copyright © 2017 gameSenseSports. All rights reserved.
//

import UIKit

class PitcherDetailViewController : UIViewController, UITableViewDataSource, UITableViewDelegate
{
    @IBOutlet weak var myDescription: UILabel!
    @IBOutlet weak var pitcher: UILabel!
    @IBOutlet weak var thumbnail: UIImageView!
    @IBOutlet weak var leaderboardTable: UITableView!
    
    var selectedListId : Int? = 0
    
    var leaderboardScoresParser : LeaderboardScoreParser? = nil
    var leaderboardScoresArray : [LeaderboardItem]? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.leaderboardTable.dataSource = self
        self.leaderboardTable.delegate = self
        let swipeRight = UISwipeGestureRecognizer(target: self, action:#selector(self.swipeRightWithGestureRecognizer))
        swipeRight.direction = .right;
        self.view.addGestureRecognizer(swipeRight)
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(self.swipeLeftWithGestureRecognizer))
        swipeLeft.direction = .left;
        self.view.addGestureRecognizer(swipeLeft)
        
        resetView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        getLeaderboard()
        
        let tracker = GAI.sharedInstance().defaultTracker
        tracker?.set(kGAIScreenName, value: "/pitcherdetail/\(String(describing: self.selectedListId))")
        let build = (GAIDictionaryBuilder.createScreenView().build() as NSDictionary) as! [AnyHashable: Any]
        tracker?.send(build)
    }
    
    func resetView() {
        let parentViewController = self.navigationController?.viewControllers[0] as! DrillListViewController
        self.leaderboardScoresArray?.removeAll()
        self.selectedListId = parentViewController.selectedListId
        self.pitcher.text = parentViewController.selectedListTitle ?? ""
        self.myDescription.text = parentViewController.selectedListDescription ?? ""
        
        if let urlSrc = parentViewController.selectedListImage {
            if urlSrc != "" {
                let url = URL(string: urlSrc)
                let data = try? Data(contentsOf: url!)
                
                if let imageData = data {
                    self.thumbnail.image = UIImage(data: imageData)
                }
            }
        }
    }
    
    func getLeaderboard() {
        let parentViewController = self.navigationController?.viewControllers[0] as! DrillListViewController
        
        // fire leaderboard scores request
        // on return, populate table
        if let selectedListLeaderboardSource = parentViewController.selectedListLeaderboardSource {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            SharedNetworkConnection.apiGetLeaderboardScores(apiToken: appDelegate.apiToken, leaderboardSource: selectedListLeaderboardSource, completionHandler: { data, response, error in
                
                guard let data = data, error == nil else {                                                 // check for fundamental networking error
                    print("error=\(error)")
                    return
                }
                
                self.leaderboardScoresParser = LeaderboardScoreParser(jsonString: String(data: data, encoding: .utf8)!)
                self.leaderboardScoresArray = self.leaderboardScoresParser?.getArray()
                //
                DispatchQueue.main.async {
                    self.leaderboardTable.reloadData()
                }
            })
        }
    }
    
    
    func numberOfSectionsInTableView(in tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if leaderboardScoresArray != nil && leaderboardScoresArray?.count != 0 {
            return (leaderboardScoresArray?.count)!
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "leaderboardScoreCell", for: indexPath)
        
        let cellLabel = cell.viewWithTag(1) as! UILabel
        let scoreLabel = cell.viewWithTag(2) as! UILabel
        if ((leaderboardScoresArray?.count)! > 0) {
            let row = self.leaderboardScoresArray?[indexPath.row]
            let score = "\(row!.score)"
            cellLabel.text = row?.playerName
            scoreLabel.text = score
        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
    @IBAction func testNext(_ sender: UIButton) {

    }
    
    @IBAction func  swipeRightWithGestureRecognizer(gestureRecognizer:UISwipeGestureRecognizer)
    {
        let parentViewController = self.navigationController?.viewControllers[0] as! DrillListViewController
        parentViewController.selectPreviousListId()
        resetView()
        getLeaderboard()
    }
    
    @IBAction func swipeLeftWithGestureRecognizer(gestureRecognizer:UISwipeGestureRecognizer)
    {
        let parentViewController = self.navigationController?.viewControllers[0] as! DrillListViewController
        parentViewController.selectNextListId()
        resetView()
        getLeaderboard()
    }

}
