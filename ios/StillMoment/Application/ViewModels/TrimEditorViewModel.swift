//
//  TrimEditorViewModel.swift
//  Still Moment
//
//  Application Layer - Waveform Trim Editor ViewModel (shared-107)
//

import Combine
import Foundation
import OSLog

/// How long the short auto-previews play after committing a mark.
struct TrimPreviewDurations {
    let afterMarkDrag: TimeInterval
    let afterNudge: TimeInterval

    static let standard = TrimPreviewDurations(afterMarkDrag: 2.2, afterNudge: 1.4)
}

/// ViewModel for the full-screen waveform trim editor.
///
/// Owns the immutable `TrimEditorState` and forwards intents (select, move, nudge,
/// whole-file) to it. Loads the waveform lazily through `WaveformProviderProtocol`
/// and drives audio playback through the shared meditation-preview infrastructure
/// (shared-098, `.preview` session).
///
/// Playback model (handoff "touch-robuste Punkt-Bedienung"): the playhead is its own,
/// always-present position. Dragging it (`seek`) pauses playback first and moves only
/// the playhead. Releasing a mark drag or nudging anchors the playhead at the mark and
/// auditions the cut with a short auto-preview; ▶ plays from the playhead, ⏸ pauses and
/// keeps it. Playback pauses automatically at the end point, unless it was anchored at
/// or after the end point (so the end position itself can be auditioned).
@MainActor
final class TrimEditorViewModel: ObservableObject {
    // MARK: Lifecycle

    init(
        meditation: GuidedMeditation,
        audioService: AudioServiceProtocol = AudioService(),
        waveformProvider: WaveformProviderProtocol = WaveformProvider(),
        meditationService: GuidedMeditationServiceProtocol = GuidedMeditationService(),
        previewDurations: TrimPreviewDurations = .standard
    ) {
        self.meditation = meditation
        self.audioService = audioService
        self.waveformProvider = waveformProvider
        self.meditationService = meditationService
        self.previewDurations = previewDurations

        let state = TrimEditorState(meditation: meditation)
        self.editorState = state
        self.playheadTime = state.start

        self.bindPreviewPublishers()
    }

    // MARK: Internal

    @Published private(set) var editorState: TrimEditorState
    @Published private(set) var waveform: MeditationWaveform?
    @Published private(set) var waveformLoadFailed = false

    /// Whether audio is currently playing via ▶ — drives the ▶/⏸ icon.
    @Published private(set) var isPlaying = false
    /// Whether a short auto-preview (after mark drag/nudge) is running. The play
    /// button stays calm (▶) during previews.
    @Published private(set) var isPreviewing = false
    /// Playback position in seconds — always present, seeded with the start point.
    @Published private(set) var playheadTime: TimeInterval

    /// True while the waveform is still being generated/loaded and has not failed.
    var isLoadingWaveform: Bool {
        self.waveform == nil && !self.waveformLoadFailed
    }

    // MARK: - Waveform Loading

    /// Loads the waveform through the provider (cache hit is instant, miss generates).
    /// Runs in a stored task so the view can release it on disappear; the provider's
    /// shared generation keeps running and caches even if we stop awaiting (intended).
    func loadWaveform() {
        guard self.waveform == nil, !self.waveformLoadFailed else {
            return
        }
        self.waveformLoadTask?.cancel()
        self.waveformLoadTask = Task { [weak self] in
            guard let self else {
                return
            }
            do {
                let loaded = try await self.waveformProvider.waveform(for: self.meditation)
                guard !Task.isCancelled else {
                    return
                }
                self.waveform = loaded
            } catch is CancellationError {
                // Editor closed mid-load — nothing to show, no fallback needed.
            } catch {
                Logger.viewModel.error("Failed to load waveform for trim editor", error: error)
                self.waveformLoadFailed = true
            }
        }
    }

    // MARK: - Editor Intents

    /// Selects which point (start/end) is active and moves the playhead onto it.
    /// Keeps playing (seek) when playing, stays paused otherwise.
    func selectPoint(_ point: TrimPoint) {
        self.cancelPreview()
        self.editorState = self.editorState.selecting(point)
        self.anchorPlayhead(at: self.editorState.activeValue)
    }

    /// Moves a point to a time (clamped + min-distance enforced by the domain) and selects it.
    /// Fires continuously during a drag — audio only follows on `markDragEnded()`.
    func movePoint(_ point: TrimPoint, to time: TimeInterval) {
        self.cancelPreview()
        self.editorState = self.editorState.moving(point, to: time)
    }

    /// Mark drag released — anchors the playhead at the mark and auditions the cut.
    func markDragEnded() {
        self.playPreview(from: self.editorState.activeValue, for: self.previewDurations.afterMarkDrag)
    }

    /// Nudges the active point by a delta (±1 s) and auditions the new cut.
    func nudgeActivePoint(by delta: TimeInterval) {
        self.editorState = self.editorState.nudgingActivePoint(by: delta)
        self.playPreview(from: self.editorState.activeValue, for: self.previewDurations.afterNudge)
    }

    /// Resets the selection to the full file and parks the playhead at 0, paused.
    func useWholeFile() {
        self.cancelPreview()
        self.pausePlayback()
        self.editorState = self.editorState.usingWholeFile()
        self.playheadTime = 0
        self.playsToFileEnd = false
    }

    // MARK: - Seeking (playhead lane / upper zone)

    /// Moves the playhead while the finger drags in the playhead zone. Marks stay
    /// untouched; a running playback or preview is paused first so it cannot fight
    /// the finger (handoff: every seek pauses first).
    func seek(to time: TimeInterval) {
        self.cancelPreview()
        self.pausePlayback()
        self.playheadTime = min(max(time, 0), self.editorState.duration)
        self.playsToFileEnd = self.playheadTime >= self.editorState.end
    }

    // MARK: - Playback

    /// ▶ plays from the playhead, ⏸ pauses and keeps the position. Pressing ▶ during
    /// a short preview promotes it to full playback from the preview's anchor.
    func togglePlayback() {
        if self.isPlaying {
            self.pausePlayback()
            return
        }
        self.cancelPreview()
        self.startPlayback()
    }

    /// Stops all audio — called when the editor disappears.
    func viewDisappeared() {
        self.previewTask?.cancel()
        self.previewTask = nil
        self.audioService.stopMeditationPreview()
        self.isPlaying = false
        self.isPreviewing = false
        self.waveformLoadTask?.cancel()
        self.waveformLoadTask = nil
    }

    // MARK: Private

    private let meditation: GuidedMeditation
    private let audioService: AudioServiceProtocol
    private let waveformProvider: WaveformProviderProtocol
    private let meditationService: GuidedMeditationServiceProtocol
    private let previewDurations: TrimPreviewDurations

    private var waveformLoadTask: Task<Void, Never>?
    private var previewTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    /// True when the current playback was anchored at/after the end point — it then runs
    /// to the file end instead of pausing at the end point (auditioning the end position).
    private var playsToFileEnd = false

    private func bindPreviewPublishers() {
        self.audioService.meditationPreviewPositionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] position in
                guard let self, self.isPlaying || self.isPreviewing else {
                    return
                }
                self.handlePlaybackPosition(position)
            }
            .store(in: &self.cancellables)

        self.audioService.meditationPreviewCompletionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self else {
                    return
                }
                self.previewTask?.cancel()
                self.previewTask = nil
                self.isPlaying = false
                self.isPreviewing = false
            }
            .store(in: &self.cancellables)
    }

    private func handlePlaybackPosition(_ position: TimeInterval) {
        if !self.playsToFileEnd, position >= self.editorState.end {
            self.pauseAtEndPoint()
            return
        }
        self.playheadTime = position
    }

    private func startPlayback() {
        let position = self.playheadTime
        guard self.startPreviewPlayback(at: position) else {
            return
        }
        self.isPlaying = true
        self.playsToFileEnd = position >= self.editorState.end
    }

    /// Pause keeps `playheadTime` so ▶ resumes where the user stopped.
    private func pausePlayback() {
        guard self.isPlaying else {
            return
        }
        self.audioService.stopMeditationPreview()
        self.isPlaying = false
    }

    private func pauseAtEndPoint() {
        self.previewTask?.cancel()
        self.previewTask = nil
        self.audioService.stopMeditationPreview()
        self.isPlaying = false
        self.isPreviewing = false
        self.playheadTime = self.editorState.end
    }

    /// Moves the playhead onto a mark. Keeps playing (seek) when playing,
    /// stays paused (playhead jumps only) otherwise.
    private func anchorPlayhead(at position: TimeInterval) {
        self.playheadTime = position
        self.playsToFileEnd = position >= self.editorState.end
        if self.isPlaying {
            self.audioService.seekMeditationPreview(to: position)
        }
    }

    /// Auditions the cut: plays a short preview from `position`, then stops and parks
    /// the playhead back at `position`. Replaces a running playback or preview.
    private func playPreview(from position: TimeInterval, for duration: TimeInterval) {
        self.cancelPreview()
        self.pausePlayback()
        self.playheadTime = position
        self.playsToFileEnd = position >= self.editorState.end
        guard self.startPreviewPlayback(at: position) else {
            return
        }
        self.isPreviewing = true
        self.previewTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            guard !Task.isCancelled else {
                return
            }
            self?.finishPreview(parkingPlayheadAt: position)
        }
    }

    private func finishPreview(parkingPlayheadAt position: TimeInterval) {
        self.audioService.stopMeditationPreview()
        self.isPreviewing = false
        self.playheadTime = position
        self.previewTask = nil
    }

    private func cancelPreview() {
        self.previewTask?.cancel()
        self.previewTask = nil
        guard self.isPreviewing else {
            return
        }
        self.audioService.stopMeditationPreview()
        self.isPreviewing = false
    }

    /// Starts the underlying preview player at the given position. Returns false when the
    /// file could not be resolved (no playback, no state change).
    private func startPreviewPlayback(at position: TimeInterval) -> Bool {
        guard let fileURL = self.meditationService.fileURL(for: self.meditation) else {
            Logger.viewModel.warning(
                "Cannot play — file not found",
                metadata: ["id": self.meditation.id.uuidString]
            )
            return false
        }
        do {
            try self.audioService.playMeditationPreview(fileURL: fileURL)
            self.audioService.seekMeditationPreview(to: position)
            return true
        } catch {
            Logger.viewModel.error("Failed to start trim playback", error: error)
            return false
        }
    }
}
