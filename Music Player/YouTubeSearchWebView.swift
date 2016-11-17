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
    func didTapDownloadButton(_ url: URL)
}


enum YoutubeUrlType {
    case playlist(id: String)
    case video(id: String)
    case other
}


class YouTubeSearchWebView: WKWebView {

    fileprivate let downloadButton = UIButton()
    
    var delegate: YouTubeSearchWebViewDelegate?
    
    init() {
        let conf = WKWebViewConfiguration()
        //doesn't work
        /*if #available(iOS 9.0, *) {
            conf.requiresUserActionForMediaPlayback = true
        } else {
            conf.mediaPlaybackRequiresUserAction = true
        }
        conf.allowsInlineMediaPlayback = true*/
        super.init(frame: CGRect.zero, configuration: conf)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func setup() {
        allowsBackForwardNavigationGestures = true
        addDownloadButton()
        addObserver(self, forKeyPath:"URL", options:.new, context:nil)
    }
    
    deinit {
        removeObserver(self, forKeyPath: "URL")
    }
    
    func didTapDownloadButton() {
        if let url = self.url {
            delegate?.didTapDownloadButton(url)
        }
    }
    
    
    // MARK: Check URL
    
    fileprivate func didChangeURL(_ url: URL) {
        switch detectURLType(url) {
        case .playlist, .video: enableButton()
        case .other: disableButton()
        }
    }
    
    
    // MARK: Download Button
    
    fileprivate func addDownloadButton() {
        downloadButton.setTitle("↓", for: UIControlState())
        downloadButton.setTitleColor(UIColor.white, for: UIControlState())
        downloadButton.titleLabel?.font = UIFont(name: "HiraKakuProN-W6", size: 20)!
        disableButton()
        
        // add
        let btnSize: CGFloat = 44
        let margin: CGFloat = 12
        downloadButton.layer.cornerRadius = btnSize / 2
        addSubview(downloadButton)
        downloadButton.snp.makeConstraints { make in
            _ = make.size.equalTo(btnSize)
            _ = make.right.equalTo(self).offset(-margin)
            _ = make.bottom.equalTo(self).offset(-margin)
        }

        downloadButton.addTarget(self, action: #selector(YouTubeSearchWebView.didTapDownloadButton), for: .touchUpInside)
    }
    
    fileprivate func disableButton() {
        downloadButton.isEnabled = false
        downloadButton.backgroundColor = UIColor.gray
        downloadButton.alpha = 0.1
    }

    fileprivate func enableButton() {
        downloadButton.isEnabled = true
        downloadButton.backgroundColor = UIColor.red
        UIView.animate(withDuration: 0.2, animations: { self.downloadButton.alpha = 1 }) 
    }
    
}



// util
extension YouTubeSearchWebView {
    
    fileprivate func detectURLType(_ url: URL) -> YoutubeUrlType {
        let (videoId, playlistId) = MiscFuncs.parseIDs(url: url.absoluteString)
        if let videoId = videoId {
            return YoutubeUrlType.video(id: videoId)
        }
        else if let playlistId = playlistId {
            return YoutubeUrlType.playlist(id: playlistId)
        }
        else {
            return YoutubeUrlType.other
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let keyPath = keyPath {
            switch keyPath {
            case "URL":
                if let url = change![NSKeyValueChangeKey.newKey] as? URL {
                    didChangeURL(url)
                }
            default: return
            }
        }
    }
}
