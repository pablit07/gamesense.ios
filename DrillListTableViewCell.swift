//
//  DrillListTableViewCell.swift
//  gameSenseSports
//
//  Created by Paul Kohlhoff on 6/1/17.
//  Copyright © 2017 gameSenseSports. All rights reserved.
//

import UIKit

class DrillListTableViewCell: UITableViewCell {

    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var startDownload: UIButton!
    
    var drillId : Int? = nil
    var title : String? = nil
    var numberToDownload = 0
    var completedDownloads = 0
    var isCached = false
    var cacheData:DrillListTableViewData? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    private func downloadError(alert:UIAlertController, parentController:DrillListViewController) {
        self.progressView.isHidden = true
        self.startDownload.isHidden = false
        alert.message = "Your drill \(self.title!) failed to download. If this issue continues, please contact gamesenseSports at " + Constants.gamesenseSportsContact
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
        parentController.present(alert, animated: true, completion: nil)
    }
    
    private func updateNumberForDownload(numberForDownload: Int) {
        self.numberToDownload = numberForDownload
    }
    
    private func updateNumberDownloaded(numberToDownload:Float, completedDownloads:Float) {
        self.completedDownloads += 1
        let progress = (Float(completedDownloads) / Float(numberToDownload))
        self.progressView.setProgress(progress, animated: true)
        if completedDownloads == numberToDownload {
            self.clearNumberForDownload()
            self.progressView.isHidden = true
        }
    }
    
    public func updateIsCached(isCached:Bool) {
        self.startDownload.isHidden = isCached || !self.progressView.isHidden
    }
    
    private func clearNumberForDownload() {
        self.progressView.progress = 0
        self.numberToDownload = 0
    }
    
    @IBAction func startDownloadButtonTap(_ sender: UIButton) {
        if self.drillId != nil {
            self.startDownload.isHidden = true
            self.progressView.isHidden = false
            self.clearNumberForDownload()
            self.cacheData?.populateCache(drillId: self.drillId, progress: self.updateNumberDownloaded, onerror: self.downloadError)
        }
    }
}

extension UIView {
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder!.next
            if parentResponder is UIViewController {
                return parentResponder as! UIViewController!
            }
        }
        return nil
    }
}
