//
//  AVMediaType Shim.swift
//  Privy
//
//  Created by Michael MacCallum on 1/17/16.
//  Copyright © 2016 Privy. All rights reserved.
//


import AVFoundation

/**
 *  Exists only to maintain Swifty use of AVMediaType and some of its associated APIs
 *  until AVFoundation comes up in Apple's Cocoa Touch audit list.
 */
enum AVMediaType: String {
    case Video, Audio, Text, ClosedCaption, Subtitle, Timecode, Metadata, Muxed
    
    var rawValue: String {
        switch self {
        case .Video:
            return AVMediaTypeVideo
        case .Audio:
            return AVMediaTypeAudio
        case .Text:
            return AVMediaTypeText
        case .ClosedCaption:
            return AVMediaTypeClosedCaption
        case .Subtitle:
            return AVMediaTypeSubtitle
        case .Timecode:
            return AVMediaTypeTimecode
        case .Metadata:
            return AVMediaTypeMetadata
        case .Muxed:
            return AVMediaTypeMuxed
        }
    }
    
    init?(rawValue: String) {
        switch rawValue {
        case AVMediaTypeVideo:
            self = .Video
        case AVMediaTypeAudio:
            self = .Audio
        case AVMediaTypeText:
            self = .Text
        case AVMediaTypeClosedCaption:
            self = .ClosedCaption
        case AVMediaTypeSubtitle:
            self = .Subtitle
        case AVMediaTypeTimecode:
            self = .Timecode
        case AVMediaTypeMetadata:
            self = .Metadata
        case AVMediaTypeMuxed:
            self = .Muxed
        default:
            return nil
        }
    }
}

extension AVCaptureDevice {
    class func authorizationStatusForMediaType(mediaType: AVMediaType) -> AVAuthorizationStatus {
        return authorizationStatusForMediaType(mediaType.rawValue)
    }
    
    class func requestAccessForMediaType(mediaType: AVMediaType, completionHandler handler: ((Bool) -> Void)!) {
        requestAccessForMediaType(mediaType.rawValue, completionHandler: handler)
    }
    
    class func devicesWithMediaType(mediaType: AVMediaType) -> [AnyObject]! {
        return devicesWithMediaType(mediaType.rawValue)
    }

    func hasMediaType(mediaType: AVMediaType) -> Bool {
        return hasMediaType(mediaType.rawValue)
    }

    class func defaultDeviceWithMediaType(mediaType: AVMediaType) -> AVCaptureDevice! {
        return defaultDeviceWithMediaType(mediaType.rawValue)
    }
}
