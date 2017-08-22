//
//  DrillListParser.swift
//  gameSenseSports
//
//  Created by Ra on 11/19/16.
//  Copyright © 2016 gameSenseSports. All rights reserved.
//

import Foundation

class DrillListParser : NSObject
{
    let jsonString: String
    var recordCount : Int
    
    init?(jsonString: String) {
        self.jsonString = jsonString
        self.recordCount = 0;
    }

    func getDrillListArray() -> Array<DrillListItem>
    {
        var drillArray = [DrillListItem]()
        
        let data = self.jsonString.data(using: String.Encoding.utf8, allowLossyConversion: false)!
        let json = try? JSONSerialization.jsonObject(with: data, options: [])
        
        if let dictionary = json as? [String: Any] {
            if let recordCount = dictionary["count"] as? (Int) {
                self.recordCount = recordCount
            }
            if let array = dictionary["results"] as? [Any] {
                for object in array {
                    // access all objects in array
                    let drillListItem = DrillListItem(json: object as! [String : Any]);
                    drillArray.append(drillListItem!)
                }
            }
        }
        drillArray = drillArray.sorted { $0.title < $1.title }
        return drillArray
    }
}

struct DrillList {
    let id: Int
    let title: String
    let image: String
    let description: String
    let leaderboardSource: String?
}

struct DrillListItem {
    let url: String
    let drillID: Int
    let title: String
    let questionCount: Int
    let randomize: Bool
    let primaryList: DrillList
}

extension DrillListItem {
    init?(json: [String: Any]) {
        let lists = json["lists"] as? [[String: Any]]
        guard let url = json["url"] as? String,
            let title = json["title"] as? String,
            let drillID = json["id"] as? Int,
            let questionCount = json["number_of_questions"] as? Int,
            let randomize = json["randomize"] as? Bool,
            let primaryList = DrillList(json: lists)
            else {
                return nil
        }
        
        self.url = url
        self.title = title
        self.drillID = drillID
        self.questionCount = questionCount
        self.randomize = randomize
        self.primaryList = primaryList
    }
}

extension DrillList {
    init?(json: [[String: Any]]? = nil) {
        if json == nil || json!.count == 0 {
            self.id = 0
            self.title = "TEST"
            self.image = ""
            self.description = ""
            self.leaderboardSource = ""
        } else {        
            guard let id = json![0]["id"] as? Int,
              let title = json![0]["title"] as? String,
                let image = json![0]["image"] as? String,
                let description = json![0]["description"] as? String
                else {
                    return nil
            }
            guard let leaderboardSource = json![0]["leaderboard_scores_source"] as? String
                else {
                    self.id = id
                    self.title = title
                    self.image = image
                    self.description = description
                    self.leaderboardSource = nil
                    return
                }
            self.id = id
            self.title = title
            self.image = image
            self.description = description
            self.leaderboardSource = leaderboardSource
        }
    }
}
