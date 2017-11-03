//
//  VideoPlayerViewController.swift
//  gameSenseSports
//
//  Created by Ra on 11/15/16.
//  Copyright © 2016 gameSenseSports. All rights reserved.
//

import AVFoundation
import AVKit

import MobileCoreServices

import UIKit

class VideoPlayerViewController: UIViewController
{
 
    deinit {
        self.removeVideoPlayer()
        NotificationCenter.default.removeObserver(self)
        URLSession.shared.invalidateAndCancel()
    }
    
    @IBOutlet weak var movieView: UIView!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var scoreView: UIView!
    @IBOutlet weak var replayNextBgView: UIView!
    @IBOutlet weak var questionsTextField: UILabel!
    @IBOutlet weak var pointsTextField: UILabel!

    private var drillQuestionsParser = DrillQuestionParser(jsonString: "")
    private var drillListItem = DrillListItem(json: [:])
    private var presenting = false
    
    private var drillStartTime = ""
    
    public var drillQuestionsArray = [DrillQuestionItem]()
    private var drillVideoItem = DrillVideoItem(json: [:])

    public var replay = false
    public var index = 0

    public var points = 0
    public var locationPoints = 0
    public var typePoints = 0
    
    public var returnedDrillID = -1
    
    public var hasDrillStarted = false
    public var onDrillStarted: (() -> ())? = nil
    
    private var currentpreferredPeakBitRate = 1000000.0
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        let screenSize : CGRect = self.movieView.bounds
        let fullScreenSize = UIScreen.main.bounds
        let verticalClass = self.traitCollection.verticalSizeClass
        if verticalClass == UIUserInterfaceSizeClass.compact {
            self.movieView.frame = CGRect.init(x:0, y:63, width:fullScreenSize.width, height:fullScreenSize.height)
            self.movieView.bounds = CGRect.init(x:0, y:0, width:fullScreenSize.width, height:fullScreenSize.height)
            if self.movieView.layer.sublayers != nil {
                self.movieView.layer.sublayers?[0].frame = CGRect.init(x:0, y:0, width:fullScreenSize.width, height:fullScreenSize.height)
                self.movieView.layer.sublayers?[0].bounds = CGRect.init(x:0, y:0, width:fullScreenSize.width, height:fullScreenSize.height)
            }
            if self.loadingView.subviews.count > 0 {
                self.loadingView.subviews[0].frame.origin.y = 100
            }
        } else {
            if self.movieView.layer.sublayers != nil {
                self.movieView.frame = CGRect.init(x:0, y:63, width:fullScreenSize.width, height:215)
                self.movieView.layer.sublayers?[0].frame = CGRect.init(x:0, y:0, width:screenSize.width, height:(screenSize.width * 0.5625))
            }
            if self.loadingView.subviews.count > 0 {
                self.loadingView.subviews[0].frame.origin.y = 284
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        // force to landscape for this view only
        let currentOrientationValue = UIDevice.current.orientation
        if currentOrientationValue != UIDeviceOrientation.landscapeLeft && currentOrientationValue != UIDeviceOrientation.landscapeRight {
            UIDevice.current.setValue(UIInterfaceOrientation.landscapeLeft.rawValue, forKey: "orientation")
        }
        self.movieView.backgroundColor = UIColor.black
        
        var parentViewController : DrillListViewController? = nil
        for var vc in (self.navigationController?.viewControllers.reversed())! {
            if let vc = (vc as? DrillListViewController) {
                parentViewController = vc
                break
            }
        }
//        let parentViewController = self.navigationController?.viewControllers[0] as! DrillListViewController
        drillListItem = parentViewController?.selectedDrillItem

//
//        self.navigationController?.navigationBar.frame = CGRect(x: 0, y: 0, width: bounds.width, height: 50)
//
        let rightBarButton = UIBarButtonItem(customView: self.scoreView!)
        self.navigationItem.rightBarButtonItem = rightBarButton
        

        self.replayNextBgView.alpha = 0

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.resetView()
        
        let tracker = GAI.sharedInstance().defaultTracker
        tracker?.set(kGAIScreenName, value: "/videoplayer/" + String(self.drillListItem!.drillID))
        let build = (GAIDictionaryBuilder.createScreenView().build() as NSDictionary) as! [AnyHashable: Any]
        tracker?.send(build)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.removeVideoPlayer()
        super.viewWillDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if (self.replay || index + 1 ==  drillListItem?.questionCount) {
            return false
        }
        self.presenting = true
        self.removeVideoPlayer()
        return true
    }
    
    override var shouldAutorotate : Bool {
        return false
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }
    
    private func startDtill()
    {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        SharedNetworkConnection.apiPostRegisterDrill(apiToken: appDelegate.apiToken, drillID: drillListItem!.drillID, drillTitle: (drillListItem?.title)!, completionHandler: { data, response, error in
            guard let data = data, error == nil else {                                                 // check for fundamental networking error
                print("error=\(error)")
                return
            }
            
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
                // 403 on no token
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(response)")
                
                if (httpStatus.statusCode == 403)
                {
                    SharedNetworkConnection.apiLoginWithStoredCredentials(completionHandler: { data, response, error in
                        let appDelegate = UIApplication.shared.delegate as! AppDelegate
                        let json = try? JSONSerialization.jsonObject(with: data!, options: [])
                        if let dictionary = json as? [String: Any] {
                            if let apiToken = dictionary["token"] as? (String) {
                                appDelegate.apiToken = apiToken
                                self.startDtill()
                            }
                        }
                    })
                }
            }
            
            let json = try? JSONSerialization.jsonObject(with: data, options: [])
            if let dictionary = json as? [String: Any] {
                if let returnedDrillID = dictionary["id"] as? (Int) {
                    self.returnedDrillID = returnedDrillID
                }
            }
            
            
            let stringData = String(data: data, encoding: .utf8)!
            print(stringData)
        })
    }
    
    private func getDrillQuestions()
    {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        SharedNetworkConnection.apiGetDrillQuestions(apiToken: appDelegate.apiToken, drillID: drillListItem!.drillID, completionHandler: { data, response, error in
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
                            self.getDrillQuestions()
                        }
                    }                    
                })
                
                return
            }

            self.drillQuestionsParser = DrillQuestionParser(jsonString: String(data: data, encoding: .utf8)!)
            if (self.drillListItem?.randomize)! {
                self.drillQuestionsArray = (self.drillQuestionsParser?.getDrillQuestionArray())!.shuffled()
            }
            else {
                self.drillQuestionsArray = (self.drillQuestionsParser?.getDrillQuestionArray())!
            }
            self.startDtill()
            DispatchQueue.main.async {
                self.downloadVideo()
            }
        })
    }
    
    private func downloadVideo()
    {
        self.showIndicator(shouldAppear:true)
        let currentDrillQuestionItem = drillQuestionsArray[index]
        var cacheDirectory = try! FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        var filename = ""
        var hlsFile = ""
        if (!replay) {
            if currentDrillQuestionItem.occludedHlsVideo != "" {
                cacheDirectory.appendPathComponent((currentDrillQuestionItem.occludedHlsVideo as NSString).lastPathComponent)
                hlsFile = currentDrillQuestionItem.occludedHlsVideo
            } else {
                filename = currentDrillQuestionItem.occludedVideo
            }
        }
        else {
            cacheDirectory.appendPathComponent(currentDrillQuestionItem.fullVideo)
            if currentDrillQuestionItem.fullHlsVideo != "" {
                hlsFile = currentDrillQuestionItem.fullHlsVideo
            }
            filename = currentDrillQuestionItem.fullVideo
        }
        
//        if (FileManager.default.fileExists(atPath: cacheDirectory.path)) {
//            DispatchQueue.main.async {
//                self.updateVideoPlayer(videoURL: cacheDirectory)
//            }
//        }
        DispatchQueue.main.async {
            self.updateVideoPlayer(videoURL: URL(string: hlsFile)!, startPlaying: self.hasDrillStarted)
        }

//        else {
//
//        }
    }
    
    private func updateVideoPlayer(videoURL: URL, startPlaying: Bool = false)
    {
        self.removeVideoPlayer()
        if (!replay) {
            //set view bounds
            let asset = AVAsset(url: videoURL)
            let assetKeys = [
                "playable",
                "hasProtectedContent"
            ]
            let playerItem = AVPlayerItem(asset: asset,automaticallyLoadedAssetKeys: assetKeys)
            playerItem.preferredPeakBitRate = currentpreferredPeakBitRate
            let player = getPlayerInstance(playerItem: playerItem)
            //            let playerLayer = AVPlayerLayer(player: player)
            let playerLayer = AVPlayerLayer()
            playerLayer.player = player
            playerLayer.frame = self.movieView.bounds
            playerLayer.bounds = self.movieView.bounds

            //get size of screen
            let screenSize : CGRect = self.movieView.bounds
            let verticalClass = self.traitCollection.verticalSizeClass
            if verticalClass == UIUserInterfaceSizeClass.compact {
                let fullScreenSize = UIScreen.main.bounds
                self.movieView.frame = CGRect.init(x:0, y:63, width:fullScreenSize.width, height:fullScreenSize.height)
                self.movieView.bounds = CGRect.init(x:0, y:0, width:fullScreenSize.width, height:fullScreenSize.height)
                playerLayer.frame = CGRect.init(x:0, y:0, width:fullScreenSize.width, height:fullScreenSize.height)
                playerLayer.bounds = CGRect.init(x:0, y:0, width:fullScreenSize.width, height:fullScreenSize.height)
            } else {
                playerLayer.frame = CGRect.init(x:0, y:0, width:screenSize.width, height:(screenSize.width * 0.5625))
            }
            playerLayer.videoGravity = AVLayerVideoGravityResizeAspect
            self.movieView.layer.insertSublayer(playerLayer, at: 0)
            
            NotificationCenter.default.addObserver(self, selector: #selector(VideoPlayerViewController.playerFinished), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
            if startPlaying { player.play() }
            
            if drillListItem?.title.range(of:"RHP") != nil {
                self.replayNextBgView.center = CGPoint(x:playerLayer.frame.origin.x+playerLayer.frame.size.width/2+50,
                                                       y:playerLayer.frame.origin.y+playerLayer.frame.size.height/2)

            } else {
            self.replayNextBgView.center = CGPoint(x:playerLayer.frame.origin.x+playerLayer.frame.size.width/2-50,
                                                   y:playerLayer.frame.origin.y+playerLayer.frame.size.height/2)
            }
        }
        else {
            let asset = AVAsset(url: videoURL)
            let assetKeys = [
                "playable",
                "hasProtectedContent"
            ]
            let playerItem = AVPlayerItem(asset: asset,automaticallyLoadedAssetKeys: assetKeys)
            playerItem.preferredPeakBitRate = currentpreferredPeakBitRate
            let player = getPlayerInstance(playerItem: playerItem)
            let playerLayer = AVPlayerLayer(player: player)
            playerLayer.frame = self.movieView.bounds
            playerLayer.bounds = self.movieView.bounds
            //get size of screen
            let screenSize : CGRect = self.movieView.bounds
            playerLayer.frame = CGRect.init(x:0, y:0, width:screenSize.width, height:(screenSize.width * 0.5625))
            playerLayer.videoGravity = AVLayerVideoGravityResizeAspect
            self.movieView.layer.addSublayer(playerLayer)
            NotificationCenter.default.addObserver(self, selector: #selector(VideoPlayerViewController.replayFinished), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
            player.play()
            
            if drillListItem?.title.range(of:"RHP") != nil {
                self.replayNextBgView.center = CGPoint(x:playerLayer.frame.origin.x+playerLayer.frame.size.width/2+50,
                                                       y:playerLayer.frame.origin.y+playerLayer.frame.size.height/2)
                
            } else {
                self.replayNextBgView.center = CGPoint(x:playerLayer.frame.origin.x+playerLayer.frame.size.width/2-50,
                                                       y:playerLayer.frame.origin.y+playerLayer.frame.size.height/2)
            }


        }
        
//        self.replayNextBgView.center = CGPoint(x:self.movieView.center.x-35, y:self.movieView.center.y-50)

    }
    
    private func getPlayerInstance(playerItem: AVPlayerItem) -> AVPlayer {
        var player = AVPlayer(playerItem: playerItem)
        player.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions(), context: nil)
        player.addPeriodicTimeObserver(forInterval: CMTimeMake(1, 1), queue: DispatchQueue.main, using: { (time: CMTime) -> Void in
            if let lastEvent = player.currentItem?.accessLog()?.events.last {
                if self.currentpreferredPeakBitRate < lastEvent.observedBitrate {
                    self.currentpreferredPeakBitRate = lastEvent.observedBitrate
                }
            }
        })
        return player
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let player = object as? AVPlayer
        else {
            return
        }
        if (player.status == AVPlayerStatus.readyToPlay) {
            self.showIndicator(shouldAppear:false)
            let dq = self.childViewControllers[0] as! DrillQuestionsViewController
            dq.resetViewForDisplay()
        }
        else if (player.status == AVPlayerStatus.failed){
            self.showIndicator(shouldAppear:false)
            let alert = UIAlertController(title: "Sorry", message: "Your video failed to play. If this issue continues, please contact gamesenseSports at " + Constants.gamesenseSportsContact, preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            
            let currentDrillQuestionItem = drillQuestionsArray[index]
            var cacheDirectory = try! FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            
            if (!replay) {
                cacheDirectory.appendPathComponent(currentDrillQuestionItem.occludedVideo)
            }
            else {
                cacheDirectory.appendPathComponent(currentDrillQuestionItem.fullVideo)
            }
            
            try? FileManager.default.removeItem(atPath: cacheDirectory.path)
        }
        else
        {
            
        }
    }
    
    private func removeVideoPlayer()
    {
        if (self.movieView.layer.sublayers?.count == nil) {
            return
        }
        for layer in self.movieView.layer.sublayers!
        {
            guard let playerLayer = layer as? AVPlayerLayer else
            {
                continue
            }
            
            let player = playerLayer.player! as AVPlayer
            player.removeObserver(self, forKeyPath: "status")
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
            layer.removeFromSuperlayer()
        }
    }

    func replayDrillHandler(alert: UIAlertAction!) {
        self.drillQuestionsArray = self.drillQuestionsArray.shuffled()
        index = 0
        self.replay = false
        self.presenting = false
        self.points = 0
        self.locationPoints = 0
        self.typePoints = 0
        self.resetView()
        self.startDtill()
    }
    
    func doneHandler(alert: UIAlertAction!)
    {
        self.navigationController!.popViewController(animated: true)
    }

    public func resetView()
    {
        presenting = false
        if (index == 0) {
            if (!replay) {
                getDrillQuestions()
            }
            else {
                self.downloadVideo()
            }
        }
        else {
            if (index + 1 <= (drillListItem?.questionCount)!) {
                self.downloadVideo()
            }
            else {
                self.showIndicator(shouldAppear:true)
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                SharedNetworkConnection.apiDrillFinished(apiToken: appDelegate.apiToken, drill_id: (self.drillListItem?.drillID)!, activityID: self.returnedDrillID, score: self.points, locationScore: self.locationPoints, typeScore: self.typePoints, completionHandler:  { data, response, error in
                    guard let data = data, error == nil else {                                                 // check for fundamental networking error
                        print("error=\(error)")
                        return
                    }
                    
                    if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
                        // 403 on no token
                        print("statusCode should be 200, but is \(httpStatus.statusCode)")
                        print("response = \(response)")
                        
                        if (httpStatus.statusCode == 403)
                        {
                            SharedNetworkConnection.apiLoginWithStoredCredentials(completionHandler: { data, response, error in
                                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                                let json = try? JSONSerialization.jsonObject(with: data!, options: [])
                                if let dictionary = json as? [String: Any] {
                                    if let apiToken = dictionary["token"] as? (String) {
                                        appDelegate.apiToken = apiToken
                                        self.resetView()
                                    }
                                }
                            })
                        }
                    }
                    
                    let stringData = String(data: data, encoding: .utf8)!
                    print(stringData)
                    self.showIndicator(shouldAppear:false)
                    let maxPoints = (self.drillListItem?.questionCount)! * 25
                    let points = self.points
                    let recommendation = ((Double(points)/Double(maxPoints)) > 0.75) ? "start a new drill" : "repeat this drill"
                    let completeMessage = "You scored \(points) points out of a max of \(maxPoints) points. We recommend for you to \(recommendation)."
                    let alert = UIAlertController(title: "Drill Complete", message: completeMessage, preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "Replay", style: UIAlertActionStyle.default, handler: self.replayDrillHandler))
                    alert.addAction(UIAlertAction(title: "Done", style: UIAlertActionStyle.default, handler: self.doneHandler))
                    self.present(alert, animated: true, completion: nil)
                })
            }
        }
    }
    
    public func showIndicator(shouldAppear: Bool)
    {
        if (shouldAppear) {
            self.loadingView.isUserInteractionEnabled = false
            UIView.animate(withDuration: 0.3, delay: 0, options: UIViewAnimationOptions.allowAnimatedContent, animations: {
                self.loadingView.alpha = 1
            },completion: nil)
        }
        else {
            self.loadingView.isUserInteractionEnabled = false
            UIView.animate(withDuration: 0.3, delay: 0, options: UIViewAnimationOptions.allowAnimatedContent, animations: {
                self.loadingView.alpha = 0
            },completion: nil)
        }
    }
    
    func playerFinished()
    {
        if (!presenting) {
            let dq = self.childViewControllers[0] as! DrillQuestionsViewController
            dq.triggerCountdown()
        }
    }
    
    
    func replayFinished()
    {
        // Allow another replay
//        let alert = UIAlertController(title: (drillListItem?.title)! + " " + String(index + 1), message: nil, preferredStyle: UIAlertControllerStyle.alert)
//        alert.addAction(UIAlertAction(title: "Replay", style: UIAlertActionStyle.default, handler: replayHandler))
//        alert.addAction(UIAlertAction(title: "Next", style: UIAlertActionStyle.default, handler: nextHandler))
//        self.present(alert, animated: true, completion: nil)
        self.replayNextBgView.alpha = 1
    }
    
    @IBAction func playButtonPressed(_ sender: UIButton) {
        sender.isHidden = true
        (movieView.layer.sublayers?[0] as? AVPlayerLayer)?.player?.play()
        hasDrillStarted = true
        if onDrillStarted != nil {
            onDrillStarted!()
        }
    }
    
    
    
    @IBAction func replayClicked(_ sender: Any) {
        self.replay = true
        DispatchQueue.main.async {
            self.replayNextBgView.alpha = 0
            self.resetView()
        }
    }
    
    @IBAction func nextClicked(_ sender: Any) {
        self.replay = false
        self.index += 1
        DispatchQueue.main.async {
            self.replayNextBgView.alpha = 0
            if (self.index + 1 <= (self.drillListItem?.questionCount)!) {
                self.questionsTextField.text = "\(self.index+1)"
            }
            self.resetView()
        }
    }
    
    public func didShowQuestionNumberAndPoints(pitch: Int, totalPoints: Int) {
        self.questionsTextField.text = "\(pitch)"
        self.pointsTextField.text = "\(totalPoints)"
        self.replayNextBgView.alpha = 1
    }
}

