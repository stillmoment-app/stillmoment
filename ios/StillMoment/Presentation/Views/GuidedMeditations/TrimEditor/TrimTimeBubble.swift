//
//  TrimTimeBubble.swift
//  Still Moment
//
//  Presentation Layer — time bubble shown above a dragged trim element (shared-107).
//

import SwiftUI

/// Small time pill floating above a dragged playhead grabber or trim mark.
///
/// Centered over the element where possible; near the track edges it measures its own
/// width and shifts inward so it never leaves the screen. Purely visual — never
/// participates in hit testing.
struct TrimTimeBubble: View {
    // MARK: Internal

    let time: TimeInterval
    /// X-position of the anchoring element in track coordinates.
    let anchorX: CGFloat
    let trackWidth: CGFloat
    let background: Color
    let textColor: Color

    var body: some View {
        Text(EditSheetState.formatTime(self.time))
            .textStyle(.body, monospacedDigits: true)
            .foregroundColor(self.textColor)
            .padding(.horizontal, 9)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(self.background)
            )
            // The anchoring frame can be narrower than the text — without fixedSize
            // the time would wrap onto two lines inside it.
            .fixedSize()
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .onAppear { self.bubbleWidth = proxy.size.width }
                        .onChange(of: proxy.size.width) { newWidth in
                            self.bubbleWidth = newWidth
                        }
                }
            )
            .offset(x: self.edgeShift)
            .allowsHitTesting(false)
    }

    // MARK: Private

    /// Measured bubble width; drives the edge clamping in `edgeShift`.
    @State private var bubbleWidth: CGFloat = 0

    /// Horizontal correction keeping the bubble inside the track bounds.
    private var edgeShift: CGFloat {
        let half = self.bubbleWidth / 2
        let minShift = half - self.anchorX
        let maxShift = self.trackWidth - self.anchorX - half
        guard minShift <= maxShift else {
            return 0
        }
        return min(max(0, minShift), maxShift)
    }
}
