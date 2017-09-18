//
//  SharedNetworkConnection.swift
//  gameSenseSports
//
//  Created by Ra on 11/22/16.
//  Copyright © 2016 gameSenseSports. All rights reserved.
//

import Foundation

class SharedNetworkConnection: NSObject
{
    static var apiGetDrillListTask: URLSessionDataTask? = nil
    static var apiGetDrillQuestionsTask: URLSessionDataTask? = nil
    static var apiGetDrillVideoTask: URLSessionDataTask? = nil
    static var apiGetLeaderboardScoresTask: URLSessionDataTask? = nil
    
    static func testURL(urlSession: URLSession, urlComponents: URLComponents, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Swift.Void)
    {
        let task = URLSession.shared.dataTask(with: urlComponents.url!, completionHandler: completionHandler)
        task.resume()
    }
    
    static func apiLogin(username: String, password: String, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Swift.Void)
    {
        var request = URLRequest(url: URL(string: Constants.URLs.Login)!)
        let escapedUsername = username.addingPercentEncoding(withAllowedCharacters: .rfc3986Unreserved)!
        request.httpMethod = "POST"
        let postString = "username=" + escapedUsername + "&password=" + password
        request.httpBody = postString.data(using: .utf8)
        let task = URLSession.shared.dataTask(with: request, completionHandler: completionHandler)
        task.resume()
    }
    
    static func apiLoginWithStoredCredentials(completionHandler: @escaping (Data?, URLResponse?, Error?) -> Swift.Void)
    {
        if let userDefault = UserDefaults.standard.object(forKey: Constants.kUsernameKey) as? String {
            if let passwordDefault = UserDefaults.standard.object(forKey: Constants.kPasswordKey) as? String {
                self.apiLogin(username: userDefault, password: passwordDefault, completionHandler: completionHandler)
            }
        }
    }
    
    static func apiGetDrillList(apiToken: String, limit: Int = 0, listId: Int? = nil, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Swift.Void)
    {
        if self.apiGetDrillListTask != nil && self.apiGetDrillListTask?.state != .completed {
            self.apiGetDrillListTask?.cancel()
        }
        var url = (listId == nil) ? Constants.URLs.DrillList : Constants.URLs.DrillListForList
        if listId != nil {
            url += String(listId!) + "/drills/"
        }
        if limit > 0 {
            url += "?limit=" + "\(limit)" + "&ordering=title"
        }
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "GET"
        let apiString = "Token " + apiToken
        request.addValue(apiString, forHTTPHeaderField: "Authorization")
        let task = URLSession.shared.dataTask(with: request, completionHandler: completionHandler)
        task.resume()
        self.apiGetDrillListTask = task
    }

    static func apiGetDrillQuestions(apiToken: String, drillID: Int, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Swift.Void)
    {
        if self.apiGetDrillQuestionsTask != nil && self.apiGetDrillQuestionsTask?.state != .completed {
            self.apiGetDrillQuestionsTask?.cancel()
        }
        var request = URLRequest(url: URL(string: Constants.URLs.DrillQuestions + String(drillID) + "/questions/")!)
        request.httpMethod = "GET"
        let apiString = "Token " + apiToken
        request.addValue(apiString, forHTTPHeaderField: "Authorization")
        let task = URLSession.shared.dataTask(with: request, completionHandler: completionHandler)
        task.resume()
        self.apiGetDrillQuestionsTask = task
    }

    static func apiGetDrillVideo(apiToken: String, responseURI: String, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Swift.Void)
    {
        if self.apiGetDrillVideoTask != nil && self.apiGetDrillVideoTask?.state != .completed {
            self.apiGetDrillVideoTask?.cancel()
        }
        var request = URLRequest(url: URL(string: Constants.URLs.apiBase + responseURI)!)
        let apiString = "Token " + apiToken
        request.addValue(apiString, forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: request, completionHandler: completionHandler)
        task.resume()
        self.apiGetDrillVideoTask = task
    }

    static func apiGetDrillPitchLocation(apiToken: String, responseURI: String, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Swift.Void)
    {
        var request = URLRequest(url: URL(string: Constants.URLs.apiBase + responseURI)!)
        let apiString = "Token " + apiToken
        request.addValue(apiString, forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: request, completionHandler: completionHandler)
        task.resume()
    }
    
    static func apiGetLeaderboardScores(apiToken: String, leaderboardSource: String, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Swift.Void)
    {
        if self.apiGetLeaderboardScoresTask != nil && self.apiGetLeaderboardScoresTask?.state != .completed {
            self.apiGetLeaderboardScoresTask?.cancel()
        }
        var request = URLRequest(url: URL(string: Constants.URLs.apiBase + leaderboardSource)!)
        let apiString = "Token " + apiToken
        request.addValue(apiString, forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: request, completionHandler: completionHandler)
        task.resume()
        self.apiGetLeaderboardScoresTask = task
    }
    
    static func apiPostRegisterDrill(apiToken: String, drillID: Int, drillTitle: String, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Swift.Void)
    {
        var request = URLRequest(url: URL(string: Constants.URLs.apiRegisterDrill)!)
        let apiString = "Token " + apiToken
        request.addValue(apiString, forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField:"Content-Type")
        request.httpMethod = "POST"
        let postString = "drill_id=" + String(drillID) + "&activity_name=\"Drill\"&activity_value=\"" + drillTitle + "\""
        request.httpBody = postString.data(using: .utf8)
        let task = URLSession.shared.dataTask(with: request, completionHandler: completionHandler)
        task.resume()
    }
    
    static func apiPostAnswerQuestion(apiToken: String, correctAnswer: Bool, activityID: Int, questionID: Int, answerID: Int, pitchLocation: String, questionJson: String, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Swift.Void)
    {
        var request = URLRequest(url: URL(string: Constants.URLs.apiAnswerQuestion)!)
        let apiString = "Token " + apiToken
        request.addValue(apiString, forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField:"Content-Type")
        request.httpMethod = "POST"
        var postString = ""
        if (answerID == -1) {
            postString = "activity_id=" + String(activityID) + "&question_id=" + String(questionID) + "&action_name=\"Question Response\"&action_value={\"Response\": null,\"Question\": " + questionJson + "}"        
        }
        else {
            postString = "activity_id=" + String(activityID) + "&question_id=" + String(questionID) + "&action_name=\"Question Response\"&action_value={\"Response\": {\"id\": " + String(answerID) + ", \"name\": \"" + pitchLocation + "\", \"correct\": " + String(correctAnswer) + ", \"incorrect\": " + String(!correctAnswer) + ", \"objName\": \"pitch_location\"},\"Question\": " + questionJson + "}"
        }
        request.httpBody = postString.data(using: .utf8)
        let task = URLSession.shared.dataTask(with: request, completionHandler: completionHandler)
        task.resume()
    }
    
    static func apiDrillFinished(apiToken: String, drill_id: Int, activityID: Int, score: Int, locationScore: Int, typeScore: Int, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Swift.Void)
    {
        var request = URLRequest(url: URL(string: Constants.URLs.apiDrillFinished)!)
        let apiString = "Token " + apiToken
        request.addValue(apiString, forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField:"Content-Type")
        request.httpMethod = "POST"
        let postString = "drill_id=" + String(drill_id) + "&value=" + String(score)
        request.httpBody = postString.data(using: .utf8)
        let task = URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
            guard let data = data, error == nil else {                                                 // check for fundamental networking error
                print("error=\(error)")
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
                // 403 on no token
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(response)")
                
                return
            }
            
            let json = try? JSONSerialization.jsonObject(with: data, options: [])
            if let dictionary = json as? [String: Any] {
                if let scoreID = dictionary["id"] as? (Int) {
                    self.apiDrillFinishedNextCall(apiToken: apiToken, activityID: activityID, scoreID: scoreID, locationScore: locationScore, typeScore: typeScore, totalScore: score, completionHandler: completionHandler)
                }
            }
            
        })
        task.resume()
    }
    
    private static func apiDrillFinishedNextCall(apiToken: String, activityID: Int, scoreID: Int, locationScore: Int, typeScore: Int, totalScore: Int, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Swift.Void)
    {
        var request = URLRequest(url: URL(string: Constants.URLs.apiDrillFinishedNext)!)
        let apiString = "Token " + apiToken
        request.addValue(apiString, forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField:"Content-Type")
        request.httpMethod = "POST"
        let jsonString = "{\"Pitch Location Score\":" + String(locationScore) + ",\"Pitch Type Score\":" + String(typeScore) + ",\"Total Score\":" + String(totalScore) + "}"
        let postString = "activity_id=" + String(activityID) + "&score_id=" + String(scoreID) + "&action_name=Final Score&action_value=" + jsonString
        request.httpBody = postString.data(using: .utf8)
        let task = URLSession.shared.dataTask(with: request, completionHandler: completionHandler)
        task.resume()
    }

    static func downloadVideo(resourceFilename : String, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Swift.Void)
    {
        downloadVideo(resourceFile: Constants.URLs.awsBase + resourceFilename, completionHandler: completionHandler)
    }
    
    static func downloadVideo(resourceFile : String, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Swift.Void)
    {
        var request = URLRequest(url: URL(string: resourceFile)!)
        request.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: request, completionHandler: completionHandler)
        task.resume()
    }
    
    static func downloadCache(completionHandler: @escaping (Data?, URLResponse?, Error?) -> Swift.Void)
    {
        var request = URLRequest(url: URL(string: Constants.URLs.imageCacheZip)!)
        request.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: request, completionHandler: completionHandler)
        task.resume()
    }
}

extension CharacterSet {
    static let rfc3986Unreserved = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
}
