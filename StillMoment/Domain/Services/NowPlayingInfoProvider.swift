//
//  NowPlayingInfoProvider.swift
//  Still Moment
//
//  Domain Service Protocol - Now Playing Info
//

import Foundation

/// Protocol for managing Now Playing information displayed on lock screen and control center
///
/// This protocol abstracts access to the system's Now Playing info center,
/// allowing for better testability and isolation in unit tests.
protocol NowPlayingInfoProvider: AnyObject {
    /// Gets or sets the currently playing item's metadata
    ///
    /// The dictionary contains media item property keys (e.g., MPMediaItemPropertyTitle)
    /// and their corresponding values for display on lock screen and control center.
    var nowPlayingInfo: [String: Any]? { get set }
}
