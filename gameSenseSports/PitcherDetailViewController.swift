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
        
        let parentViewController = self.navigationController?.viewControllers[0] as! DrillListViewController
        self.selectedListId = parentViewController.selectedListId
        self.pitcher.text = parentViewController.selectedListTitle ?? ""
        self.myDescription.text = parentViewController.selectedListDescription ?? ""
        
        if let urlSrc = parentViewController.selectedListImage {
            let url = URL(string: urlSrc)
            let data = try? Data(contentsOf: url!)
            
            if let imageData = data {
                self.thumbnail.image = UIImage(data: imageData)
            }
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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
        if ((leaderboardScoresArray?.count)! > 0) {
            cellLabel.text = leaderboardScoresArray?[indexPath.row].playerName
        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
}
