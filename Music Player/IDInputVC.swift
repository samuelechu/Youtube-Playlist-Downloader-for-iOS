//
//  IDInputvc.swift
//  Music Player
//
//  Created by Sem on 7/3/15.
//  Copyright (c) 2015 Sem. All rights reserved.
//

import UIKit
import CoreData

class IDInputvc: UIViewController, DownloaderDelegate {
    
    @IBOutlet var vidID: UITextView!
    @IBOutlet var downloadButton: UIButton!
    @IBOutlet var initializingLabel: UILabel!
    @IBOutlet var indicator: UIActivityIndicatorView!
    
    var downloader: Downloader!
    var settings : NSManagedObject!
    
    // Please Call
    func setup(downloadListView downloadListView : DownloadListView) {
        downloader = Downloader(downloadListView: downloadListView)
        
        downloader.delegate = self
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "DismissKeyboard")
        view.addGestureRecognizer(tap)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        settings = MiscFuncs.getSettings()
        vidID.text = settings.valueForKey("playlist") as? String ?? "https://www.youtube.com/playlist?list=PLyD2IQPajS7Z3VcvQmqJWPOQtXQ1qnDha"
        //hide download button if downloads are being queued
        manageButtons(dlButtonHidden: (downloader.downloadListView.dlButtonIsHidden()))
    }
    
    //hide download button and show download intializing buttons
    func manageButtons(dlButtonHidden dlButtonHidden: Bool){
        downloadButton.hidden = dlButtonHidden
        initializingLabel.hidden = !dlButtonHidden
        if dlButtonHidden {
            indicator.startAnimating()
        }
        else{
            indicator.stopAnimating()
        }
    }
    
    func DismissKeyboard(){
        view.endEditing(true)
    }
    @IBAction func finishedEditing() {
        view.endEditing(true)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func startDownloadTask() {
        
        let (_, playlistId) = MiscFuncs.parseIDs(url: vidID.text ?? "")
        if playlistId != nil {
            settings.setValue(vidID.text, forKey: "playlist")
        }
        
        downloader.startDownloadVideoOrPlaylist(url: vidID.text ?? "")
        navigationController?.popViewControllerAnimated(true)
    }
    
    // MARK: DownloaderDelegate
    func hideDownloadButton() {
        manageButtons(dlButtonHidden: false)
    }
}
