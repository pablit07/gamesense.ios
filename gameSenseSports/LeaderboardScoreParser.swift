//
//  LeaderboardScoreParser.swift
//  gameSenseSports
//
//  Created by Paul Kohlhoff on 8/22/17.
//  Copyright © 2017 gameSenseSports. All rights reserved.
//

import Foundation

class LeaderboardScoreParser : NSObject
{
    let jsonString: String
    var recordCount : Int
    
    init?(jsonString: String) {
        self.jsonString = jsonString
        self.recordCount = 0;
    }
    
    func getArray() -> Array<LeaderboardItem>
    {
        var drillArray = [LeaderboardItem]()
        
        let data = self.jsonString.data(using: String.Encoding.utf8, allowLossyConversion: false)!
        let json = try? JSONSerialization.jsonObject(with: data, options: [])
        
        if let dictionary = json as? [String: Any] {
            if let recordCount = dictionary["count"] as? (Int) {
                self.recordCount = recordCount
            }
            if let array = dictionary["results"] as? [Any] {
                for object in array {
                    // access all objects in array
                    let drillListItem = LeaderboardItem(json: object as! [String : Any]);
                    drillArray.append(drillListItem!)
                }
            }
        }
        return drillArray
    }
}

struct LeaderboardItem {
    let playerName : String
}

extension LeaderboardItem {
    init?(json: [String: Any]? = nil) {

        guard let playerName = json?["playerName"] as? String
        else {
            return nil
        }
        self.playerName = playerName
    }
}
