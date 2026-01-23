# Feature-Konzept: iOS System Focus Mode Integration

**Status**: Konzept
**Erstellt**: 2026-01-23

## Übersicht

Integration des iOS System Focus Mode ("Nicht stören") in Still Moment, um Benachrichtigungen während der Meditation automatisch zu unterdrücken.

**Wichtig:** Dies ist der iOS **System** Focus Mode (Benachrichtigungen unterdrücken), nicht der bereits implementierte In-App Focus Mode (UI vereinfachen, siehe `shared-013`).

**Kernproblem**: Benachrichtigungen während der Meditation stören die Konzentration. User wünschen sich automatische Aktivierung des "Nicht stören"-Modus.

**Lösung**: User-geführte Integration über iOS Shortcuts/Automations, da Apple keine direkte API bereitstellt.

---

## Technische Realität: Apple APIs

### Es gibt keine öffentliche Apple API, um den Focus Mode programmatisch zu aktivieren.

Apple betrachtet Focus Mode als User-kontrollierte System-Einstellung. Aus Datenschutz- und Sicherheitsgründen können Apps diese Einstellung nicht manipulieren.

> "This setting is reserved for the user" - [Apple Developer Forums](https://developer.apple.com/forums/thread/670579)

---

## Was Apple stattdessen bietet

### 1. SetFocusFilterIntent (iOS 16+)

Apps können auf Focus-Änderungen **reagieren**, aber nicht selbst auslösen:

```swift
struct MeditationFocusFilter: SetFocusFilterIntent {
    static var title: LocalizedStringResource = "Meditation Mode"
    static var description: IntentDescription = "Customize Still Moment during Focus"

    @Parameter(title: "Hide Library")
    var hideLibrary: Bool

    func perform() async throws -> some IntentResult {
        // App-Verhalten anpassen wenn Focus aktiv
        return .result()
    }
}
```

**Fähigkeiten:**
- App-Verhalten anpassen wenn Focus aktiv
- Benachrichtigungen der eigenen App filtern
- Badge-Counts aktualisieren

**Einschränkungen:**
- Kann Focus NICHT aktivieren
- iOS 18 hat bekannte Bugs mit Focus Filters
- User muss Focus manuell erstellen und aktivieren

### 2. Siri Shortcuts Integration

Apps können Shortcuts anbieten, die User mit Focus kombinieren können.

---

## Lösungsansätze

### Option A: Shortcuts Automation (Empfohlen)

**Konzept:** User erstellt eine iOS Shortcuts-Automation

**User-Flow:**
1. Einstellungen → Kurzbefehle → Automation → Neue Automation
2. "Wenn App geöffnet wird" → Still Moment auswählen
3. Aktion: "Fokus aktivieren" → z.B. "Nicht stören"
4. Optional: Zweite Automation für "App wird geschlossen" → Fokus deaktivieren

**Implementation in Still Moment:**
- In-App Tutorial/Anleitung mit Screenshots
- Optional: Deep Link zu Shortcuts-App
- Hinweis beim ersten Meditations-Start

**Vorteile:**
- Funktioniert zuverlässig
- Apple-konform
- Keine speziellen Berechtigungen nötig
- User behält volle Kontrolle

**Nachteile:**
- Erfordert manuelles Setup durch User
- Nicht alle User kennen Shortcuts

---

### Option B: Eigener Focus Mode erstellen lassen

**Konzept:** User erstellt einen "Meditation" Focus Mode in iOS Settings

**User-Flow:**
1. Einstellungen → Fokus → + → Eigener Fokus
2. Name: "Meditation"
3. Benachrichtigungen: Alle stummschalten (oder nur wichtige zulassen)
4. Automation hinzufügen: "Wenn Still Moment geöffnet"

**Implementation in Still Moment:**
- Anleitung in den App-Settings
- Deep Link zu Focus-Einstellungen: `App-prefs:FOCUS`

**Vorteile:**
- Tiefere iOS-Integration
- User kann granular konfigurieren
- Sichtbar im Control Center

**Nachteile:**
- Mehr Setup-Aufwand
- Komplexer zu erklären

---

### Option C: SetFocusFilterIntent implementieren

**Konzept:** Still Moment registriert sich als Focus Filter

**Implementation:**

```swift
import AppIntents

// In AppIntents-Ordner
struct StillMomentFocusFilter: SetFocusFilterIntent {
    static var title: LocalizedStringResource = "Still Moment"
    static var description = IntentDescription("Meditation mode settings")

    @Parameter(title: "Simplified UI")
    var simplifiedUI: Bool = true

    func perform() async throws -> some IntentResult {
        // Speichern für App-State
        UserDefaults.standard.set(simplifiedUI, forKey: "focusSimplifiedUI")
        return .result()
    }
}
```

**User-Flow:**
1. User erstellt Focus "Meditation"
2. Unter "Focus Filter" → Still Moment hinzufügen
3. Optionen konfigurieren (z.B. vereinfachte UI)
4. Wenn Focus aktiv → App reagiert entsprechend

**Vorteile:**
- Moderne iOS-Integration
- App erscheint in Focus-Settings
- Kann App-Verhalten anpassen

**Nachteile:**
- Löst Focus NICHT automatisch aus
- iOS 18 Bugs dokumentiert
- Komplexere Implementation

---

### Option D: Sanfter Hinweis (Minimal)

**Konzept:** Einmaliger Hinweis vor/beim Meditations-Start

**Implementation:**

```swift
// Beim Start einer Meditation
if !UserDefaults.hasSeenFocusTip {
    showFocusTipSheet()
    UserDefaults.hasSeenFocusTip = true
}
```

**UI:**
> "Tipp: Aktiviere den Fokus-Modus für ungestörte Meditation"
> [Zu iOS Einstellungen] [Nicht mehr anzeigen]

**Vorteile:**
- Minimaler Aufwand
- Keine komplexe Integration
- Respektiert User-Autonomie

**Nachteile:**
- Kein automatisches Aktivieren
- User muss selbst handeln

---

## Empfehlung

**Kombination aus Option A + D:**

1. **Einmaliger Hinweis (D)** beim ersten Meditations-Start
2. **In-App Anleitung (A)** in den Einstellungen mit Schritt-für-Schritt Screenshots
3. **Optional später:** SetFocusFilterIntent (C) für erweiterte Integration

**Begründung:**
- Respektiert Still Moment's Philosophie (keine aufdringlichen Features)
- User behält volle Kontrolle
- Minimaler Implementierungsaufwand
- Apple-konform

---

## Was andere Apps machen

| App | Ansatz |
|-----|--------|
| Headspace | Bietet eigene In-App "Focus" Features, nutzt iOS Shortcuts Integration |
| Calm | Ähnlich wie Headspace |
| Timefully | Bietet Shortcuts-Integration für DND |

**Fazit:** Keine der großen Meditations-Apps kann Focus automatisch aktivieren.

---

## Fallstricke & Risiken

| Risiko | Beschreibung | Mitigation |
|--------|--------------|------------|
| iOS 18 Bugs | SetFocusFilterIntent wird nicht immer aufgerufen | Fallback implementieren, iOS 18.x Fixes abwarten |
| User-Frustration | Setup zu kompliziert | Klare Anleitung mit Screenshots |
| Feature Creep | Zu viele Optionen | Einfach halten, nur Hinweis + Anleitung |
| App Store Rejection | Keine - das ist der offizielle Weg | N/A |

---

## Offene Fragen

- [ ] **UI-Design**: Wie sollte der einmalige Hinweis aussehen?
- [ ] **Zeitpunkt**: Beim ersten App-Start oder beim ersten Meditations-Start?
- [ ] **Anleitung**: Screenshots erstellen für Shortcuts-Setup?
- [ ] **Deep Link**: `App-prefs:FOCUS` auf allen iOS-Versionen unterstützt?
- [ ] **Focus Filter**: iOS 18 Bugs abwarten oder implementieren?
- [ ] **Lokalisierung**: Anleitung in DE + EN?

---

## Quellen

- [Apple Developer Forums: API to enable/disable Focus](https://developer.apple.com/forums/thread/693444)
- [Apple Developer Forums: No API for Do Not Disturb](https://developer.apple.com/forums/thread/670579)
- [Apple: SetFocusFilterIntent Documentation](https://developer.apple.com/documentation/appintents/setfocusfilterintent)
- [WWDC22: Meet Focus Filters](https://developer.apple.com/videos/play/wwdc2022/10121/)
- [Tutorial: Focus Filters Implementation](https://crunchybagel.com/showing-relevant-data-using-focus-filters/)
- [iDownloadBlog: Auto-enable DND when opening an app](https://www.idownloadblog.com/2023/04/21/how-to-auto-enable-dnd-when-you-open-a-certain-app-on-iphone/)
