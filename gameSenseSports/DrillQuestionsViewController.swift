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
    private var pitchArray = Array<Any>()
    private var drillVideoItem = DrillVideoItem(json: [:])
    
    public var answered = false
    public var answeredCorrectly = false
    public var alternateColor = false
    
    public var correctPitchLocationID = -1
    public var correctPitchTypeID = -1
    
    public var answeredPitchLocationID = -1
    public var answeredPitchTypeID = -1
    
    public var isLandscape = false

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.view.alpha = 0
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
        questionsLabel.text = String(parentViewController.index + 1)
        drillQuestionItem = parentViewController.drillQuestionsArray[parentViewController.index]
        getPitchLocations()
    }
    
    private func getPitchLocations()
    {
        self.pitchArray = (drillQuestionItem?.pitchArray)!
        DispatchQueue.main.async {
            self.pitchesTable.reloadData()
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
        if let dictionary = drillPitchItem as? [String: Any]
        {
            let pitchLabel = cell.viewWithTag(3) as! UILabel
            pitchLabel.text = dictionary["name"] as! String?
            let hiddenLabel = cell.viewWithTag(4) as! UILabel
            let idNum = dictionary["id"] as! Int
            hiddenLabel.text = String(idNum)
        }
        
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
    
    func nextVideo(pitchType: Int, pitchLocation: Int)
    {
        let parentViewController = self.parent as! VideoPlayerViewController
        parentViewController.replay = false
        parentViewController.index += 1
        self.view.alpha = 0
        parentViewController.resetView()
    }
    
    func storeAnswer(pitchType: Int, pitchLocation: Int)
    {
        let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("answers.txt")
        
        if let outputStream = OutputStream(url: fileURL, append: true) {
            outputStream.open()
            //json file structure to come
            var text = "Pitch: \(pitchType) \(pitchLocation) \(drillQuestionItem?.drillQuestionID)"
            text = text + "\n"
            let bytesWritten = outputStream.write(text, maxLength: text.lengthOfBytes(using: String.Encoding.utf8))
            if bytesWritten < 0 { print("write failure") }
            outputStream.close()
        } else {
            print("Unable to open file")
        }
    }
    
    @IBAction func buttonPressed(sender: UIButton) {
        self.answered = true
        let hiddenLabel = sender.superview?.viewWithTag(4) as! UILabel
        self.storeAnswer(pitchType: Int(hiddenLabel.text!)!, pitchLocation: sender.tag)
        self.nextVideo(pitchType: Int(hiddenLabel.text!)!, pitchLocation: sender.tag)
    }
}
