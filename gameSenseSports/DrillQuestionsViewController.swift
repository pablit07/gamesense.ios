//
//  DrillQuestionsViewController.swift
//  gameSenseSports
//
//  Created by Ra on 11/26/16.
//  Copyright © 2016 gameSenseSports. All rights reserved.
//

import UIKit
import AVFoundation

class DrillQuestionsViewController: UIViewController, AVAudioPlayerDelegate, UITableViewDataSource, UITableViewDelegate
{
    
    @IBOutlet weak var questionsLabel: UILabel!
    @IBOutlet weak var pointsLabel: UILabel!
    
    @IBOutlet weak var scoreView: UIView!

    @IBOutlet weak var pitchesTable: UITableView!
    
    private var audioPlayerHit: AVAudioPlayer?
    private var audioPlayerMiss: AVAudioPlayer?
    
    private var drillQuestionItem = DrillQuestionItem(json: [:])
    private var pitchArray = [DrillPitchLocationItem]()
    private var drillVideoItem = DrillVideoItem(json: [:])
    
    public var answered = false
    public var answeredCorrectly = false
    public var alternateColor = false
    
    public var correctPitchLocationID = -1
    public var correctPitchTypeID = -1
    
    public var answeredPitchLocationID = -1
    public var answeredPitchTypeID = -1
    
    public var isLandscape = false
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        /*
        let verticalClass = self.traitCollection.verticalSizeClass
        self.isLandscape = verticalClass == UIUserInterfaceSizeClass.compact
        if self.drillVideoItem != nil {
            updateViewComponents(battingHand: (self.drillVideoItem?.batterHand)!)
        } else {
            updateViewComponents(battingHand: "R")
        }
        */
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.view.alpha = 0
        loadVideos()
        //self.isLandscape = self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClass.compact
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    public func resetViewForDisplay()
    {
        self.view.alpha = 1
        answered = false
        answeredCorrectly = false
        alternateColor = false
        correctPitchLocationID = -1
        correctPitchTypeID = -1
        answeredPitchLocationID = -1
        answeredPitchTypeID = -1
        let parentViewController = self.parent as! VideoPlayerViewController
        pointsLabel.text = String(parentViewController.points)
        questionsLabel.text = String(parentViewController.index + 1)
        drillQuestionItem = parentViewController.drillQuestionsArray[parentViewController.index]
        getPitchLocations()
        loadVideoData()
    }
    
    private func updateViewComponents(battingHand: String)
    {
        /*
        let deviceBounds = UIScreen.main.bounds
        if isLandscape
        {
            self.scoreView.isHidden = true
            self.view.backgroundColor = UIColor.clear
            let toMoveX = deviceBounds.width * 0.65
            var viewFrame = self.view.frame
            assert(battingHand == "R" || battingHand == "L")
            if battingHand == "R" {
                viewFrame.origin = CGPoint.init(x:toMoveX, y:0)
            } else if battingHand == "L" {
                viewFrame.origin = CGPoint.init(x:0, y:0)
            }
            viewFrame.size.width = deviceBounds.width - toMoveX
            viewFrame.size.height = deviceBounds.height
            self.view.frame = viewFrame
            self.pitchesTable.frame.origin.y = 0
            self.isLandscape = true
        } else {
            self.scoreView.isHidden = false
            self.view.superview?.frame = CGRect.init(x:0, y:286, width:deviceBounds.width, height:381)
            self.view.backgroundColor = UIColor.black
            self.view.frame = CGRect.init(x:0, y:0, width:deviceBounds.width, height:381)
            self.pitchesTable.frame = CGRect.init(x:0, y:86, width:deviceBounds.width, height:203)
            self.scoreView.frame = CGRect.init(x:0, y:0, width:deviceBounds.width, height:78)
            self.scoreView.subviews[0].frame = CGRect.init(x:7, y:7, width:((deviceBounds.width / 2) - 17), height:67)
            self.scoreView.subviews[1].frame = CGRect.init(x:((deviceBounds.width / 2) + 7), y:7, width:((deviceBounds.width / 2) - 17), height:67)
            self.isLandscape = false
        }
 */
    }
    
    private func getPitchLocations()
    {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let drillVideo = drillQuestionItem!.responseURI0
        
        SharedNetworkConnection.apiGetDrillPitchLocation(apiToken: "", responseURI: drillVideo, completionHandler: { data, response, error in
            guard let data = data, error == nil else {                                                 // check for fundamental networking error
                print("error=\(error)")
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(response)")
                return
            }
            
            let drillPitchLocationParser = DrillPitchLocationParser(jsonString: String(data: data, encoding: .utf8)!)
            self.pitchArray = (drillPitchLocationParser?.getDrillVideoPitchLocationArray())!
            DispatchQueue.main.async {
                self.pitchesTable.reloadData()
            }
        })
    }
    
    private func loadVideoData()
    {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        SharedNetworkConnection.apiGetDrillVideo(apiToken: "", responseURI: (drillQuestionItem?.answerURL)!, completionHandler: { data, response, error in
            guard let data = data, error == nil else {                                                 // check for fundamental networking error
                print("error=\(error)")
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
                // 403 on no token
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(response)")
                
                
                SharedNetworkConnection.apiLoginWithStoredCredentials(completionHandler: { data, response, error in
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    let json = try? JSONSerialization.jsonObject(with: data!, options: [])
                    if let dictionary = json as? [String: Any] {
                        if let apiToken = dictionary["token"] as? (String) {
                            self.loadVideoData()
                        }
                    }
                })
                
                return
            }
            
            let drillVideoParser = DrillVideoParser(jsonString: String(data: data, encoding: .utf8)!)
            self.drillVideoItem = drillVideoParser?.getDrillVideoItem()
            
            DispatchQueue.main.async {
                self.updateViewComponents(battingHand: (self.drillVideoItem?.batterHand)!)
            }
        })
    }
    
    private func getVideoAnswer(pitchType: Int, pitchLocation: Int)
    {
        self.correctPitchLocationID = (self.drillVideoItem?.pitchLocationID)!
        self.correctPitchTypeID = (self.drillVideoItem?.pitchTypeID)!
        
        self.answeredPitchTypeID = pitchType
        self.answeredPitchLocationID = pitchLocation
        
        let parentViewController = self.parent as! VideoPlayerViewController
        if (pitchType == self.drillVideoItem?.pitchTypeID && pitchLocation == self.drillVideoItem?.pitchLocationID) {
            self.sendUserAnswer(correctAnswer: true)
            parentViewController.locationPoints += 10
            parentViewController.typePoints += 10
            self.calculcatePoints(points: 25)
        }
        else {
            var points = 0
            if (pitchType == self.drillVideoItem?.pitchTypeID) {
                points += 10
                parentViewController.typePoints += 10
            }
            if (pitchLocation == self.drillVideoItem?.pitchLocationID) {
                points += 10
                parentViewController.locationPoints += 10
            }
            self.calculcatePoints(points: points)
            self.sendUserAnswer(correctAnswer: false)
        }
    }
    
    private func calculcatePoints(points: Int)
    {
        let parentViewController = self.parent as! VideoPlayerViewController
        parentViewController.points += points
        self.pointsLabel.text = String(parentViewController.points)
    }
    
    private func sendUserAnswer(correctAnswer: Bool)
    {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let parentViewController = self.parent as! VideoPlayerViewController
        let drillQuestionItem = parentViewController.drillQuestionsArray[parentViewController.index]
        
        var pitchLocation = "Strike"
        if (self.answeredPitchLocationID == 1) {
            pitchLocation = "Ball"
        }
        
        SharedNetworkConnection.apiPostAnswerQuestion(apiToken: "", correctAnswer: correctAnswer, activityID: parentViewController.returnedDrillID, questionID: drillQuestionItem.drillQuestionID, answerID: self.answeredPitchTypeID, pitchLocation: pitchLocation, questionJson: drillQuestionItem.fullJson, completionHandler: { data, response, error in
            guard let data = data, error == nil else {                                                 // check for fundamental networking error
                print("error=\(error)")
                let parentViewController = self.parent as! VideoPlayerViewController
                parentViewController.showIndicator(shouldAppear: false)
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
                // 403 on no token
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(response)")
                
                SharedNetworkConnection.apiLoginWithStoredCredentials(completionHandler: { data, response, error in
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    let json = try? JSONSerialization.jsonObject(with: data!, options: [])
                    if let dictionary = json as? [String: Any] {
                        if let apiToken = dictionary["token"] as? (String) {
                            self.sendUserAnswer(correctAnswer: correctAnswer)
                        }
                    }
                })
                
                return
            }
            let parentViewController = self.parent as? VideoPlayerViewController
            parentViewController?.showIndicator(shouldAppear: false)
            if parentViewController != nil {
                self.showAnswer(correctAnswer: correctAnswer)
            }
        })
    }
    
    private func showAnswer(correctAnswer: Bool)
    {
        self.answeredCorrectly = correctAnswer
        var message = "The correct answer is: \n"
        for drillPitchItem in self.pitchArray {
            if (drillPitchItem.drillPitchID == self.correctPitchTypeID) {
                if (self.correctPitchLocationID == 2) {
                    message = message + drillPitchItem.name + "\nStrike"
                }
                else {
                    message = message + drillPitchItem.name + "\nBall"
                }
            }
        }
        
        let parentViewController = self.parent as? VideoPlayerViewController
        let points = (parentViewController?.points)!
        let questionCount = (parentViewController?.index)! + 1
        
        message = message + "\n\nPoints: \(points)\nQuestion: \(questionCount)\n "
        
        if (correctAnswer) {
            let alert = UIAlertController(title: "Correct!", message: message, preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Replay", style: UIAlertActionStyle.default, handler: replayHandler))
            alert.addAction(UIAlertAction(title: "Next", style: UIAlertActionStyle.default, handler: nextHandler))
            self.present(alert, animated: true, completion: nil)
            //audioPlayerHit?.play()
        }
        else {
            let alert = UIAlertController(title: "Miss", message: message, preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Replay", style: UIAlertActionStyle.default, handler: replayHandler))
            alert.addAction(UIAlertAction(title: "Next", style: UIAlertActionStyle.default, handler: nextHandler))
            self.present(alert, animated: true, completion: nil)
            //audioPlayerMiss?.play()
        }
    }
    
    func replayHandler(alert: UIAlertAction!) {
        let parentViewController = self.parent as! VideoPlayerViewController
        parentViewController.replay = true
        self.view.alpha = 0
        parentViewController.resetView()
    }
    
    func nextHandler(alert: UIAlertAction!)
    {
        let parentViewController = self.parent as! VideoPlayerViewController
        parentViewController.replay = false
        parentViewController.index += 1
        self.view.alpha = 0
        parentViewController.resetView()
    }
    
    private func loadVideos()
    {
        let urlHit = URL.init(fileURLWithPath: Bundle.main.path(
            forResource: "ballcheer",
            ofType: "mp3")!)
        
        do {
            try audioPlayerHit = AVAudioPlayer(contentsOf: urlHit)
            audioPlayerHit?.delegate = self
            audioPlayerHit?.prepareToPlay()
        } catch let error as NSError {
            print("audioPlayer error \(error.localizedDescription)")
        }
        
        let urlMiss = URL.init(fileURLWithPath: Bundle.main.path(
            forResource: "caughtball",
            ofType: "mp3")!)
        
        do {
            try audioPlayerMiss = AVAudioPlayer(contentsOf: urlMiss)
            audioPlayerMiss?.delegate = self
            audioPlayerMiss?.prepareToPlay()
        } catch let error as NSError {
            print("audioPlayer error \(error.localizedDescription)")
        }
    }
    
    func numberOfSectionsInTableView(in tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.pitchArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "answerCell", for: indexPath)
        let drillPitchItem = self.pitchArray[indexPath.row]
        let pitchLabel = cell.viewWithTag(3) as! UILabel
            pitchLabel.text = drillPitchItem.name
        let hiddenLabel = cell.viewWithTag(4) as! UILabel
        hiddenLabel.text = String(drillPitchItem.drillPitchID)

        if (alternateColor) {
            alternateColor = false
            cell.backgroundColor = UIColor.lightGray
        }
        else {
            alternateColor = true
            cell.backgroundColor = UIColor.darkGray
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
    @IBAction func buttonPressed(sender: UIButton) {
        self.answered = true
        let hiddenLabel = sender.superview?.viewWithTag(4) as! UILabel
        self.getVideoAnswer(pitchType: Int(hiddenLabel.text!)!, pitchLocation: sender.tag)
    }
}
