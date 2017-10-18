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
    
    //@IBOutlet weak var questionsLabel: UILabel!
    //@IBOutlet weak var pointsLabel: UILabel!
    
    //@IBOutlet weak var scoreView: UIView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var lineTimerView: UIView!
    @IBOutlet weak var countLabel: UILabel!
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
//        self.isLandscape = self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClass.compact
//        let verticalClass = self.traitCollection.verticalSizeClass
//        self.isLandscape = verticalClass == UIUserInterfaceSizeClass.compact

        if self.drillVideoItem != nil {
            updateViewComponents(battingHand: (self.drillVideoItem?.batterHand)!)
        } else {
            updateViewComponents(battingHand: "R")
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
        
//        self.navigationController?.navigationBar.topItem?.title = "Drill List";

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.pitchesTable.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
        self.pitchesTable.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    public func resetViewForDisplay()
    {
        let parentViewController = self.parent as! VideoPlayerViewController
        if !parentViewController.replay {
            if parentViewController.hasDrillStarted {
                self.view.alpha = 1
            } else {
                let onDrillStartedHandler = {self.view.alpha = (self.isLandscape) ? 0.7 : 1}
                parentViewController.onDrillStarted = onDrillStartedHandler
            }
        } else {
            self.view.alpha = 0
        }
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
        drillQuestionItem = parentViewController.drillQuestionsArray[parentViewController.index]
        getPitchLocations()
        loadVideoData()
        self.countLabel.layer.borderWidth = 3.0
        self.countLabel.layer.borderColor = UIColor.red.cgColor
        self.countLabel.isHidden = false
    }
    
    public func triggerCountdown()
    {
        self.setTimer(value: 2.5)
        self.startClockTimer()
    }
    
    private func updateViewComponents(battingHand: String)
    {
        let deviceBounds = UIScreen.main.bounds
        if self.parent == nil || !(self.parent is VideoPlayerViewController) {
            return
        }
        let parentViewController = self.parent as! VideoPlayerViewController
        
//        if isLandscape
//        {
            self.lineTimerView.isHidden = true
            //self.scoreView.isHidden = true
            self.view.backgroundColor = UIColor.clear
            if parentViewController.hasDrillStarted && !parentViewController.replay {
                self.view.alpha = 0.7
            }
            self.timerView.isHidden = true
            let toMoveX = deviceBounds.width - 195
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
//            let yPos = self.lineTimerView.frame.origin.y+self.countLabel.frame.size.height+10
//            self.pitchesTable.frame.origin.y = 1
            self.pitchesTable.frame = CGRect.init(x:self.pitchesTable.frame.origin.x, y:self.pitchesTable.frame.origin.y, width:self.pitchesTable.frame.size.width, height:viewFrame.size.height)
            self.lineTimerView.frame = CGRect.init(x:self.lineTimerView.frame.origin.x, y:self.lineTimerView.frame.origin.y, width:self.countLabel.frame.size.width, height:self.lineTimerView.frame.size.height)
//        } else {
//            self.timerView.isHidden = false
//            //self.scoreView.isHidden = false
//            if parentViewController.hasDrillStarted && !parentViewController.replay {
//                self.view.alpha = 1
//            }
//            self.view.superview?.frame = CGRect.init(x:0, y:parentViewController.movieView.frame.size.height + 63, width:deviceBounds.width, height:381)
//            self.view.backgroundColor = UIColor.black
//            self.view.frame = CGRect.init(x:0, y:0, width:deviceBounds.width, height:381)
//            self.pitchesTable.frame = CGRect.init(x:0, y:86, width:deviceBounds.width, height:203)
//            //self.scoreView.frame = CGRect.init(x:0, y:0, width:deviceBounds.width, height:78)
//            //self.scoreView.subviews[0].frame = CGRect.init(x:7, y:7, width:((deviceBounds.width / 2) - 17), height:67)
//            //self.scoreView.subviews[1].frame = CGRect.init(x:((deviceBounds.width / 2) + 7), y:7, width:((deviceBounds.width / 2) - 17), height:67)
//            self.timerView.frame = CGRect.init(x:0, y:302, width:deviceBounds.width, height:64)
//            self.lineTimerView.isHidden = true
//        }
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
                self.countLabel.text = (self.drillQuestionItem?.pitchCount)! as String
                
                if (self.countLabel.text == "") {
                    self.countLabel.text = "2-1"
                }
                
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
        
        if let parentViewController = self.parent as? VideoPlayerViewController {
            if (pitchType == self.drillVideoItem?.pitchTypeID && pitchLocation == self.drillVideoItem?.pitchLocationID) {
                parentViewController.locationPoints += 10
                parentViewController.typePoints += 10
                self.calculcatePoints(points: 25)
                self.sendUserAnswer(correctAnswer: true, bothIncorrect: false)
            }
            else {
                var points = 0
                let bothIncorrect = pitchType != self.drillVideoItem?.pitchTypeID && pitchLocation != self.drillVideoItem?.pitchLocationID
                if (pitchType == self.drillVideoItem?.pitchTypeID) {
                    points += 10
                    parentViewController.typePoints += 10
                }
                if (pitchLocation == self.drillVideoItem?.pitchLocationID) {
                    points += 10
                    parentViewController.locationPoints += 10
                }
                self.calculcatePoints(points: points)
                self.sendUserAnswer(correctAnswer: false, bothIncorrect: bothIncorrect)
            }
        }
    }
    
    private func calculcatePoints(points: Int)
    {
        let parentViewController = self.parent as! VideoPlayerViewController
        parentViewController.points += points
        print("Points : \(parentViewController.points)")
//        self.pointsLabel.text = String(parentViewController.points)
    }
    
    private func sendUserAnswer(correctAnswer: Bool, bothIncorrect: Bool)
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
                print("error=\(String(describing: error))")
                let parentViewController = self.parent as! VideoPlayerViewController
                parentViewController.showIndicator(shouldAppear: false)
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
                // 403 on no token
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(String(describing: response))")
                
                SharedNetworkConnection.apiLoginWithStoredCredentials(completionHandler: { data, response, error in
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    let json = try? JSONSerialization.jsonObject(with: data!, options: [])
                    if let dictionary = json as? [String: Any] {
                        if let apiToken = dictionary["token"] as? (String) {
                            appDelegate.apiToken = apiToken
                        }
                    }
                })
                
                return
            }
            let parentViewController = self.parent as? VideoPlayerViewController
            parentViewController?.showIndicator(shouldAppear: false)
        })
        
        if parentViewController != nil {
            self.pitchesTable.reloadData()
            self.showAnswer(correctAnswer: correctAnswer, bothIncorrect: bothIncorrect)
        }
    }
    
    private func showAnswer(correctAnswer: Bool, bothIncorrect: Bool)
    {
        
        let parentViewController = self.parent as? VideoPlayerViewController
        let points = (parentViewController?.points)!
        let questionCount = (parentViewController?.index)! + 1
        parentViewController?.didShowQuestionNumberAndPoints(pitch: questionCount, totalPoints: points)

        self.answeredCorrectly = correctAnswer

        if (correctAnswer) {
            
            if UserDefaults.standard.object(forKey: Constants.kSound) as? Int == 1 {
                AudioServicesPlaySystemSound(Constants.positiveSoundId)
                if #available(iOS 10.0, *) {
                    let generator = UIImpactFeedbackGenerator(style: .heavy)
                    generator.impactOccurred()
                } else {
                    AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
                }
            }
        } else {
            if bothIncorrect && UserDefaults.standard.object(forKey: Constants.kSound) as? Int == 1 {
                audioPlayerMiss?.play()
            }
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
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: self.view.frame.width/2,y: 33), radius: CGFloat(40), startAngle: CGFloat(-Double.pi / 2), endAngle:CGFloat(2*Double.pi - Double.pi / 2), clockwise: true)
        
        self.shapeLayer.path = circlePath.cgPath
        self.shapeLayer.fillColor = UIColor.clear.cgColor
        self.shapeLayer.strokeColor = UIColor.white.cgColor
        self.shapeLayer.lineWidth = 5.0
        
        timerView.layer.addSublayer(self.shapeLayer)
    }
    
    private func addLine() {
        let linePath = UIBezierPath()
        linePath.move(to: CGPoint(x:0, y:0))
        linePath.addLine(to: CGPoint(x:self.countLabel.frame.width, y:0))
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
        if answered { return }
        self.lineTimerView.isHidden = false
        self.countDownTimer.invalidate()
        self.countDownTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(DrillQuestionsViewController.countdown), userInfo: nil, repeats: true)

        self.startAnimation()
    }
    
    func stopAnimation() {
        self.lineLayer.removeAllAnimations()
        self.lineTimerView.isHidden = true
    }
    
    func countdown()
    {
        if (answered)
        {
            self.countDownTimer.invalidate()
            self.stopAnimation()
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
        
        let pitchTypeLabel = cell.viewWithTag(3) as! UILabel
        pitchTypeLabel.text = drillPitchItem.name
        
        
        if (drillPitchItem.drillPitchID == self.correctPitchTypeID) { //GreenColor
            pitchTypeLabel.backgroundColor = UIColor(red: 80/255, green: 204/255, blue: 107/255, alpha: 1.0)
        } else {
            switch drillPitchItem.drillPitchID {
            case 1: //"#f39c12" FastBall
                pitchTypeLabel.backgroundColor = UIColor(red: 243/255, green: 156/255, blue: 18/255, alpha: 1.0)
            case 2: //"#f31286" Changeup
                pitchTypeLabel.backgroundColor = UIColor(red: 243/255, green: 18/255, blue: 134/255, alpha: 1.0)
            case 3: //"#975113" Cutter
                pitchTypeLabel.backgroundColor = UIColor(red: 151/255, green: 81/255, blue: 19/255, alpha: 1.0)
            case 4://"#3498db" Curveball
                pitchTypeLabel.backgroundColor = UIColor(red: 52/255, green: 152/255, blue: 219/255, alpha: 1.0)
            case 5: //"#6334db" Slider
                pitchTypeLabel.backgroundColor = UIColor(red: 99/255, green: 52/255, blue: 219/255, alpha: 1.0)
                
            default: //"#f39c12"
                pitchTypeLabel.backgroundColor = UIColor(red: 243/255, green: 156/255, blue: 18/255, alpha: 1.0)
            }
        }
        
        
        let ballImage = cell.viewWithTag(1) as! UIButton
        let strikeImage = cell.viewWithTag(2) as! UIButton
        
        ballImage.alpha = 1
        strikeImage.alpha = 1
        
        cell.contentView.bringSubview(toFront: ballImage)
        cell.contentView.bringSubview(toFront: strikeImage)
        
        var selectedButtonBColor: String? = "plainB.png"
        var selectedButtonSColor: String?  = "plainS.png"
        
        if (drillPitchItem.drillPitchID == self.answeredPitchTypeID) {
            if (self.answeredPitchLocationID == 1) {
                selectedButtonBColor = "redB.png"
            } else {
                selectedButtonSColor = "redS.png"
            }
        }
        
        if (drillPitchItem.drillPitchID == self.correctPitchTypeID) {
            if (self.correctPitchLocationID == 1) {
                selectedButtonBColor = "greenB.png"
            } else {
                selectedButtonSColor = "greenS.png"
            }
        }
        
        
        let image1 = UIImage(named: selectedButtonBColor!) as UIImage?
        ballImage.setImage(image1, for: UIControlState.normal)
        
        let image2 = UIImage(named: selectedButtonSColor!) as UIImage?
        strikeImage.setImage(image2, for: UIControlState.normal)
        
        let hiddenLabel = cell.viewWithTag(4) as! UILabel
        hiddenLabel.text = String(drillPitchItem.drillPitchID)
        
        cell.backgroundColor = UIColor.clear
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
    
    @IBAction func buttonPressed(sender: UIButton) {
        sender.isEnabled = false
        if (!timeout)
        {
            self.answered = true
            let pausedTime = self.shapeLayer.convertTime(CACurrentMediaTime(), from: nil)
            self.shapeLayer.speed = 0
            self.shapeLayer.timeOffset = pausedTime
            let hiddenLabel = sender.superview?.superview?.viewWithTag(4) as! UILabel
            self.getVideoAnswer(pitchType: Int(hiddenLabel.text!)!, pitchLocation: sender.tag)
            sender.isEnabled = true
        }
    }
}
