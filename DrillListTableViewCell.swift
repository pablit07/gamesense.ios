//
//  DrillListTableViewCell.swift
//  gameSenseSports
//
//  Created by Paul Kohlhoff on 6/1/17.
//  Copyright © 2017 gameSenseSports. All rights reserved.
//

import UIKit

class DrillListTableViewCell: UITableViewCell {

    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var startDownload: UIButton!
    @IBAction func startDownloadButtonTap(_ sender: UIButton) {
        self.startDownload.isHidden = true
        if self.drillId != nil {
            self.getDrillListQuestions()
        }
    }
    
    var drillId : Int? = nil
    var numberToDownload = 0
    var completedDownloads = 0
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    
    private func getDrillListQuestions() {
        var drillId = self.drillId!
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        self.progressView.isHidden = false
        self.clearNumberForDownload()
        SharedNetworkConnection.apiGetDrillQuestions(apiToken: appDelegate.apiToken, drillID: drillId, completionHandler: { data, response, error in
            guard let data = data, error == nil else {                                                 // check for fundamental networking error
                print("error=\(error)")
                return
            }
            
            var drillQuestionsParser = DrillQuestionParser(jsonString: String(data: data, encoding: .utf8)!)
            var drillQuestionsArray = (drillQuestionsParser?.getDrillQuestionArray())!
            self.updateNumberForDownload(numberForDownload: (drillQuestionsArray.count * 2))
            var filenameArray = [String]()
            for drillQuestion in drillQuestionsArray {
                filenameArray.append(drillQuestion.occludedVideo)
                filenameArray.append(drillQuestion.fullVideo)
            }
            for filename in filenameArray {
                DispatchQueue.main.async {
                    var cacheDirectory = try! FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                    cacheDirectory.appendPathComponent(filename)
                    SharedNetworkConnection.downloadVideo(resourceFilename: filename, completionHandler: { data, response, error in
                        guard let data = data, error == nil else {                                                 // check for fundamental networking error
                            print("error=\(error)")
                            return
                        }
                        
                        if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
                            // 403 on no token
                            print("statusCode should be 200, but is \(httpStatus.statusCode)")
                            print("response = \(response)")
                        }
                        
                        try? data.write(to: cacheDirectory)
                        DispatchQueue.main.async { self.updateNumberDownloaded() }
                    })
                }
            }
            
        })
    }
    
    private func updateNumberForDownload(numberForDownload: Int) {
        self.numberToDownload = numberForDownload
    }
    
    private func updateNumberDownloaded() {
        self.completedDownloads += 1
        let progress = (Float(self.completedDownloads) / Float(self.numberToDownload))
        self.progressView.setProgress(progress, animated: true)
        if self.completedDownloads == self.numberToDownload {
            self.clearNumberForDownload()
            self.progressView.isHidden = true
        }
    }
    
    private func clearNumberForDownload() {
        self.progressView.progress = 0
        self.numberToDownload = 0
    }
}
