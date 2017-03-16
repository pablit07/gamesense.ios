//
//  TutorialViewController.swift
//  gameSenseSports
//
//  Created by Ra on 3/16/17.
//  Copyright © 2017 gameSenseSports. All rights reserved.
//

import Foundation
import AVFoundation
import AVKit

import MobileCoreServices

import UIKit

class TutorialViewController: UIViewController
{
    @IBOutlet weak var movieView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let bundle = Bundle.main
        let path = bundle.path(forResource: "PR-Test-Instructions-317", ofType: "mp4")
        
        if (FileManager.default.fileExists(atPath: path!)) {
            self.loadTutorial(videoURL: Bundle.main.url(forResource: "PR-Test-Instructions-317", withExtension:"mp4", subdirectory:"/")!)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.removeVideoPlayer()
        super.viewWillDisappear(animated)
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
    
    private func loadTutorial(videoURL: URL)
    {
        let player = AVPlayer(url: videoURL)
        player.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions(), context: nil)
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = self.movieView.bounds
        playerLayer.bounds = self.movieView.bounds
        
        playerLayer.videoGravity = AVLayerVideoGravityResizeAspect
        self.movieView.layer.addSublayer(playerLayer)
        
        NotificationCenter.default.addObserver(self, selector: #selector(TutorialViewController.playerFinished), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        player.play()
    }
    
    func playerFinished()
    {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let player = object as? AVPlayer
            else {
                return
        }
        if (player.status == AVPlayerStatus.readyToPlay) {
        }
        else if (player.status == AVPlayerStatus.failed) {
        }
        else
        {
            
        }
    }
}
