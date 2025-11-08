#!/bin/bash
# Script to add public modifiers to package files

DOMAIN_DIR="/Users/helmut/devel/stillmoment/Packages/StillMomentDomain/Sources/StillMomentDomain"

# Make all types public in Domain
sed -i '' 's/^enum TimerState/public enum TimerState/g' "$DOMAIN_DIR/TimerState.swift"
sed -i '' 's/^enum MeditationTimerError/public enum MeditationTimerError/g' "$DOMAIN_DIR/MeditationTimer.swift"
sed -i '' 's/^struct MeditationTimer/public struct MeditationTimer/g' "$DOMAIN_DIR/MeditationTimer.swift"
sed -i '' 's/^protocol TimerServiceProtocol/public protocol TimerServiceProtocol/g' "$DOMAIN_DIR/TimerServiceProtocol.swift"
sed -i '' 's/^protocol AudioServiceProtocol/public protocol AudioServiceProtocol/g' "$DOMAIN_DIR/AudioServiceProtocol.swift"
sed -i '' 's/^protocol NotificationServiceProtocol/public protocol NotificationServiceProtocol/g' "$DOMAIN_DIR/NotificationServiceProtocol.swift"

# Make struct properties and methods public
sed -i '' 's/    let durationMinutes:/    public let durationMinutes:/g' "$DOMAIN_DIR/MeditationTimer.swift"
sed -i '' 's/    let remainingSeconds:/    public let remainingSeconds:/g' "$DOMAIN_DIR/MeditationTimer.swift"
sed -i '' 's/    let state:/    public let state:/g' "$DOMAIN_DIR/MeditationTimer.swift"
sed -i '' 's/    init(durationMinutes:/    public init(durationMinutes:/g' "$DOMAIN_DIR/MeditationTimer.swift"
sed -i '' 's/    var totalSeconds:/    public var totalSeconds:/g' "$DOMAIN_DIR/MeditationTimer.swift"
sed -i '' 's/    var progress:/    public var progress:/g' "$DOMAIN_DIR/MeditationTimer.swift"
sed -i '' 's/    var isCompleted:/    public var isCompleted:/g' "$DOMAIN_DIR/MeditationTimer.swift"
sed -i '' 's/    func tick()/    public func tick()/g' "$DOMAIN_DIR/MeditationTimer.swift"
sed -i '' 's/    func withState/    public func withState/g' "$DOMAIN_DIR/MeditationTimer.swift"
sed -i '' 's/    func reset()/    public func reset()/g' "$DOMAIN_DIR/MeditationTimer.swift"
sed -i '' 's/    var errorDescription:/    public var errorDescription:/g' "$DOMAIN_DIR/MeditationTimer.swift"

echo "✅ Domain types made public"
