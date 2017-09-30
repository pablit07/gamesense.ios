//
//  SlideshowViewController.swift
//  gameSenseSports
//
//  Created by Paul Kohlhoff on 9/30/17.
//  Copyright © 2017 gameSenseSports. All rights reserved.
//

import Foundation

class SlideshowViewController : UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    var slideIndex = 0
    var slideImages = [
        "welcomescreen.png",
        "drill_list.png",
        "pitcher_profile",
        "completing drills.png",
        "post-drill response.png",
        "yours_stats.png",
        "the end.png"
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let currentOrientationValue = UIDevice.current.orientation
        if currentOrientationValue != UIDeviceOrientation.portrait {
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        }
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action:#selector(self.previousImage))
        swipeRight.direction = .right;
        self.view.addGestureRecognizer(swipeRight)
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(self.nextImage))
        swipeLeft.direction = .left;
        self.view.addGestureRecognizer(swipeLeft)
        
        updateImage()
    }
    
    private func updateImage() {
        imageView.image = UIImage(named: slideImages[slideIndex])
    }
    
    func previousImage(gestureRecognizer:UISwipeGestureRecognizer) {
        if slideIndex > 0 {
            slideIndex -= 1;
            updateImage()
        }
    }
    
    func nextImage(gestureRecognizer:UISwipeGestureRecognizer) {
        if slideIndex < (slideImages.count - 1) {
            slideIndex += 1
            updateImage()
        } else if slideIndex == (slideImages.count - 1) {
            // go to app
            let transition: CATransition = CATransition()
            transition.duration = 0.5
            transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            transition.type = kCATransitionReveal
            transition.subtype = kCATransitionFromRight
            self.view.window!.layer.add(transition, forKey: nil)
            self.dismiss(animated: false, completion: nil)
        }
    }
}
