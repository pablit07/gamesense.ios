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
    
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var modalButton: UIButton!
    
    private var drillQuestionsParser = DrillQuestionParser(jsonString: "")
    private var drillListItem = DrillListItem(json: [:])
    private var presenting = false
    
    private var drillStartTime = ""
    
    public var drillQuestionsArray = [DrillQuestionItem]()
    public var replay = false
    public var index = 0

    public var points = 0
    public var locationPoints = 0
    public var typePoints = 0
    
    public var returnedDrillID = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let parentViewController = self.navigationController?.viewControllers[0] as! DrillListViewController
        drillListItem = parentViewController.selectedDrillItem
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
        self.loadingIndicator?.startAnimating()
        let currentDrillQuestionItem = drillQuestionsArray[index]
        var cacheDirectory = try! FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        var filename = ""
        if (!replay) {
            cacheDirectory.appendPathComponent(currentDrillQuestionItem.occludedVideo)
            filename = currentDrillQuestionItem.occludedVideo
        }
        else {
            cacheDirectory.appendPathComponent(currentDrillQuestionItem.fullVideo)
            filename = currentDrillQuestionItem.fullVideo
        }
        
        if (FileManager.default.fileExists(atPath: cacheDirectory.path)) {
            DispatchQueue.main.async {
                self.updateVideoPlayer(videoURL: cacheDirectory)
            }
        }
        else {
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
                DispatchQueue.main.async {
                    self.updateVideoPlayer(videoURL: cacheDirectory)
                }
            })
        }
    }
    
    private func updateVideoPlayer(videoURL: URL)
    {
        self.removeVideoPlayer()
        if (!replay) {
            let player = AVPlayer(url: videoURL)
            player.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions(), context: nil)
            let playerLayer = AVPlayerLayer(player: player)
            playerLayer.frame = self.view.bounds
            playerLayer.bounds = self.view.bounds
            //get size of screen
            let screenSize : CGRect = UIScreen.main.bounds
            playerLayer.frame = CGRect.init(x:0, y:75, width:screenSize.width, height:(screenSize.width * 0.5625))
            playerLayer.videoGravity = AVLayerVideoGravityResizeAspect
            self.view.layer.addSublayer(playerLayer)
            NotificationCenter.default.addObserver(self, selector: #selector(VideoPlayerViewController.playerFinished), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
            player.play()
        }
        else {
            let player = AVPlayer(url: videoURL)
            player.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions(), context: nil)
            let playerLayer = AVPlayerLayer(player: player)
            playerLayer.frame = self.view.bounds
            playerLayer.bounds = self.view.bounds
            //get size of screen
            let screenSize : CGRect = UIScreen.main.bounds
            playerLayer.frame = CGRect.init(x:0, y:75, width:screenSize.width, height:(screenSize.width * 0.5625))
            playerLayer.videoGravity = AVLayerVideoGravityResizeAspect
            self.view.layer.addSublayer(playerLayer)
            NotificationCenter.default.addObserver(self, selector: #selector(VideoPlayerViewController.replayFinished), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
            player.play()
        }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let player = object as? AVPlayer
        else {
            return
        }
        if (player.status == AVPlayerStatus.readyToPlay) {
            self.loadingIndicator?.stopAnimating()
        }
        else if (player.status == AVPlayerStatus.failed){
            self.loadingIndicator?.stopAnimating()
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
        for layer in self.view.layer.sublayers!
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
    
    func replayFinished()
    {
        // Allow another replay
        let alert = UIAlertController(title: (drillListItem?.title)! + " " + String(index + 1), message: nil, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Replay", style: UIAlertActionStyle.default, handler: replayHandler))
        alert.addAction(UIAlertAction(title: "Next", style: UIAlertActionStyle.default, handler: nextHandler))
        self.present(alert, animated: true, completion: nil)
    }
    
    func replayHandler(alert: UIAlertAction!) {
        self.resetView()
    }
    
    func nextHandler(alert: UIAlertAction!)
    {
        self.replay = false
        self.index += 1
        self.resetView()
    }

    func replayDrillHandler(alert: UIAlertAction!) {
        self.drillQuestionsArray = self.drillQuestionsArray.shuffled()
        index = 0
        self.replay = false
        self.presenting = false
        self.points = 0
        self.locationPoints = 0
        self.typePoints = 0
        self.startDtill()
        self.resetView()
    }
    
    func doneHandler(alert: UIAlertAction!)
    {
        self.dismiss(animated: true, completion: nil)
    }

    private func resetView()
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
                self.loadingIndicator?.startAnimating()
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
                    self.loadingIndicator?.stopAnimating()
                    
                    let alert = UIAlertController(title: (self.drillListItem?.title)!, message: "Drill Finished", preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "Replay", style: UIAlertActionStyle.default, handler: self.replayDrillHandler))
                    alert.addAction(UIAlertAction(title: "Done", style: UIAlertActionStyle.default, handler: self.doneHandler))
                    self.present(alert, animated: true, completion: nil)
                })
            }
        }
    }
    
    func playerFinished()
    {
        if (!presenting) {
            self.performSegue(withIdentifier: "DrillQuestions", sender: self)
        }
    }
}

