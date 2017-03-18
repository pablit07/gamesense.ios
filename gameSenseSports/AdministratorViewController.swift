//
//  AdministratorViewController.swift
//  gameSenseSports
//
//  Created by Ra on 3/15/17.
//  Copyright © 2017 gameSenseSports. All rights reserved.
//

import Foundation
import UIKit
import AWSS3

class AdministratorViewController: UIViewController, URLSessionTaskDelegate {

    
    @IBOutlet weak var teamName: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if (UserDefaults.standard.object(forKey: Constants.kTeamKey) == nil)
        {
            teamName.text = "GameSenseSports"
        }
        else
        {
            teamName.text = UserDefaults.standard.string(forKey: Constants.kTeamKey)
        }
    }

    
    
    @IBAction func uploadFile(_ sender: Any) {
        let getPreSignedURLRequest = AWSS3GetPreSignedURLRequest()
        let timestamp = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT") //Set timezone that you want
        dateFormatter.locale = NSLocale.current
        dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm"
        var teamName = ""
        if UserDefaults.standard.string(forKey: Constants.kTeamKey) != nil {
            teamName = UserDefaults.standard.string(forKey: Constants.kTeamKey)!
        }        
        getPreSignedURLRequest.bucket = "gamesense-test-responses"
        getPreSignedURLRequest.key = teamName + dateFormatter.string(from: timestamp)
        getPreSignedURLRequest.httpMethod = .PUT
        getPreSignedURLRequest.expires = Date(timeIntervalSinceNow: 360000)
        
        //Important: set contentType for a PUT request.
        let fileContentTypeStr = "text/plain"
        getPreSignedURLRequest.contentType = fileContentTypeStr
        
        AWSS3PreSignedURLBuilder.default().getPreSignedURL(getPreSignedURLRequest).continueWith { (task:AWSTask<NSURL>) -> Any? in
            if let error = task.error as? NSError {
                print("Error: \(error)")
                return nil
            }
            
            let presignedURL = task.result
            print("Download presignedURL is: \(presignedURL)")
            
            var request = URLRequest(url: presignedURL as! URL)
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.httpMethod = "PUT"
            request.setValue(fileContentTypeStr, forHTTPHeaderField: "Content-Type")
            
            let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("answers.txt")
            
            let uploadTask: URLSessionTask = URLSession.shared.uploadTask(with: request, fromFile: URL(fileURLWithPath: fileURL.path), completionHandler: {(data, response, error) -> Void in
                if (error != nil) {
                    print("Error")
                }
                print("Complete")})
            
            
            uploadTask.resume()
            
            return nil
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        print("progress..")
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError: Error?) {
        print("error!")
    }
    
    @IBAction func closeModal(_ sender: Any) {
        UserDefaults.standard.set(teamName.text, forKey: Constants.kTeamKey)
        self.dismiss(animated: true, completion: nil)
    }
}
