//
//  DrillVideoParser.swift
//  gameSenseSports
//
//  Created by Ra on 11/20/16.
//  Copyright © 2016 gameSenseSports. All rights reserved.
//

import Foundation

class DrillVideoParser : NSObject
{
    let jsonString: String
    
    init?(jsonString: String) {
        self.jsonString = jsonString
    }
    
    func getDrillVideoItem() -> DrillVideoItem
    {
        var drillVideoItem = DrillVideoItem(json: [:])
        let data = self.jsonString.data(using: String.Encoding.utf8, allowLossyConversion: false)!
        let json = try? JSONSerialization.jsonObject(with: data, options: [])
        
        if let dictionary = json as? [String: Any] {
            drillVideoItem = DrillVideoItem(json: dictionary)!
        }
        
        return drillVideoItem!
    }
}

struct DrillVideoItem {
    let file: String
    let drillVideoID: Int
    let pitchTypeID: Int
    let pitchLocationID: Int
    let batterHand: String
}

extension DrillVideoItem {
    init?(json: [String: Any]) {
        guard let drillVideoID = json["id"] as? Int,
            let file = json["file"] as? String,
            let pitchLocationID = json["pitch_location"] as? Int,
            let pitchTypeID = json["pitch_type"] as? Int,
            let batterHand = json["batter_hand"] as? String
            else {
                return nil
        }
        
        self.drillVideoID = drillVideoID
        self.file = file
        self.pitchLocationID = pitchLocationID
        self.pitchTypeID = pitchTypeID
        self.batterHand = batterHand
    }
}
