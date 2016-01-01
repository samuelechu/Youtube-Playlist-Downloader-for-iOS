//
//  IDInputvc.swift
//  Music Player
//
//  Created by Sem on 7/3/15.
//  Copyright (c) 2015 Sem. All rights reserved.
//

import UIKit


class IDInputvc: UIViewController, DownloaderDelegate {
    
    @IBOutlet var vidID: UITextView!
    @IBOutlet var downloadButton: UIButton!
    @IBOutlet var initializingLabel: UILabel!
    @IBOutlet var indicator: UIActivityIndicatorView!
    
    var downloader: Downloader!
    
    // Please Call
    func setup(tableViewDelegate tableDelegate : inputVCTableDelegate) {
        downloader = Downloader(tableDelegate: tableDelegate)
        
        downloader.delegate = self
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "DismissKeyboard")
        view.addGestureRecognizer(tap)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        //hide download button if downloads are being queued
        manageButtons(dlButtonHidden: (downloader.tableDelegate.dlButtonIsHidden()))
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
        downloader.startDownloadTask(vidID.text ?? "")
        navigationController?.popViewControllerAnimated(true)
    }
    
    // MARK: DownloaderDelegate
    func hideDownloadButton() {
        manageButtons(dlButtonHidden: false)
    }
}
