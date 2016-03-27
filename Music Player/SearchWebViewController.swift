//
//  SearchWebViewController.swift
//  Music Player
//
//  Created by Takuya Okamoto on 2015/12/30.
//  Copyright © 2015年 Sem. All rights reserved.
//

import UIKit
import WebKit

class SearchWebViewController: UIViewController, YouTubeSearchWebViewDelegate {
    
    let webView: YouTubeSearchWebView
    
    var downloadManager: DownloadManager!
    
    // Please Call
    func setup(downloadTable : downloadTableViewControllerDelegate, playlistName: String) {
        downloadManager = DownloadManager(downloadTable : downloadTable, playlistName: playlistName)
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        self.webView = YouTubeSearchWebView()
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setup()
    }
    required init?(coder aDecoder: NSCoder) {
        self.webView = YouTubeSearchWebView()
        super.init(coder: aDecoder)
        setup()
    }
    init() {
        self.webView = YouTubeSearchWebView()
        super.init(nibName: nil, bundle: nil)
        setup()
    }
    private func setup() {
        webView.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let tabBarHeight: CGFloat = tabBarController?.tabBar.frame.size.height ?? 0

        webView.frame = CGRect(
            x: 0,
            y: 0,
            width: view.frame.width,
            height: view.frame.height - tabBarHeight
        )
        view.addSubview(webView)
        
        let req = NSURLRequest(URL: NSURL(string:"https://www.youtube.com")!)
        webView.loadRequest(req)
    }
    
    // MARK: YouTubeSearchWebViewDelegate
    func didTapDownloadButton(url: NSURL) {
        downloadManager.startDownloadVideoOrPlaylist(url: url.absoluteString)
        self.navigationController?.popViewControllerAnimated(true)
    }
}