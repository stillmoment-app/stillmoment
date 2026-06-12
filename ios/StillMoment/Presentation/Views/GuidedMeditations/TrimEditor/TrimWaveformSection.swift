//
//  TrimWaveformSection.swift
//  Still Moment
//
//  Presentation Layer — playhead lane + waveform + marks with a single geometric
//  drag gesture, plus axis labels (shared-107).
//

import SwiftUI

/// The interactive trim track: the sage playhead lane on top, the waveform with the
/// two copper trim marks below, and the axis labels underneath.
///
/// All grips are purely visual — one single drag gesture covers lane + waveform and
/// resolves geometrically (via `TrimHitTesting`) what the finger acts on: the lane and
/// the upper 45 % of the waveform move the playhead, the lower zone moves a mark (in
/// clusters the active mark always wins). This removes any competition between
/// overlapping hit areas on the narrow track (handoff "touch-robuste Punkt-Bedienung").
struct TrimWaveformSection: View {
    // MARK: Internal

    @ObservedObject var viewModel: TrimEditorViewModel

    var body: some View {
        VStack(spacing: 12) {
            self.track
            self.axisLabels
        }
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

    private var track: some View {
        VStack(spacing: 0) {
            TrimPlayheadLane(
                playheadTime: self.viewModel.playheadTime,
                duration: self.state.duration,
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
    }

    private var waveform: some View {
        TrimWaveformView(
            waveform: self.viewModel.waveform,
            isLoading: self.viewModel.isLoadingWaveform,
            loadFailed: self.viewModel.waveformLoadFailed,
            duration: self.state.duration,
            start: self.state.start,
            end: self.state.end,
            playheadTime: self.viewModel.playheadTime
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
                self.mark(for: .start, labelKey: "trim_editor.a11y.startHandle")
                self.mark(for: .end, labelKey: "trim_editor.a11y.endHandle")
            }
            .allowsHitTesting(false)
        }
    }

    private func mark(for point: TrimPoint, labelKey: String) -> some View {
        TrimMarkHandle(
            time: point == .start ? self.state.start : self.state.end,
            isActive: self.state.activePoint == point,
            isDragging: self.dragSession?.target == .mark(point),
            trackWidth: self.trackWidth,
            duration: self.state.duration,
            onNudge: { delta in
                self.viewModel.selectPoint(point)
                self.viewModel.nudgeActivePoint(by: delta)
            },
            accessibilityLabelText: NSLocalizedString(labelKey, comment: "Trim mark")
        )
        .zIndex(self.state.activePoint == point ? 1 : 0)
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
    /// and at which relative offset was it grabbed?
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
        TrimGeometry.x(for: time, duration: self.state.duration, width: self.trackWidth)
    }

    private func applyDrag(session: TrimDragSession, locationX: CGFloat) {
        let time = TrimGeometry.time(
            forX: locationX + session.offset,
            duration: self.state.duration,
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

    private var axisLabels: some View {
        HStack {
            Text(EditSheetState.formatTime(0))
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
            Text(EditSheetState.formatTime(self.state.duration))
                .textStyle(.micro, monospacedDigits: true, color: \.textSecondary)
        }
    }
}
