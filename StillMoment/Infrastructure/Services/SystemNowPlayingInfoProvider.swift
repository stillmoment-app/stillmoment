//
//  SystemNowPlayingInfoProvider.swift
//  Still Moment
//
//  Infrastructure - System Now Playing Info Provider
//

import Foundation
import MediaPlayer

/// Concrete implementation of NowPlayingInfoProvider using system MPNowPlayingInfoCenter
///
/// This implementation provides access to the actual iOS Now Playing info center
/// for displaying media metadata on lock screen and control center.
final class SystemNowPlayingInfoProvider: NowPlayingInfoProvider {
    var nowPlayingInfo: [String: Any]? {
        get {
            MPNowPlayingInfoCenter.default().nowPlayingInfo
        }
        set {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = newValue
        }
    }
}
