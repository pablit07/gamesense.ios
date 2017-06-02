//
//  DrillListTableViewCell.swift
//  gameSenseSports
//
//  Created by Paul Kohlhoff on 6/1/17.
//  Copyright © 2017 gameSenseSports. All rights reserved.
//

import UIKit

class DrillListTableViewCell: UITableViewCell {

    @IBOutlet weak var startDownload: UIButton!
    @IBAction func startDownloadButtonTap(_ sender: UIButton) {
        if self.drillId != nil {
            getDrillListQuestions(self.getDrillListQuestions())
        }
    }
    
    var drillId : Int? = nil
    
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
        SharedNetworkConnection.apiGetDrillQuestions(apiToken: appDelegate.apiToken, drillID: drillId, completionHandler: { data, response, error in
            guard let data = data, error == nil else {                                                 // check for fundamental networking error
                print("error=\(error)")
                return
            }
            
            var drillQuestionsParser = DrillQuestionParser(jsonString: String(data: data, encoding: .utf8)!)
            var drillQuestionsArray = (drillQuestionsParser?.getDrillQuestionArray())!
            for drillQuestion in drillQuestionsArray {
                DispatchQueue.main.async {
                    var cacheDirectory = try! FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                    let filename = drillQuestion.occludedVideo
                    cacheDirectory.appendPathComponent(filename)
                    print(filename)
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
                    })
                }
            }
            
        })
    }


}
