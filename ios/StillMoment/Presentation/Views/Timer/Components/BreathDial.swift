//
//  BreathDial.swift
//  Still Moment
//
//  Presentation Layer - Atemkreis-Picker (shared-086).
//
//  Ersatz fuer den Wheel-Picker. Ring + Aktiv-Bogen + Drag-Tropfen plus zwei
//  radial platzierte +/- Buttons mit Long-Press-Beschleunigung. Wert wird
//  ueber `value` (Binding) gesteuert; Werte werden auf [1, 60] geklemmt.
//

import SwiftUI

struct BreathDial: View {
    @Binding var value: Int
    let diameter: CGFloat

    @Environment(\.themeColors)
    private var theme
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @State private var haloAnimating = false

    private static let buttonSize: CGFloat = 44
    private static let dropletCoreRadius: CGFloat = 6.5
    private static let dropletOuterRadius: CGFloat = 14
    private static let dropletStrokeWidth: CGFloat = 1.8
    private static let haloMaxRadius: CGFloat = 26
    private static let haloMinRadius: CGFloat = 18
    private static let haloStaticRadius: CGFloat = 22

    private var ringWidth: CGFloat {
        max(13, self.diameter * 16 / 220)
    }

    private var ringRadius: CGFloat {
        (self.diameter - self.ringWidth) / 2
    }

    /// Radius vom Dial-Mittelpunkt zum Mittelpunkt eines +/- Buttons.
    /// 168 px bei 220 Dial-Durchmesser (JS-Referenz). Skaliert proportional.
    private var buttonRadialDistance: CGFloat {
        self.diameter * 168 / 220
    }

    private var buttonOffsetSize: CGSize {
        BreathDialGeometry.buttonOffset(direction: .plus, distance: self.buttonRadialDistance)
    }

    private var totalWidth: CGFloat {
        max(self.diameter, 2 * self.buttonOffsetSize.width + Self.buttonSize)
    }

    private var totalHeight: CGFloat {
        self.diameter / 2 + self.buttonOffsetSize.height + Self.buttonSize / 2
    }

    private var canDecrement: Bool {
        self.value > BreathDialGeometry.minMinutes
    }

    private var canIncrement: Bool {
        self.value < BreathDialGeometry.maxMinutes
    }

    var body: some View {
        ZStack {
            self.dialContent
                .frame(width: self.diameter, height: self.diameter)
                .position(x: self.totalWidth / 2, y: self.diameter / 2)

            DialAdjustButton(
                direction: .minus,
                isDisabled: !self.canDecrement,
                size: Self.buttonSize
            ) {
                self.adjustValue(by: -1)
            }
            .position(
                x: self.totalWidth / 2 - self.buttonOffsetSize.width,
                y: self.diameter / 2 + self.buttonOffsetSize.height
            )

            DialAdjustButton(
                direction: .plus,
                isDisabled: !self.canIncrement,
                size: Self.buttonSize
            ) {
                self.adjustValue(by: 1)
            }
            .position(
                x: self.totalWidth / 2 + self.buttonOffsetSize.width,
                y: self.diameter / 2 + self.buttonOffsetSize.height
            )
        }
        .frame(width: self.totalWidth, height: self.totalHeight)
        .accessibilityElement(children: .contain)
    }

    // MARK: - Dial-Inhalt (Ring + Bogen + Tropfen + Mittelschrift)

    private var dialContent: some View {
        ZStack {
            self.trackRing
            self.activeArc
            self.droplet
            self.centerText
        }
        .contentShape(Circle())
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
            .animation(.easeOut(duration: 0.15), value: self.value)
    }

    private var droplet: some View {
        let progress = Double(self.value) / Double(BreathDialGeometry.maxMinutes)
        let angleRad = progress * 2 * .pi - .pi / 2
        let offsetX = cos(angleRad) * self.ringRadius
        let offsetY = sin(angleRad) * self.ringRadius

        return ZStack {
            self.dropletHalo

            // Aussenring (Tropfen-Body) — verdeckt den Bogen darunter
            Circle()
                .fill(self.theme.backgroundPrimary)
                .frame(width: Self.dropletOuterRadius * 2, height: Self.dropletOuterRadius * 2)
                .overlay(
                    Circle()
                        .stroke(self.theme.dialDropletCore, lineWidth: Self.dropletStrokeWidth)
                )

            // Tropfen-Kern
            Circle()
                .fill(self.theme.dialDropletCore)
                .frame(width: Self.dropletCoreRadius * 2, height: Self.dropletCoreRadius * 2)
        }
        .offset(x: offsetX, y: offsetY)
        .animation(.easeOut(duration: 0.15), value: self.value)
        .accessibilityHidden(true)
    }

    @ViewBuilder private var dropletHalo: some View {
        if self.reduceMotion {
            // Statischer Halo — mittlere Groesse, mittlere Opazitaet
            Circle()
                .fill(self.theme.dialDropletHalo)
                .frame(width: Self.haloStaticRadius * 2, height: Self.haloStaticRadius * 2)
        } else {
            Circle()
                .fill(self.theme.dialDropletHalo)
                .frame(
                    width: (self.haloAnimating ? Self.haloMaxRadius : Self.haloMinRadius) * 2,
                    height: (self.haloAnimating ? Self.haloMaxRadius : Self.haloMinRadius) * 2
                )
                .opacity(self.haloAnimating ? 0.05 : 0.35)
                .animation(
                    .easeInOut(duration: 1.3).repeatForever(autoreverses: true),
                    value: self.haloAnimating
                )
                .onAppear { self.haloAnimating = true }
        }
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
                let newValue = BreathDialGeometry.valueFromPoint(
                    gesture.location,
                    center: center
                )
                if newValue != self.value {
                    self.value = newValue
                }
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

// MARK: - Adjust-Button (Touch-down + Long-Press-Beschleunigung)

private struct DialAdjustButton: View {
    let direction: BreathDialGeometry.ButtonDirection
    let isDisabled: Bool
    let size: CGFloat
    let onPress: () -> Void

    @Environment(\.themeColors)
    private var theme
    @State private var holder = AcceleratorHolder()

    var body: some View {
        ZStack {
            Circle()
                .fill(self.theme.dialButtonBackground)
                .overlay(
                    Circle().stroke(self.theme.dialButtonBorder, lineWidth: 1)
                )
            Text(self.direction == .plus ? "+" : "−")
                .font(.system(size: 22, weight: .light, design: .rounded))
                .foregroundColor(self.theme.textPrimary)
        }
        .frame(width: self.size, height: self.size)
        .opacity(self.isDisabled ? 0.3 : 1.0)
        .contentShape(Circle())
        .gesture(self.pressGesture)
        .disabled(self.isDisabled)
        .accessibilityIdentifier(self.identifier)
        .accessibilityLabel(Text(NSLocalizedString(self.accessibilityLabelKey, comment: "")))
        .accessibilityAddTraits(.isButton)
        .onChange(of: self.isDisabled) { newValue in
            if newValue {
                self.handlePressEnd()
            }
        }
    }

    private var identifier: String {
        self.direction == .plus ? "timer.dial.plus" : "timer.dial.minus"
    }

    private var accessibilityLabelKey: String {
        self.direction == .plus ? "accessibility.dial.increment" : "accessibility.dial.decrement"
    }

    private var pressGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in self.handlePressBegin() }
            .onEnded { _ in self.handlePressEnd() }
    }

    private func handlePressBegin() {
        guard self.holder.accelerator == nil
        else { return }
        guard !self.isDisabled
        else { return }
        let action = self.onPress
        let acc = LongPressAccelerator(action: action)
        self.holder.accelerator = acc
        acc.start()
    }

    private func handlePressEnd() {
        self.holder.accelerator?.stop()
        self.holder.accelerator = nil
    }
}

/// Reference-type-Halter, damit der Accelerator zwischen Press-Phasen ueberlebt
/// und `.onChanged`-Updates nicht jedes Mal neue Instanzen anlegen.
@MainActor
private final class AcceleratorHolder {
    var accelerator: LongPressAccelerator?
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
