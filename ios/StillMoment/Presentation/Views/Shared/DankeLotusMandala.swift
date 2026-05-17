//
//  DankeLotusMandala.swift
//  Still Moment
//
//  Presentation Layer — statisches Doppel-Lotus-Mandala fuer den Danke-Screen
//  (shared-097). 16 Petals (8 outer + 8 inner um 22.5° versetzt) plus zentraler
//  Punkt und Outline-Ring. Akzent-Farbe aus `theme.interactive`, kein Pulsieren,
//  keine Animation — die Sitzung ist vorbei, der Screen ist ruhig.
//

import SwiftUI

// MARK: - Geometrie

/// Pure Geometrie-Werte des Mandalas. In den Tests verifiziert: 8 Outer-Petals
/// bei 0°/45°/.../315°, 8 Inner-Petals um 22.5° versetzt, Opacities laut Handoff.
enum LotusMandalaGeometry {
    static let outerPetalAngles: [Double] = Array(stride(from: 0.0, to: 360.0, by: 45.0))
    static let innerPetalAngles: [Double] = Array(stride(from: 22.5, to: 360.0, by: 45.0))

    static let innerPetalOpacity: Double = 0.6
    static let centerRingOpacity: Double = 0.5

    /// Logisches Koordinatensystem aus dem Handoff (170 × 170 ViewBox, Center 85, 85).
    static let viewBoxSize: CGFloat = 170
    static let strokeWidth: CGFloat = 1.3
}

// MARK: - Petal Shape

/// Petal-Form als kubische Bézier-Schleife — eine Form, in zwei Groessen
/// (outer / inner). Lokal-Koordinaten relativ zu (0, 0) als Petal-Basis.
struct LotusPetalShape: Shape {
    static let outer = LotusPetalShape(
        tipY: -72,
        bellyX: 10,
        bellyHigh: -54,
        bellyLow: -32,
        baseY: -22
    )

    static let inner = LotusPetalShape(
        tipY: -42,
        bellyX: 7,
        bellyHigh: -32,
        bellyLow: -18,
        baseY: -10
    )

    let tipY: CGFloat
    let bellyX: CGFloat
    let bellyHigh: CGFloat
    let bellyLow: CGFloat
    let baseY: CGFloat

    func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / LotusMandalaGeometry.viewBoxSize
        let centerX = rect.midX
        let centerY = rect.midY

        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: centerX + x * scale, y: centerY + y * scale)
        }

        var path = Path()
        path.move(to: point(0, self.tipY))
        path.addCurve(
            to: point(0, self.baseY),
            control1: point(-self.bellyX, self.bellyHigh),
            control2: point(-self.bellyX, self.bellyLow)
        )
        path.addCurve(
            to: point(0, self.tipY),
            control1: point(self.bellyX, self.bellyLow),
            control2: point(self.bellyX, self.bellyHigh)
        )
        path.closeSubpath()
        return path
    }
}

// MARK: - Mandala View

/// Statisches Doppel-Lotus-Mandala — keine Animation, keine Lifecycle.
/// Skaliert mit dem zugewiesenen Frame (siehe `LotusMandalaGeometry.viewBoxSize`).
struct DankeLotusMandala: View {
    @Environment(\.themeColors)
    private var theme

    var body: some View {
        ZStack {
            ForEach(LotusMandalaGeometry.outerPetalAngles, id: \.self) { angle in
                LotusPetalShape.outer
                    .stroke(
                        self.theme.interactive,
                        style: StrokeStyle(
                            lineWidth: LotusMandalaGeometry.strokeWidth,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    .rotationEffect(.degrees(angle))
            }

            ForEach(LotusMandalaGeometry.innerPetalAngles, id: \.self) { angle in
                LotusPetalShape.inner
                    .stroke(
                        self.theme.interactive,
                        style: StrokeStyle(
                            lineWidth: LotusMandalaGeometry.strokeWidth,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    .rotationEffect(.degrees(angle))
                    .opacity(LotusMandalaGeometry.innerPetalOpacity)
            }

            self.centerMarks
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }

    private var centerMarks: some View {
        GeometryReader { geometry in
            let scale = min(geometry.size.width, geometry.size.height) / LotusMandalaGeometry.viewBoxSize
            let dotDiameter = 10 * scale
            let ringDiameter = 18 * scale
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)

            ZStack {
                Circle()
                    .fill(self.theme.interactive)
                    .frame(width: dotDiameter, height: dotDiameter)
                    .position(center)

                Circle()
                    .strokeBorder(
                        self.theme.interactive.opacity(LotusMandalaGeometry.centerRingOpacity),
                        lineWidth: LotusMandalaGeometry.strokeWidth
                    )
                    .frame(width: ringDiameter, height: ringDiameter)
                    .position(center)
            }
        }
    }
}

// MARK: - Previews

@available(iOS 17.0, *)
#Preview("Dark") {
    ZStack {
        Color(red: 0.10, green: 0.06, blue: 0.05).ignoresSafeArea()
        DankeLotusMandala()
            .frame(width: 160, height: 160)
            .environment(\.themeColors, .dark)
    }
}

@available(iOS 17.0, *)
#Preview("Light") {
    ZStack {
        Color(red: 0.98, green: 0.93, blue: 0.85).ignoresSafeArea()
        DankeLotusMandala()
            .frame(width: 160, height: 160)
            .environment(\.themeColors, .light)
    }
}
