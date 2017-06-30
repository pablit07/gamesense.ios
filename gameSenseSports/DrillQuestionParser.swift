//
//  DrillQuestionParser.swift
//  gameSenseSports
//
//  Created by Ra on 11/19/16.
//  Copyright © 2016 gameSenseSports. All rights reserved.
//

import Foundation

class DrillQuestionParser : NSObject
{
    let jsonString: String
    var randomize : Bool
    var recordCount : Int
    
    init?(jsonString: String) {
        self.jsonString = jsonString
        self.recordCount = 0
        self.randomize = false
    }

    func getDrillQuestionArray() -> Array<DrillQuestionItem>
    {
        var drillQuestionArray = [DrillQuestionItem]()
        
        let data = self.jsonString.data(using: String.Encoding.utf8, allowLossyConversion: false)!
        let json = try? JSONSerialization.jsonObject(with: data, options: [])
        
        if let dictionary = json as? [String: Any] {
            if let recordCount = dictionary["count"] as? (Int) {
                self.recordCount = recordCount
            }
            if let array = dictionary["results"] as? [Any] {
                for object in array {
                    // access all objects in array
                    let drillQuestionItem = DrillQuestionItem(json: object as! [String : Any])
                    if drillQuestionItem != nil {
                        drillQuestionArray.append(drillQuestionItem!)
                    }
                }
            }
        }
        return drillQuestionArray
    }
}

struct DrillQuestionItem
{
    let fullJson: String
    let drillQuestionID: Int
    let occludedVideo: String
    let fullVideo: String
    let answerURL: String
    let responseURI0: String
    let responseURI1: String
}

extension DrillQuestionItem {
    init?(json: [String: Any]) {
        guard let drillQuestionID = json["id"] as? Int,
        let occludedVideo = json["occluded_video_file"] as? String,
        let fullVideo = json["full_video_file"] as? String,
        let answerURL = json["full_video"] as? String,
        let responseURIs = json["response_uris"] as? [Any]
            else {
                return nil
        }
        
        self.drillQuestionID = drillQuestionID
        self.occludedVideo = occludedVideo
        self.fullVideo = fullVideo
        self.answerURL = answerURL
        self.responseURI0 = responseURIs[0] as! String
        self.responseURI1 = responseURIs[1] as! String
        self.fullJson = try! String(data:JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),encoding: String.Encoding.utf8)!
    }
}

extension MutableCollection where Indices.Iterator.Element == Index {
    /// Shuffles the contents of this collection.
    mutating func shuffle() {
        let c = count
        guard c > 1 else { return }
        
        for (firstUnshuffled , unshuffledCount) in zip(indices, stride(from: c, to: 1, by: -1)) {
            let d: IndexDistance = numericCast(arc4random_uniform(numericCast(unshuffledCount)))
            guard d != 0 else { continue }
            let i = index(firstUnshuffled, offsetBy: d)
            swap(&self[firstUnshuffled], &self[i])
        }
    }
}

extension Sequence {
    /// Returns an array with the contents of this sequence, shuffled.
    func shuffled() -> [Iterator.Element] {
        var result = Array(self)
        result.shuffle()
        return result
    }
}

