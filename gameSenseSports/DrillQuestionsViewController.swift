//
//  DrillQuestionsViewController.swift
//  gameSenseSports
//
//  Created by Ra on 11/26/16.
//  Copyright © 2016 gameSenseSports. All rights reserved.
//

import UIKit
import AVFoundation

class DrillQuestionsViewController: UIViewController, AVAudioPlayerDelegate
{
    
    @IBOutlet weak var questionsLabel: UILabel!
    @IBOutlet weak var pointsLabel: UILabel!
    
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var answerView1: UIView!
    @IBOutlet weak var answerView2: UIView!
    @IBOutlet weak var answerView3: UIView!
    @IBOutlet weak var answerView4: UIView!
    @IBOutlet weak var timerView: UIView!

    
    private var audioPlayerHit: AVAudioPlayer?
    private var audioPlayerMiss: AVAudioPlayer?
    
    private var drillQuestionItem = DrillQuestionItem(json: [:])
    private var pitchArray = [DrillPitchLocationItem]()
    
    public var answered = false
    public var answeredCorrectly = false
    public var timeout = false
    
    public var correctPitchLocationID = -1
    public var correctPitchTypeID = -1
    
    public var answeredPitchLocationID = -1
    public var answeredPitchTypeID = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        answerView1.alpha = 0
        answerView2.alpha = 0
        answerView3.alpha = 0
        answerView4.alpha = 0
        loadVideos()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let navController = self.presentingViewController as! UINavigationController
        let parentViewController = navController.viewControllers[1] as! VideoPlayerViewController
        pointsLabel.text = String(parentViewController.points)
        questionsLabel.text = String(parentViewController.index + 1)
        drillQuestionItem = parentViewController.drillQuestionsArray[parentViewController.index]
        getPitchLocations()
        self.setTimer(value: 2.5)
        self.startClockTimer()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func getPitchLocations()
    {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        //let navController = self.presentingViewController as! UINavigationController
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
                self.updateUIView()
            }
        })

    }
    
    private func updateUIView()
    {
        var viewGroup = 1
        for drillPitchItem in self.pitchArray {
            if (viewGroup < 6)
            {
                let uiView = self.view.viewWithTag(viewGroup)!
                uiView.alpha = 1
                let viewTitle = uiView.viewWithTag(viewGroup * 10) as! UILabel
                viewTitle.text = drillPitchItem.name
                let hiddenLabel = uiView.viewWithTag(viewGroup * 10 + 9) as! UILabel
                hiddenLabel.text = String(drillPitchItem.drillPitchID)
                viewGroup += 1
            }
        }
    }
    
    private func getVideoAnswer(pitchType: Int, pitchLocation: Int)
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
                            self.getVideoAnswer(pitchType: pitchType, pitchLocation: pitchLocation)
                        }
                    }                    
                })
                
                return
            }
            
            let drillVideoParser = DrillVideoParser(jsonString: String(data: data, encoding: .utf8)!)
            let drillVideoItem = drillVideoParser?.getDrillVideoItem()
            
            DispatchQueue.main.async {
                self.correctPitchLocationID = (drillVideoItem?.pitchLocationID)!
                self.correctPitchTypeID = (drillVideoItem?.pitchTypeID)!
                
                self.answeredPitchTypeID = pitchType
                self.answeredPitchLocationID = pitchLocation
                
                let navController = self.presentingViewController as! UINavigationController
                let parentViewController = navController.viewControllers[1] as! VideoPlayerViewController

                if (pitchType == drillVideoItem?.pitchTypeID && pitchLocation == drillVideoItem?.pitchLocationID) {
                    self.sendUserAnswer(correctAnswer: true)
                    parentViewController.locationPoints += 10
                    parentViewController.typePoints += 10
                    self.calculcatePoints(points: 25)
                }
                else {
                    var points = 0
                    if (pitchType == drillVideoItem?.pitchTypeID) {
                        points += 10
                        parentViewController.typePoints += 10
                    }
                    if (pitchLocation == drillVideoItem?.pitchLocationID) {
                        points += 10
                        parentViewController.locationPoints += 10
                    }
                    self.calculcatePoints(points: points)
                    self.sendUserAnswer(correctAnswer: false)
                }
            }
        })
    }
    
    private func calculcatePoints(points: Int)
    {
        let navController = self.presentingViewController as! UINavigationController
        let parentViewController = navController.viewControllers[1] as! VideoPlayerViewController
        parentViewController.points += points
        self.pointsLabel.text = String(parentViewController.points)
    }
    
    private func sendUserAnswer(correctAnswer: Bool)
    {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let navController = self.presentingViewController as! UINavigationController
        let parentViewController = navController.viewControllers[1] as! VideoPlayerViewController
        let drillQuestionItem = parentViewController.drillQuestionsArray[parentViewController.index]
        
        var pitchLocation = "Strike"
        if (self.answeredPitchLocationID == 1) {
            pitchLocation = "Ball"
        }
        
        SharedNetworkConnection.apiPostAnswerQuestion(apiToken: appDelegate.apiToken, correctAnswer: correctAnswer, activityID: parentViewController.returnedDrillID, questionID: drillQuestionItem.drillQuestionID, answerID: self.answeredPitchTypeID, pitchLocation: pitchLocation, questionJson: drillQuestionItem.fullJson, completionHandler: { data, response, error in
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
                            self.sendUserAnswer(correctAnswer: correctAnswer)
                        }
                    }
                })
                
                return
            }
            
            self.showAnswer(correctAnswer: correctAnswer)
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
        
        if (correctAnswer) {
            let alert = UIAlertController(title: "Correct!", message: message, preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Replay", style: UIAlertActionStyle.default, handler: replayHandler))
            alert.addAction(UIAlertAction(title: "Next", style: UIAlertActionStyle.default, handler: nextHandler))
            self.present(alert, animated: true, completion: nil)
            audioPlayerHit?.play()
        }
        else {
            let alert = UIAlertController(title: "Miss", message: message, preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Replay", style: UIAlertActionStyle.default, handler: replayHandler))
            alert.addAction(UIAlertAction(title: "Next", style: UIAlertActionStyle.default, handler: nextHandler))
            self.present(alert, animated: true, completion: nil)
            audioPlayerMiss?.play()
        }
    }
    
    func replayHandler(alert: UIAlertAction!) {
        let navController = self.presentingViewController as! UINavigationController
        let parentViewController = navController.viewControllers[1] as! VideoPlayerViewController
        parentViewController.replay = true
        self.dismiss(animated: true, completion: nil)
    }
    
    func nextHandler(alert: UIAlertAction!)
    {
        let navController = self.presentingViewController as! UINavigationController
        let parentViewController = navController.viewControllers[1] as! VideoPlayerViewController
        parentViewController.replay = false
        parentViewController.index += 1
        self.dismiss(animated: true, completion: nil)
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
    }
    
    private func addCircle() {
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: 171,y: 75), radius: CGFloat(75), startAngle: CGFloat(-M_PI_2), endAngle:CGFloat(2*M_PI-M_PI_2), clockwise: true)
        
        self.shapeLayer.path = circlePath.cgPath
        self.shapeLayer.fillColor = UIColor.clear.cgColor
        self.shapeLayer.strokeColor = UIColor.white.cgColor
        self.shapeLayer.lineWidth = 5.0
        
        timerView.layer.addSublayer(self.shapeLayer)
    }
    
    private func updateLabel(value: Double) {
        //self.setLabelText(self.timeFormatted(value))
        self.addCircle()
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
        self.timerValue -= 0.1
        if self.timerValue < 0 {
            if (!answered)
            {
                self.timeout = true
                self.getVideoAnswer(pitchType: -1, pitchLocation: -1)
            }
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
    
    @IBAction func buttonPressed(sender: UIButton) {
        if (!timeout)
        {
            answered = true
            let hiddenLabel = sender.superview?.viewWithTag(sender.tag / 10 * 10 + 9) as! UILabel
            self.getVideoAnswer(pitchType: Int(hiddenLabel.text!)!, pitchLocation: sender.tag%10)
        }
    }
}
