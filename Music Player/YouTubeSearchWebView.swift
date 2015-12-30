//
//  YouTubeSearchWebView.swift
//  Music Player
//
//  Created by Takuya Okamoto on 2015/12/30.
//  Copyright © 2015年 Sem. All rights reserved.
//

import UIKit
import WebKit
import SnapKit

protocol YouTubeSearchWebViewDelegate {
    func didTapDownloadButton(url: NSURL)
}

class YouTubeSearchWebView: WKWebView {

    private let downloadButton = UIButton()
    
    var delegate: YouTubeSearchWebViewDelegate?
    
    init() {
        let conf = WKWebViewConfiguration()
        super.init(frame: CGRectZero, configuration: conf)
        setup()
    }
    
    private func setup() {
        allowsBackForwardNavigationGestures = true
        addDownloadButton()
        addObserver(self, forKeyPath:"URL", options:.New, context:nil)
    }
    
    deinit {
        removeObserver(self, forKeyPath: "URL")
    }
    
    func didTapDownloadButton() {
        if let url = self.URL {
            delegate?.didTapDownloadButton(url)
        }
    }
    
    
    // MARK: Check URL
    
    private func didChangeURL(url: NSURL) {
        if isPlaylistURL(url) {
            enableButton()
        }
        else {
            disableButton()
        }
    }
    
    
    // MARK: Download Button
    
    private func addDownloadButton() {
        downloadButton.setTitle("↓", forState: .Normal)
        downloadButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        downloadButton.titleLabel?.font = UIFont(name: "HiraKakuProN-W6", size: 20)
        disableButton()
        
        // add
        let btnSize: CGFloat = 44
        let margin: CGFloat = 12
        downloadButton.layer.cornerRadius = btnSize / 2
        addSubview(downloadButton)
        downloadButton.snp_makeConstraints { make in
            make.size.equalTo(btnSize)
            make.right.equalTo(self).offset(-margin)
            make.bottom.equalTo(self).offset(-margin)
        }

        downloadButton.addTarget(self, action: "didTapDownloadButton", forControlEvents: .TouchUpInside)
    }
    
    private func disableButton() {
        downloadButton.enabled = false
        downloadButton.backgroundColor = UIColor.grayColor()
        downloadButton.alpha = 0.1
    }

    private func enableButton() {
        downloadButton.enabled = true
        downloadButton.backgroundColor = UIColor.redColor()
        UIView.animateWithDuration(0.2) { self.downloadButton.alpha = 1 }
    }
    
}



// util
extension YouTubeSearchWebView {
    
    private func isPlaylistURL(url: NSURL) -> Bool {
        if let comp = NSURLComponents(URL: url, resolvingAgainstBaseURL: true) {
            if let queryItems = comp.queryItems {
                var isPlaylist = false
                queryItems.forEach { item in
                    if item.name == "list" {
                        isPlaylist = true
                    }
                }
                return isPlaylist
            }
            return false
        }
        return false
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if let keyPath = keyPath {
            switch keyPath {
            case "URL":
                if let url = change![NSKeyValueChangeNewKey] as? NSURL {
                    didChangeURL(url)
                }
            default: return
            }
        }
    }
}