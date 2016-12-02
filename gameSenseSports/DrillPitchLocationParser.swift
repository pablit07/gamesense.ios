//
//  DrillPitchLocationParser.swift
//  gameSenseSports
//
//  Created by Ra on 11/20/16.
//  Copyright © 2016 gameSenseSports. All rights reserved.
//

import Foundation

class DrillPitchLocationParser : NSObject
{
    let jsonString: String
    var recordCount : Int
    
    init?(jsonString: String) {
        self.jsonString = jsonString
        self.recordCount = 0;
    }
    
    func getDrillVideoPitchLocationArray() -> Array<DrillPitchLocationItem>
    {
        var drillArray = [DrillPitchLocationItem]()
        
        let data = self.jsonString.data(using: String.Encoding.utf8, allowLossyConversion: false)!
        let json = try? JSONSerialization.jsonObject(with: data, options: [])
        
        if let dictionary = json as? [String: Any] {
            if let recordCount = dictionary["count"] as? (Int) {
                self.recordCount = recordCount
            }
            if let array = dictionary["results"] as? [Any] {
                for object in array {
                    // access all objects in array
                    let drillListItem = DrillPitchLocationItem(json: object as! [String : Any]);
                    drillArray.append(drillListItem!)
                }
            }
        }
        return drillArray
    }
}


struct DrillPitchLocationItem {
    let drillPitchID: Int
    let name: String
}

extension DrillPitchLocationItem {
    init?(json: [String: Any]) {
        guard let drillPitchID = json["id"] as? Int,
            let name = json["name"] as? String
            else {
                return nil
        }
        
        self.drillPitchID = drillPitchID
        self.name = name
    }
}
