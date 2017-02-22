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

    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var modalButton: UIButton!
    @IBOutlet weak var movieView: UIView!
    @IBOutlet weak var loadingView: UIView!
    
    
    private var drillQuestionsParser = DrillQuestionParser(jsonString: "")
    private var drillListItem = DrillListItem(json: [:])
    private var presenting = false
    
    private var drillStartTime = ""
    
    public var drillQuestionsArray = [DrillQuestionItem]()
    public var replay = false
    public var index = 0

    
    public var returnedDrillID = -1
    public var allowRotation = true
    
    private var containerPadding = CGFloat(0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.containerPadding = self.containerView.frame.origin.x
        // Do any additional setup after loading the view, typically from a nib.
        self.movieView.backgroundColor = UIColor.black

        //Reds - Loaded from Bundle
        let jsonString = self.setDrillVariables()
        let data = jsonString.data(using: String.Encoding.utf8, allowLossyConversion: false)!
        let json = try? JSONSerialization.jsonObject(with: data, options: [])
        if let dictionary = json as? [String: Any] {
            self.drillListItem = DrillListItem(json: dictionary)
            print(dictionary)
        }
    }
    
    private func setDrillVariables()->String
    {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        var jsonString = ""
        if (appDelegate.batterHand == "right")
        {
            jsonString = AppDelegate.readJsonFile(fileName: "test-ab", bundle: Bundle(for: type(of: self)))
            self.containerView.autoresizingMask = [.flexibleTopMargin, .flexibleRightMargin]
            self.containerView.frame.origin.x = self.containerPadding
        }
        else
        {
            jsonString = AppDelegate.readJsonFile(fileName: "test-cd", bundle: Bundle(for: type(of: self)))
            self.containerView.autoresizingMask = [.flexibleTopMargin, .flexibleLeftMargin]
            self.containerView.frame.origin.x = self.view.frame.width - self.containerView.frame.origin.x - self.containerView.frame.width
        }
        return jsonString
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.resetView()
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
    
    private func getDrillQuestions()
    {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        var jsonString = ""
        if (appDelegate.batterHand == "right")
        {
            jsonString = AppDelegate.readJsonFile(fileName: "test-questions-ab", bundle: Bundle(for: type(of: self)))
        }
        else
        {
            jsonString = AppDelegate.readJsonFile(fileName: "test-questions-cd", bundle: Bundle(for: type(of: self)))
        }
        
        let data = jsonString.data(using: String.Encoding.utf8, allowLossyConversion: false)!
        self.drillQuestionsParser = DrillQuestionParser(jsonString: String(data: data, encoding: .utf8)!)
        if (self.drillListItem?.randomize)! {
            self.drillQuestionsArray = (self.drillQuestionsParser?.getDrillQuestionArray())!.shuffled()
        }
        else {
            self.drillQuestionsArray = (self.drillQuestionsParser?.getDrillQuestionArray())!
        }
        DispatchQueue.main.async {
            self.downloadVideo()
        }
    }
    
    private func downloadVideo()
    {
        self.showIndicator(shouldAppear:true)
        let currentDrillQuestionItem = drillQuestionsArray[index]
        var fullFileName = currentDrillQuestionItem.occludedVideo.components(separatedBy: ".")
        
        let bundle = Bundle.main
        let path = bundle.path(forResource: fullFileName[0], ofType: "mp4")
        
        if (FileManager.default.fileExists(atPath: path!)) {
            DispatchQueue.main.async {
                self.updateVideoPlayer(videoURL: Bundle.main.url(forResource: fullFileName[0], withExtension:"mp4", subdirectory:"/")!)
            }
        }
    }
    
    private func updateVideoPlayer(videoURL: URL)
    {
        self.removeVideoPlayer()
        if (!replay) {
            //set view bounds
            let player = AVPlayer(url: videoURL)
            player.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions(), context: nil)
            let playerLayer = AVPlayerLayer(player: player)
            playerLayer.frame = self.movieView.bounds
            playerLayer.bounds = self.movieView.bounds

            playerLayer.videoGravity = AVLayerVideoGravityResizeAspect
            self.movieView.layer.addSublayer(playerLayer)
            
            NotificationCenter.default.addObserver(self, selector: #selector(VideoPlayerViewController.playerFinished), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
            player.play()
        }
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
            allowRotation = false
        }
        else if (player.status == AVPlayerStatus.failed) {
            self.showIndicator(shouldAppear:false)
            let alert = UIAlertController(title: "Sorry", message: "Your video failed to play. If this issue continues, please contact gamesenseSports at " + Constants.gamesenseSportsContact, preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            self.dismiss(animated: false, completion: nil)
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
    
    func nextHandler(alert: UIAlertAction!)
    {
        self.replay = false
        self.index += 1
        self.resetView()
    }
    
    func doneHandler(alert: UIAlertAction!)
    {
        self.dismiss(animated: true, completion: nil)
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
                let alertController = UIAlertController(title: "Done", message:
                    "Drill Complete", preferredStyle: UIAlertControllerStyle.alert)
                alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: doneHandler))
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    public func showIndicator(shouldAppear: Bool)
    {
        if (shouldAppear) {
            self.loadingView.isUserInteractionEnabled = false
            UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions.allowAnimatedContent, animations: {
                self.loadingView.alpha = 1
            },completion: { finished in
            })
        }
        else {
            self.loadingView.isUserInteractionEnabled = false
            UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions.allowAnimatedContent, animations: {
                self.loadingView.alpha = 0
            },completion: { finished in
            })
        }
    }
    
    func playerFinished()
    {
        allowRotation = true
        if (!presenting) {
            let dq = self.childViewControllers[0] as! DrillQuestionsViewController
            dq.resetViewForDisplay()
        }
    }
}

