//
//  PlaylistProtocols.swift
//  Music Player
//
//  Created by Samuel Chu on 3/21/16.
//  Copyright © 2016 Sem. All rights reserved.
//

import Foundation


protocol PlaylistViewControllerDelegate{
    func pushWebView()
    func startPlayer()
}

protocol PlaylistDelegate{
    func seekForward()
    func seekBackward()
    func togglePlayPause()
    func advance()
    func retreat()
    func updateNowPlayingInfo()
    func stop()
}