//
//  AVAssetAudio.swift
//  Music Player
//
//  Created by Samuel Chu on 2/20/16.
// copied from http://stackoverflow.com/questions/31879470/extract-audio-from-video-avfoundation

import Foundation

extension AVAsset {
    
    func writeAudioTrackToURL(URL: NSURL, completion: (Bool, NSError?) -> ()) {
        
        do {
            
            let audioAsset = try self.audioAsset()
            audioAsset.writeToURL(URL, completion: completion)
            
        } catch (let error as NSError){
            
            completion(false, error)
            
        } catch {
            
            print("\(self.dynamicType) \(__FUNCTION__) [\(__LINE__)], error:\(error)")
        }
    }
    
    func writeToURL(URL: NSURL, completion: (Bool, NSError?) -> ()) {
        
        guard let exportSession = AVAssetExportSession(asset: self, presetName: AVAssetExportPresetAppleM4A) else {
            completion(false, nil)
            return
        }
        
        exportSession.outputFileType = AVFileTypeAppleM4A
        exportSession.outputURL      = URL
        
        exportSession.exportAsynchronouslyWithCompletionHandler {
            switch exportSession.status {
            case .Completed:
                completion(true, nil)
            case .Unknown, .Waiting, .Exporting, .Failed, .Cancelled:
                completion(false, nil)
            }
        }
    }
    
    func audioAsset() throws -> AVAsset {
        
        let composition = AVMutableComposition()
        
        let audioTracks = tracksWithMediaType(AVMediaTypeAudio)
        
        for track in audioTracks {
            
            let compositionTrack = composition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: kCMPersistentTrackID_Invalid)
            do {
                try compositionTrack.insertTimeRange(track.timeRange, ofTrack: track, atTime: track.timeRange.start)
            } catch {
                throw error
            }
            compositionTrack.preferredTransform = track.preferredTransform
        }
        return composition
    }
}