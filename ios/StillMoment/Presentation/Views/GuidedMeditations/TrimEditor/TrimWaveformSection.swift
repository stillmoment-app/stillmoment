//
//  TrimWaveformSection.swift
//  Still Moment
//
//  Presentation Layer — playhead lane + waveform + marks with a single geometric
//  drag gesture, plus minimap, edge chips, and axis labels (shared-107/108).
//

import SwiftUI

/// The interactive trim track: the sage playhead lane on top, the waveform with the
/// two copper trim marks below, and the axis labels underneath. While zoomed, a
/// whole-file minimap appears above the track.
///
/// All grips are purely visual — one single drag gesture covers lane + waveform and
/// resolves geometrically (via `TrimHitTesting`) what the finger acts on: the lane and
/// the upper 45 % of the waveform move the playhead, the lower zone moves a mark (in
/// clusters the active mark always wins). This removes any competition between
/// overlapping hit areas on the narrow track (handoff "touch-robuste Punkt-Bedienung").
///
/// Every time↔x mapping goes through the ViewModel's visible window (shared-108) —
/// in the overview that window is the whole file. Marks outside the window render as
/// edge chips at the nearer track edge; tapping one selects and frames that mark.
struct TrimWaveformSection: View {
    // MARK: Internal

    @ObservedObject var viewModel: TrimEditorViewModel

    var body: some View {
        VStack(spacing: 12) {
            if self.viewModel.isZoomed {
                self.minimap
            }
            self.track
            self.axisLabels
        }
        .animation(.easeOut(duration: 0.18), value: self.viewModel.isZoomed)
    }

    // MARK: Private

    @Environment(\.themeColors)
    private var theme

    @State private var trackWidth: CGFloat = 0
    /// Resolved at finger-down, fixed for the whole drag; nil while idle.
    @State private var dragSession: TrimDragSession?

    private var state: TrimEditorState {
        self.viewModel.editorState
    }

    /// Visible time window — all track mappings go through it.
    private var window: ClosedRange<TimeInterval> {
        self.viewModel.window
    }

    private var minimap: some View {
        TrimMinimapView(
            start: self.state.start,
            end: self.state.end,
            playheadTime: self.viewModel.playheadTime,
            window: self.window,
            duration: self.state.duration
        ) { self.viewModel.panWindow(toCenter: $0) }
            .transition(.opacity)
    }

    private var track: some View {
        VStack(spacing: 0) {
            TrimPlayheadLane(
                playheadTime: self.viewModel.playheadTime,
                window: self.window,
                trackWidth: self.trackWidth,
                isDragging: self.dragSession?.target == .playhead
            ) { self.viewModel.seek(to: self.viewModel.playheadTime + $0) }
            self.waveform
        }
        .background(
            GeometryReader { proxy in
                Color.clear.onAppear { self.trackWidth = proxy.size.width }
                    .onChange(of: proxy.size.width) { self.trackWidth = $0 }
            }
        )
        .contentShape(Rectangle())
        // High priority so dragging on the track wins over the sheet's interactive
        // swipe-to-dismiss.
        .highPriorityGesture(self.trackGesture)
        // Chips sit on top of the gesture in hit-test order, so their taps win.
        .overlay(alignment: .leading) { self.edgeChips(atLeadingEdge: true) }
        .overlay(alignment: .trailing) { self.edgeChips(atLeadingEdge: false) }
    }

    private var waveform: some View {
        TrimWaveformView(
            waveform: self.viewModel.waveform,
            isLoading: self.viewModel.isLoadingWaveform,
            loadFailed: self.viewModel.waveformLoadFailed,
            duration: self.state.duration,
            start: self.state.start,
            end: self.state.end,
            playheadTime: self.viewModel.playheadTime,
            window: self.window
        )
        .overlay(self.zoneHint)
        .overlay(alignment: .leading) {
            self.marks
        }
    }

    /// Subtle visual hint of the touch split: sage tint over the playhead zone and a
    /// hairline at the 45 % boundary.
    private var zoneHint: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [self.theme.playheadAccent.opacity(0.10), self.theme.playheadAccent.opacity(0)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: TrimWaveformView.height * TrimHitTesting.verticalSplit)
            Rectangle()
                .fill(self.theme.divider)
                .frame(height: 1)
            Spacer(minLength: 0)
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder private var marks: some View {
        if self.trackWidth > 0 {
            ZStack(alignment: .leading) {
                if TrimGeometry.isTime(self.state.start, inWindow: self.window) {
                    self.mark(for: .start, labelKey: "trim_editor.a11y.startHandle")
                }
                if TrimGeometry.isTime(self.state.end, inWindow: self.window) {
                    self.mark(for: .end, labelKey: "trim_editor.a11y.endHandle")
                }
            }
            .allowsHitTesting(false)
        }
    }

    private func mark(for point: TrimPoint, labelKey: String) -> some View {
        TrimMarkHandle(
            time: self.markTime(for: point),
            isActive: self.state.activePoint == point,
            isDragging: self.dragSession?.target == .mark(point),
            trackWidth: self.trackWidth,
            window: self.window,
            onNudge: { delta in
                self.viewModel.selectPoint(point)
                self.viewModel.nudgeActivePoint(by: delta)
            },
            accessibilityLabelText: NSLocalizedString(labelKey, comment: "Trim mark")
        )
        .zIndex(self.state.activePoint == point ? 1 : 0)
    }

    // MARK: - Edge chips (off-window marks)

    private func edgeChips(atLeadingEdge leading: Bool) -> some View {
        VStack(spacing: 6) {
            if self.showsChip(for: .start, atLeadingEdge: leading) {
                self.edgeChip(for: .start)
            }
            if self.showsChip(for: .end, atLeadingEdge: leading) {
                self.edgeChip(for: .end)
            }
        }
        .padding(.horizontal, 4)
        // Vertically centered on the waveform zone, not the whole track.
        .offset(y: TrimPlayheadLane.height / 2)
    }

    private func showsChip(for point: TrimPoint, atLeadingEdge leading: Bool) -> Bool {
        let time = self.markTime(for: point)
        guard !TrimGeometry.isTime(time, inWindow: self.window) else {
            return false
        }
        return (time < self.window.lowerBound) == leading
    }

    private func edgeChip(for point: TrimPoint) -> some View {
        TrimEdgeChip(
            point: point,
            time: self.markTime(for: point),
            pointsLeading: self.markTime(for: point) < self.window.lowerBound
        ) { self.viewModel.focusPoint(point) }
    }

    private func markTime(for point: TrimPoint) -> TimeInterval {
        point == .start ? self.state.start : self.state.end
    }

    // MARK: - Gesture

    private var trackGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard self.trackWidth > 0 else {
                    return
                }
                let session = self.dragSession ?? self.beginSession(at: value.startLocation)
                self.dragSession = session
                self.applyDrag(session: session, locationX: value.location.x)
            }
            .onEnded { _ in
                if case .mark = self.dragSession?.target {
                    self.viewModel.markDragEnded()
                }
                self.dragSession = nil
            }
    }

    /// Resolves the finger-down geometrically: which element does this drag act on,
    /// and at which relative offset was it grabbed? Element positions are unclamped
    /// window coordinates — off-window marks land outside the grab radius by design.
    private func beginSession(at location: CGPoint) -> TrimDragSession {
        TrimHitTesting.beginDrag(
            at: location,
            in: TrimTrackGeometry(
                laneHeight: TrimPlayheadLane.height,
                waveformHeight: TrimWaveformView.height,
                headX: self.trackX(for: self.viewModel.playheadTime),
                startX: self.trackX(for: self.state.start),
                endX: self.trackX(for: self.state.end)
            ),
            activePoint: self.state.activePoint
        )
    }

    private func trackX(for time: TimeInterval) -> CGFloat {
        TrimGeometry.unclampedX(for: time, window: self.window, width: self.trackWidth)
    }

    private func applyDrag(session: TrimDragSession, locationX: CGFloat) {
        // Clamped into the window — a drag to the track edge stops at the window bounds.
        let time = TrimGeometry.time(
            forX: locationX + session.offset,
            window: self.window,
            width: self.trackWidth
        )
        switch session.target {
        case .playhead:
            self.viewModel.seek(to: time)
        case let .mark(point):
            self.viewModel.movePoint(point, to: time)
        }
    }

    // MARK: - Axis

    /// Shows the window bounds (not 0 … duration) — in the overview both are the same.
    private var axisLabels: some View {
        HStack {
            Text(EditSheetState.formatTime(self.window.lowerBound))
                .textStyle(.micro, monospacedDigits: true, color: \.textSecondary)
            Spacer()
            Text(EditSheetState.formatTime(self.viewModel.playheadTime))
                .textStyle(.micro, monospacedDigits: true)
                .foregroundColor(
                    self.viewModel.isPlaying || self.viewModel.isPreviewing
                        ? self.theme.playheadAccent
                        : self.theme.textSecondary
                )
            Spacer()
            Text(EditSheetState.formatTime(self.window.upperBound))
                .textStyle(.micro, monospacedDigits: true, color: \.textSecondary)
        }
    }
}
