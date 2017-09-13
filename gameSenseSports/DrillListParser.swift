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
        drillArray = drillArray.sorted { $0.title.substring(to: $0.title.index($0.title.startIndex, offsetBy: 5)) == $1.title.substring(to: $1.title.index($1.title.startIndex, offsetBy: 5)) ? $0.occlusion < $1.occlusion : $0.title.substring(to: $0.title.index($0.title.startIndex, offsetBy: 5)) < $1.title.substring(to: $1.title.index($1.title.startIndex, offsetBy: 5)) }
        return drillArray
    }
}

struct DrillList {
    let id: Int
    let title: String
    let image: String
    let description: String
    let leaderboardSource: String?
    let difficulty: Int
}

struct DrillListItem {
    let drillID: Int
    var title: String
    let questionCount: Int
    let randomize: Bool
    let primaryList: DrillList
    let occlusion: Int
}

extension DrillListItem {
    init?(json: [String: Any]) {
        let lists = json["lists"] as? [[String: Any]]
        guard let title = json["title"] as? String,
            let drillID = json["id"] as? Int,
            let questionCount = json["number_of_questions"] as? Int,
            let randomize = json["randomize"] as? Bool
            else {
                return nil
        }
        
        self.title = title
        self.drillID = drillID
        self.questionCount = questionCount
        self.randomize = randomize
        if let lists = lists { self.primaryList = DrillList(json: lists)! }
        else { self.primaryList = DrillList()! }
        if title.contains("Advanced") {
            self.occlusion = 3
            self.title = title.replacingOccurrences(of: "- Advanced", with: "")
        } else if title.contains("Full Pitch") {
            self.title = title.replacingOccurrences(of: "- Full Pitch", with: "")
            self.occlusion = 1
        } else if title.contains("Wicked") {
            self.occlusion = 4
            self.title = title.replacingOccurrences(of: "- Wicked", with: "")
        } else {
            self.occlusion = 2
            self.title = title.replacingOccurrences(of: "- Basic", with: "")
        }
    }
}

extension DrillList {
    init?(json: [[String: Any]]? = nil) {
       
        if json == nil || json!.count == 0 {
            self.id = 0
            self.title = "No data."
            self.image = ""
            self.description = ""
            self.leaderboardSource = ""
            self.difficulty = 0
        } else {
            let json = json?.sorted { ($0["title"] as? String)! < ($1["title"] as? String)! }
            guard let id = json![0]["id"] as? Int,
              let title = json![0]["title"] as? String,
                let image = json![0]["image"] as? String,
                let description = json![0]["description"] as? String,
                let difficulty = json![0]["difficulty"] as? Int
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
                    self.difficulty = difficulty
                    return
                }
            self.id = id
            self.title = title
            self.image = image
            self.description = description
            self.leaderboardSource = leaderboardSource
            self.difficulty = difficulty
        }
    }
}
