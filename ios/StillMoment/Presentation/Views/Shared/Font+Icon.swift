//
//  Font+Icon.swift
//  Still Moment
//
//  Presentation Layer — Icon-Font-Helper.
//
//  **Nicht** Teil des Typografie-Systems. Steuert nur SF-Symbol-Groessen
//  in Komponenten wie `VolumeSliderRow`. Typography-Tokens fuer Text liegen
//  in `TextStyle.swift`.
//

import SwiftUI

extension Font {
    /// SF-Symbol-Groesse fuer dekorative Icons in Settings-Reihen (z.B. Speaker
    /// neben dem Lautstaerke-Slider). 12 pt — bewusst kompakter als Text, damit
    /// das Symbol den Slider rahmt statt mit ihm zu konkurrieren.
    static let settingsIcon = Font.system(size: 12)
}
