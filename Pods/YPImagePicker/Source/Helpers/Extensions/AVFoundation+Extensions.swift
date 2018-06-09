//
//  AVCaptureDevice+Extensions.swift
//  YPImagePicker
//
//  Created by Nik Kov on 09.04.18.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation

// MARK: - Global functions

public func createVideoItem(videoURL: URL,
                            activityIdicatorClosure: ((_ show: Bool) -> Void)? = nil,
                            completion: @escaping (_ video: YPMediaVideo) -> Void) {
    
    let videoItem = YPMediaVideo(thumbnail: thumbnailFromVideoPath(videoURL),
                            videoURL: videoURL)
    
    activityIdicatorClosure?(true)
    
    DispatchQueue.global(qos: .background).async {
        
        // Compress Video to 640x480 format.
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        if let firstPath = paths.first {
            
            let path = firstPath + "/\(Int(Date().timeIntervalSince1970))temporary.mov"
            let uploadURL = URL(fileURLWithPath: path)
            let asset = AVURLAsset(url: videoURL)
            
            let exportSession = AVAssetExportSession(asset: asset,
                                                     presetName: YPConfig.videoCompression)
            exportSession?.outputURL = uploadURL
            exportSession?.outputFileType = AVFileType.mov
            exportSession?.shouldOptimizeForNetworkUse = true
            exportSession?.exportAsynchronously {
                switch exportSession!.status {
                case .completed:
                    DispatchQueue.main.async {
                        activityIdicatorClosure?(false)
                        completion(videoItem)
                    }
                default:
                    DispatchQueue.main.async {
                        print("⚠️ createVideoItem >>> Error in creating the video item."
                            + "Export status: \(exportSession!.status)")
                        activityIdicatorClosure?(false)
                        completion(videoItem)
                    }
                }
            }
        }
    }
}

func deviceForPosition(_ p: AVCaptureDevice.Position) -> AVCaptureDevice? {
    for device in AVCaptureDevice.devices(for: AVMediaType.video) where device.position == p {
        return device
    }
    return nil
}

func thumbnailFromVideoPath(_ path: URL) -> UIImage {
    let asset = AVURLAsset(url: path, options: nil)
    let gen = AVAssetImageGenerator(asset: asset)
    gen.appliesPreferredTrackTransform = true
    let time = CMTimeMakeWithSeconds(0.0, 600)
    var actualTime = CMTimeMake(0, 0)
    let image: CGImage
    do {
        image = try gen.copyCGImage(at: time, actualTime: &actualTime)
        let thumbnail = UIImage(cgImage: image)
        return thumbnail
    } catch { }
    return UIImage()
}

func setFocusPointOnDevice(device: AVCaptureDevice, point: CGPoint) {
    do {
        try device.lockForConfiguration()
        if device.isFocusModeSupported(AVCaptureDevice.FocusMode.autoFocus) {
            device.focusMode = AVCaptureDevice.FocusMode.autoFocus
            device.focusPointOfInterest = point
        }
        if device.isExposureModeSupported(AVCaptureDevice.ExposureMode.continuousAutoExposure) {
            device.exposureMode = AVCaptureDevice.ExposureMode.continuousAutoExposure
            device.exposurePointOfInterest = point
        }
        device.unlockForConfiguration()
    } catch _ {
        return
    }
}

func setFocusPointOnCurrentDevice(_ point: CGPoint) {
    if let device = AVCaptureDevice.default(for: AVMediaType.video) {
        do {
            try device.lockForConfiguration()
            if device.isFocusModeSupported(AVCaptureDevice.FocusMode.autoFocus) == true {
                device.focusMode = AVCaptureDevice.FocusMode.autoFocus
                device.focusPointOfInterest = point
            }
            if device.isExposureModeSupported(AVCaptureDevice.ExposureMode.continuousAutoExposure) == true {
                device.exposureMode = AVCaptureDevice.ExposureMode.continuousAutoExposure
                device.exposurePointOfInterest = point
            }
        } catch _ {
            return
        }
        device.unlockForConfiguration()
    }
}

func toggledPositionForDevice(_ device: AVCaptureDevice) -> AVCaptureDevice.Position {
    return (device.position == .front) ? .back : .front
}

func flippedDeviceInputForInput(_ input: AVCaptureDeviceInput) -> AVCaptureDeviceInput? {
    let p = toggledPositionForDevice(input.device)
    let aDevice = deviceForPosition(p)
    return try? AVCaptureDeviceInput(device: aDevice!)
}
