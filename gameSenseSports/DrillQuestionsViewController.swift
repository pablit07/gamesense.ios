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
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var lineTimerView: UIView!
    @IBOutlet weak var timerView: UIView!

    @IBOutlet weak var pitchesTable: UITableView!
    
    private var audioPlayerHit: AVAudioPlayer?
    private var audioPlayerMiss: AVAudioPlayer?
    
    private var drillQuestionItem = DrillQuestionItem(json: [:])
    private var pitchArray = [DrillPitchLocationItem]()
    private var drillVideoItem = DrillVideoItem(json: [:])
    
    public var answered = false
    public var answeredCorrectly = false
    public var timeout = false
    public var alternateColor = false
    
    public var correctPitchLocationID = -1
    public var correctPitchTypeID = -1
    
    public var answeredPitchLocationID = -1
    public var answeredPitchTypeID = -1
    
    public var isLandscape = false
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        let verticalClass = self.traitCollection.verticalSizeClass
        self.isLandscape = verticalClass == UIUserInterfaceSizeClass.compact
        if self.drillVideoItem != nil {
            updateViewComponents(battingHand: (self.drillVideoItem?.batterHand)!)
        } else {
            updateViewComponents(battingHand: "R")
        }

    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.view.alpha = 0
        loadVideos()
        self.isLandscape = self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClass.compact
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
        timeout = false
        alternateColor = false
        correctPitchLocationID = -1
        correctPitchTypeID = -1
        answeredPitchLocationID = -1
        answeredPitchTypeID = -1
        self.shapeLayer.removeFromSuperlayer()
        self.shapeLayer = CAShapeLayer()
        let parentViewController = self.parent as! VideoPlayerViewController
        pointsLabel.text = String(parentViewController.points)
        questionsLabel.text = String(parentViewController.index + 1)
        drillQuestionItem = parentViewController.drillQuestionsArray[parentViewController.index]
        getPitchLocations()
        loadVideoData()
    }
    
    public func triggerCountdown()
    {
        self.setTimer(value: 2.5)
        self.startClockTimer()
    }
    
    private func updateViewComponents(battingHand: String)
    {
        let deviceBounds = UIScreen.main.bounds
        let parentViewController = self.parent as! VideoPlayerViewController
        
        if battingHand == "R" {
            parentViewController.drillQuestionsTrailingLeft.isActive = false
            parentViewController.drillQuestionsTrailingRight.isActive = true
        
            parentViewController.drillQuestionsLeadingLeft.isActive = false
            parentViewController.drillQuestionsLeadingRight.isActive = true
        } else {
            parentViewController.drillQuestionsTrailingRight.isActive = false
            parentViewController.drillQuestionsTrailingLeft.isActive = true
            
            parentViewController.drillQuestionsLeadingRight.isActive = false
            parentViewController.drillQuestionsLeadingLeft.isActive = true
        }
        
        if isLandscape
        {
//            self.lineTimerView.isHidden = false
//            self.scoreView.isHidden = true
            self.view.backgroundColor = UIColor.clear
            self.view.alpha = 0.7
            self.timerView.isHidden = true
            let toMoveX = deviceBounds.width * 0.68
            var viewFrame = self.view.frame
            assert(battingHand == "R" || battingHand == "L")
            if battingHand == "R" {
                viewFrame.origin = CGPoint.init(x:toMoveX, y:0)
            } else if battingHand == "L" {
                viewFrame.origin = CGPoint.init(x:0, y:0)
            }
//            viewFrame.size.width = deviceBounds.width - toMoveX
//            viewFrame.size.height = deviceBounds.height
            self.view.frame = viewFrame
//            self.pitchesTable.frame.origin.y = 1
        } else {
//            self.timerView.isHidden = false
            self.scoreView.isHidden = false
            self.view.alpha = 1
//            self.view.superview?.frame = CGRect.init(x:0, y:parentViewController.movieView.frame.size.height + 63, width:deviceBounds.width, height:381)
            self.view.backgroundColor = UIColor.black
//            self.view.frame = CGRect.init(x:0, y:0, width:deviceBounds.width, height:381)
//            self.pitchesTable.frame = CGRect.init(x:0, y:86, width:deviceBounds.width, height:203)
//            self.scoreView.frame = CGRect.init(x:0, y:0, width:deviceBounds.width, height:78)
//            self.scoreView.subviews[0].frame = CGRect.init(x:7, y:7, width:((deviceBounds.width / 2) - 17), height:67)
//            self.scoreView.subviews[1].frame = CGRect.init(x:((deviceBounds.width / 2) + 7), y:7, width:((deviceBounds.width / 2) - 17), height:67)
//            self.timerView.frame = CGRect.init(x:0, y:302, width:deviceBounds.width, height:64)
//            self.lineTimerView.isHidden = true
        }
    }
    
    private func getPitchLocations()
    {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let drillVideo = drillQuestionItem!.responseURI0
        
        SharedNetworkConnection.apiGetDrillPitchLocation(apiToken: appDelegate.apiToken, responseURI: drillVideo, completionHandler: { data, response, error in
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
        SharedNetworkConnection.apiGetDrillVideo(apiToken: appDelegate.apiToken, responseURI: (drillQuestionItem?.answerURL)!, completionHandler: { data, response, error in
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
                            appDelegate.apiToken = apiToken
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
        
        SharedNetworkConnection.apiPostAnswerQuestion(apiToken: appDelegate.apiToken, correctAnswer: correctAnswer, activityID: parentViewController.returnedDrillID, questionID: drillQuestionItem.drillQuestionID, answerID: self.answeredPitchTypeID, pitchLocation: pitchLocation, questionJson: drillQuestionItem.fullJson, completionHandler: { data, response, error in
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
                            appDelegate.apiToken = apiToken
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
    
    
    private var shapeLayer = CAShapeLayer()
    private var lineLayer = CAShapeLayer()
    private var countDownTimer = Timer()
    private var timerValue = 900.0
    
    private func startAnimation() {
        
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = 0
        animation.toValue = 1
        animation.duration = Double(self.timerValue)
        animation.fillMode = kCAFillModeForwards
        animation.isRemovedOnCompletion = false
        self.shapeLayer.add(animation, forKey: "ani")
        self.lineLayer.add(animation, forKey: "ani")
    }
    
    private func addCircle() {
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: self.view.frame.width/2,y: 33), radius: CGFloat(40), startAngle: CGFloat(-M_PI_2), endAngle:CGFloat(2*M_PI-M_PI_2), clockwise: true)
        
        self.shapeLayer.path = circlePath.cgPath
        self.shapeLayer.fillColor = UIColor.clear.cgColor
        self.shapeLayer.strokeColor = UIColor.white.cgColor
        self.shapeLayer.lineWidth = 5.0
        
        timerView.layer.addSublayer(self.shapeLayer)
    }
    
    private func addLine() {
        let linePath = UIBezierPath()
        linePath.move(to: CGPoint(x:0, y:0))
        linePath.addLine(to: CGPoint(x:self.view.frame.width, y:0))
        self.lineLayer.path = linePath.cgPath
        self.lineLayer.fillColor = UIColor.clear.cgColor
        self.lineLayer.strokeColor = UIColor.white.cgColor
        self.lineLayer.lineWidth = 5.0
        
        lineTimerView.layer.addSublayer(self.lineLayer)
    }
    
    private func updateLabel(value: Double) {
        self.setLabelText(value: self.timeFormatted(timer: value))
        self.addCircle()
        self.addLine()
    }
    
    func setTimer(value: Double) {
        self.timerValue = value
        self.updateLabel(value: value)
    }
    
    func startClockTimer() {
        self.countDownTimer.invalidate()
        self.countDownTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(DrillQuestionsViewController.countdown), userInfo: nil, repeats: true)

        self.startAnimation()
        
    }
    
    func countdown()
    {
        if (answered)
        {
            self.countDownTimer.invalidate()
            return
        }
        self.timerValue -= 0.1
        if self.timerValue < 0 {
            self.timeout = true
            self.getVideoAnswer(pitchType: -1, pitchLocation: -1)
            self.setLabelText(value: "0.00s")
            self.countDownTimer.invalidate()
        }
        else {
            self.setLabelText(value: self.timeFormatted(timer: self.timerValue))
        }
    }
    
    private func timeFormatted(timer: Double) -> String {
        return String(format: "%.2fs", timer)
    }
    
    private func setLabelText(value: String) {
        timeLabel.text = value
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
        if (!timeout)
        {
            self.answered = true
            let pausedTime = self.shapeLayer.convertTime(CACurrentMediaTime(), from: nil)
            self.shapeLayer.speed = 0
            self.shapeLayer.timeOffset = pausedTime
            let hiddenLabel = sender.superview?.viewWithTag(4) as! UILabel
            self.getVideoAnswer(pitchType: Int(hiddenLabel.text!)!, pitchLocation: sender.tag)
        }
    }
}
