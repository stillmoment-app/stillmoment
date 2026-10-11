//
//  TestLaunchArguments.swift
//  Still Moment
//
//  Launch arguments the app understands in UI tests.
//

/// Launch arguments the app understands in UI tests.
enum TestLaunchArguments {
    /// Starts the app on an emptied storage of its own instead of the meditations and
    /// settings saved on the simulator (ios-056, Debug builds only).
    /// Must match `StorageLocation.useTestStorageArgument` in the app.
    static let useTestStorage = "-UseTestStorage"
}
