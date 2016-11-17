//
//  AVAssetAudio.swift
//  Music Player
//
//  Created by Samuel Chu on 2/20/16.
// copied from http://stackoverflow.com/questions/31879470/extract-audio-from-video-avfoundation

import Foundation

extension AVAsset {
    
    func writeAudioTrackToURL(_ URL: NSURL, completion: @escaping (Bool, NSError?) -> ()) {
        
        do {
            
            let audioAsset = try self.audioAsset()
            audioAsset.writeToURL(URL, completion: completion)
            
        } catch (let error as NSError){
            
            completion(false, error)
            
        } catch {
            
            print("\(type(of: self)), error:\(error)")
        }
    }
    
    func writeToURL(_ URL: NSURL, completion: @escaping (Bool, NSError?) -> ()) {
        
        guard let exportSession = AVAssetExportSession(asset: self, presetName: AVAssetExportPresetAppleM4A) else {
            completion(false, nil)
            return
        }
        
        exportSession.outputFileType = AVFileTypeAppleM4A
        exportSession.outputURL      = URL as URL
        
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                completion(true, nil)
            case .unknown, .waiting, .exporting, .failed, .cancelled:
                completion(false, nil)
            }
        }
    }
    
    func audioAsset() throws -> AVAsset {
        
        let composition = AVMutableComposition()
        
        let audioTracks = tracks(withMediaType: AVMediaTypeAudio)
        
        for track in audioTracks {
            
            let compositionTrack = composition.addMutableTrack(withMediaType: AVMediaTypeAudio, preferredTrackID: kCMPersistentTrackID_Invalid)
            do {
                try compositionTrack.insertTimeRange(track.timeRange, of: track, at: track.timeRange.start)
            } catch {
                throw error
            }
            compositionTrack.preferredTransform = track.preferredTransform
        }
        return composition
    }
}
