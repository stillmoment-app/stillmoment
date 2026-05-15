//
//  BreathDial.swift
//  Still Moment
//
//  Presentation Layer - Atemkreis-Picker (shared-086).
//
//  Ring + Aktiv-Bogen + Bead. Wert wird ueber `value` (Binding) gesteuert;
//  Werte werden auf [1, 60] geklemmt. VoiceOver-Slider-Adjust bleibt als
//  alleinige nicht-gestische Eingabe. Ring-Werte werden aus `RingMetrics`
//  geteilt mit `BreathingCircleView` — damit Idle und Running dieselbe
//  Ring-Sprache sprechen (ios-045).
//

import SwiftUI

struct BreathDial: View {
    @Binding var value: Int
    let diameter: CGFloat

    @Environment(\.themeColors)
    private var theme

    @State private var isDragging = false

    private static let dragBeadScale: CGFloat = 1.55
    private static let dragAnimation = Animation.easeOut(duration: 0.15)
    private static let valueAnimation = Animation.easeOut(duration: 0.15)
    private static let hitAreaInset: CGFloat = -24

    private var ringWidth: CGFloat {
        RingMetrics.lineWidth
    }

    private var ringRadius: CGFloat {
        (self.diameter - self.ringWidth) / 2
    }

    private var beadDiameter: CGFloat {
        self.isDragging
            ? RingMetrics.beadDiameter * Self.dragBeadScale
            : RingMetrics.beadDiameter
    }

    var body: some View {
        self.dialContent
            .frame(width: self.diameter, height: self.diameter)
            .accessibilityElement(children: .contain)
    }

    // MARK: - Dial-Inhalt (Ring + Bogen + Bead + Mittelschrift)

    private var dialContent: some View {
        ZStack {
            self.trackRing
            self.activeArc
            self.bead
            self.centerText
        }
        .contentShape(Circle().inset(by: Self.hitAreaInset))
        .gesture(self.dragGesture)
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier("timer.dial")
        .accessibilityLabel(Text(NSLocalizedString("accessibility.dial.label", comment: "")))
        .accessibilityValue(Text(self.accessibilityValueString))
        .accessibilityHint(Text(NSLocalizedString("accessibility.dial.hint", comment: "")))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                self.adjustValue(by: 1)
            case .decrement:
                self.adjustValue(by: -1)
            @unknown default:
                break
            }
        }
    }

    private var trackRing: some View {
        Circle()
            .stroke(self.theme.ringTrack, lineWidth: self.ringWidth)
            .frame(width: self.diameter - self.ringWidth, height: self.diameter - self.ringWidth)
    }

    private var activeArc: some View {
        Circle()
            .trim(from: 0, to: BreathDialGeometry.arcProgress(self.value))
            .stroke(
                self.theme.dialActiveArc,
                style: StrokeStyle(lineWidth: self.ringWidth, lineCap: .round)
            )
            .rotationEffect(.degrees(-90))
            .frame(width: self.diameter - self.ringWidth, height: self.diameter - self.ringWidth)
            .animation(Self.valueAnimation, value: self.value)
    }

    private var bead: some View {
        let progress = Double(self.value) / Double(BreathDialGeometry.maxMinutes)
        let angleRad = progress * 2 * .pi - .pi / 2
        let offsetX = cos(angleRad) * self.ringRadius
        let offsetY = sin(angleRad) * self.ringRadius

        return Circle()
            .fill(self.theme.interactive)
            .frame(width: self.beadDiameter, height: self.beadDiameter)
            .shadow(color: self.theme.interactive.opacity(0.6), radius: RingMetrics.beadShadowRadius)
            .offset(x: offsetX, y: offsetY)
            .animation(Self.valueAnimation, value: self.value)
            .animation(Self.dragAnimation, value: self.isDragging)
            .accessibilityHidden(true)
    }

    private var centerText: some View {
        VStack(spacing: 2) {
            Text("\(self.value)")
                .themeFont(.dialValue, size: self.dialValueSize)
                .monospacedDigit()
                .accessibilityIdentifier("timer.dial.value")

            Text(NSLocalizedString("timer.dial.unit", comment: ""))
                .themeFont(.dialUnit)
        }
        .allowsHitTesting(false)
    }

    /// Big-Number skaliert proportional zur Dial-Groesse — 62 px bei D=180,
    /// 76 px bei D=220.
    private var dialValueSize: CGFloat {
        let minSize: CGFloat = 62
        let maxSize: CGFloat = 76
        let minDiameter: CGFloat = 180
        let maxDiameter: CGFloat = 220
        let clampedDiameter = min(max(self.diameter, minDiameter), maxDiameter)
        let ratio = (clampedDiameter - minDiameter) / (maxDiameter - minDiameter)
        return minSize + ratio * (maxSize - minSize)
    }

    // MARK: - Gesten

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { gesture in
                let center = CGPoint(x: self.diameter / 2, y: self.diameter / 2)
                let dx = gesture.location.x - center.x
                let dy = gesture.location.y - center.y
                guard sqrt(dx * dx + dy * dy) > self.ringRadius * 0.5
                else { return }
                if !self.isDragging {
                    self.isDragging = true
                }
                let newValue = BreathDialGeometry.valueFromPoint(
                    gesture.location,
                    center: center
                )
                if newValue != self.value {
                    self.value = newValue
                }
            }
            .onEnded { _ in
                self.isDragging = false
            }
    }

    // MARK: - Adjust

    private func adjustValue(by delta: Int) {
        let clamped = BreathDialGeometry.clampValue(self.value + delta)
        if clamped != self.value {
            self.value = clamped
        }
    }

    // MARK: - Accessibility-Helfer

    private var accessibilityValueString: String {
        String(format: NSLocalizedString("accessibility.dial.value", comment: ""), self.value)
    }
}

// MARK: - Previews

#if DEBUG
@available(iOS 17.0, *)
#Preview("BreathDial - 220") {
    StatefulPreview(initialValue: 18) { binding in
        BreathDial(value: binding, diameter: 220)
    }
    .padding()
}

@available(iOS 17.0, *)
#Preview("BreathDial - 180 (compact)") {
    StatefulPreview(initialValue: 30) { binding in
        BreathDial(value: binding, diameter: 180)
    }
    .padding()
}

private struct StatefulPreview<Content: View>: View {
    @State var value: Int

    let content: (Binding<Int>) -> Content

    init(initialValue: Int, @ViewBuilder content: @escaping (Binding<Int>) -> Content) {
        self._value = State(initialValue: initialValue)
        self.content = content
    }

    var body: some View {
        self.content(self.$value)
    }
}
#endif
