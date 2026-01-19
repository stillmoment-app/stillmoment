# Feature-Konzept: Timer Presets

**Status**: Konzeptphase - Brainstorming
**Erstellt**: 2026-01-18

## Problemanalyse

### Aktueller Zustand

User konfiguriert bei jeder stillen Meditation:
- Dauer (1-60 Minuten)
- Vorbereitungszeit (aus/5s/10s/15s/20s/30s/45s)
- Intervall-Gong (aus/3/5/10 Minuten)
- Start/End-Gong Sound + Lautstärke
- Intervall-Gong Sound + Lautstärke
- Hintergrund-Soundscape + Lautstärke

### Das Problem

```
┌─────────────────────────────────────────────────────────────────┐
│ Morgen-Routine (jeden Tag):                                     │
│   → Timer öffnen                                                │
│   → 20 Minuten einstellen                                       │
│   → Intervall auf 5 Min                                         │
│   → Settings prüfen (Gong-Sounds richtig?)                      │
│   → Start                                                       │
│                                                                 │
│ Mittagspause (regelmäßig):                                      │
│   → Timer öffnen                                                │
│   → 10 Minuten einstellen (war noch auf 20)                     │
│   → Intervall ausschalten (will Ruhe)                           │
│   → Start                                                       │
│                                                                 │
│ Abend-Meditation (gelegentlich):                                │
│   → Timer öffnen                                                │
│   → 30 Minuten einstellen                                       │
│   → Wald-Soundscape an                                          │
│   → Leiserer Gong                                               │
│   → Start                                                       │
└─────────────────────────────────────────────────────────────────┘
```

**Friction-Punkte:**
1. Wiederholte manuelle Anpassung
2. "War der Gong letztes Mal leiser?" - Unsicherheit
3. Kognitive Last vor der Meditation (eigentlich soll man abschalten)
4. Längere Zeit bis zum Start

### Wann wird das zum Problem?

| Nutzungsmuster | Problem-Intensität |
|----------------|-------------------|
| Immer gleiche Einstellung | Gering (letzte wird gemerkt) |
| 2-3 verschiedene Routinen | **Hoch** - ständiges Umstellen |
| Spontan, immer anders | Gering (Einstellung ist Teil des Rituals) |

**Zielgruppe für Presets:** User mit 2-4 regelmäßigen Meditationsroutinen.

---

## Lösungsansätze

### Ansatz A: "Letzte Einstellung merken" (Minimal)

Einfachste Lösung - Timer startet immer mit der letzten Konfiguration.

```
┌─────────────────────────────────────┐
│         Stille Meditation           │
│                                     │
│              20:00                  │  ← Wie beim letzten Mal
│                                     │
│         [ ▶ Starten ]               │
│                                     │
│         ⚙️ Einstellungen            │
└─────────────────────────────────────┘
```

**Pro:**
- Null UI-Änderung nötig
- Kein Preset-Management
- Löst Problem für "immer gleich"-User

**Contra:**
- Hilft nicht bei wechselnden Routinen
- Kein schneller Wechsel zwischen Konfigurationen

**Bewertung:** ⭐⭐ (zu minimal für das eigentliche Problem)

---

### Ansatz B: Quick-Start Chips

Horizontale Chips über dem Timer für schnellen Zugriff.

```
┌─────────────────────────────────────┐
│         Stille Meditation           │
│                                     │
│  [Morgen]  [Kurz]  [Abend]  [+]     │  ← Preset-Chips
│                                     │
│              20:00                  │
│                                     │
│         [ ▶ Starten ]               │
│                                     │
│         ⚙️ Einstellungen            │
└─────────────────────────────────────┘
```

**Interaktion:**
- Tap auf Chip → Lädt Preset (Dauer, Sounds, alles)
- Aktiver Chip ist hervorgehoben
- [+] öffnet Preset-Erstellung

**Pro:**
- Ein-Tap-Zugriff
- Sofort sichtbar, welche Presets existieren
- Visuell minimal

**Contra:**
- Horizontal scrollbar bei vielen Presets?
- Braucht Platz auf dem Timer-Screen

**Bewertung:** ⭐⭐⭐⭐ (guter Kompromiss)

---

### Ansatz C: Preset-Picker (Dropdown)

Picker/Dropdown statt Chips.

```
┌─────────────────────────────────────┐
│         Stille Meditation           │
│                                     │
│     ┌── Preset ──────────────┐      │
│     │ Morgen-Meditation    ▼ │      │  ← Dropdown
│     └────────────────────────┘      │
│                                     │
│              20:00                  │
│                                     │
│         [ ▶ Starten ]               │
└─────────────────────────────────────┘

Aufgeklappt:
┌─────────────────────────────────────┐
│     ┌────────────────────────┐      │
│     │ Morgen-Meditation    ✓ │      │
│     │ Kurze Pause            │      │
│     │ Abend-Routine          │      │
│     │ Benutzerdefiniert      │      │
│     │ ─────────────────────  │      │
│     │ + Neues Preset...      │      │
│     └────────────────────────┘      │
└─────────────────────────────────────┘
```

**Pro:**
- Skaliert gut (10+ Presets)
- Weniger visueller Footprint wenn zugeklappt
- "Benutzerdefiniert" als Escape-Hatch

**Contra:**
- Zwei Taps nötig (öffnen + auswählen)
- Weniger "auf einen Blick" sichtbar

**Bewertung:** ⭐⭐⭐ (gut für viele Presets, aber mehr Taps)

---

### Ansatz D: Swipe zwischen Presets

Horizontal swipen wechselt komplettes Preset.

```
        ←  swipe  →
┌─────────────────────────────────────┐
│         Stille Meditation           │
│                                     │
│           Morgen-Routine            │
│              ●  ○  ○                │  ← Page Indicator
│                                     │
│              20:00                  │
│         5 Min Intervall             │
│         Wald-Soundscape             │
│                                     │
│         [ ▶ Starten ]               │
└─────────────────────────────────────┘
```

**Pro:**
- Natürliche iOS-Geste
- Volle Preset-Info sichtbar
- Keine UI-Elemente die Platz brauchen

**Contra:**
- Nicht discoverable (User muss wissen, dass man swipen kann)
- Bei vielen Presets: viel Swipen
- Konkurriert mit Tab-Navigation?

**Bewertung:** ⭐⭐⭐ (elegant aber versteckt)

---

### Ansatz E: Preset-Karten (Carousel)

Horizontales Karussell mit Preset-Karten.

```
┌─────────────────────────────────────────────────────────────┐
│                    Stille Meditation                        │
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │   Morgen    │  │    Kurz     │  │   Abend     │   ...   │
│  │   20 Min    │  │   10 Min    │  │   30 Min    │         │
│  │   ♪ Gong    │  │   ♪ Stille  │  │   ♪ Wald    │         │
│  │             │  │             │  │             │         │
│  │  [Starten]  │  │  [Starten]  │  │  [Starten]  │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
│                                                             │
│                    [+ Eigenes Preset]                       │
└─────────────────────────────────────────────────────────────┘
```

**Pro:**
- Alle wichtigen Infos auf einen Blick
- Direkter Start pro Preset
- Entdeckbar und visuell ansprechend

**Contra:**
- Signifikante UI-Änderung
- Weniger "minimal" als aktuelle UI
- Kein manueller Timer mehr sichtbar?

**Bewertung:** ⭐⭐⭐ (schön aber vielleicht zu viel)

---

### Ansatz F: Long-Press zum Speichern

Aktueller Timer bleibt, Long-Press auf Start speichert als Preset.

```
┌─────────────────────────────────────┐
│         Stille Meditation           │
│                                     │
│              20:00                  │
│                                     │
│         [ ▶ Starten ]               │  ← Long-Press
│                                     │
│         ⚙️ Einstellungen            │
└─────────────────────────────────────┘

Nach Long-Press:
┌─────────────────────────────────────┐
│   ┌───────────────────────────┐     │
│   │ Aktuelle Einstellungen    │     │
│   │ speichern als...          │     │
│   │                           │     │
│   │ [Morgen-Meditation    ]   │     │
│   │                           │     │
│   │    [Abbrechen] [Speichern]│     │
│   └───────────────────────────┘     │
└─────────────────────────────────────┘
```

**Pro:**
- Keine UI-Änderung im Normalfall
- Natürlicher Flow: einstellen → speichern
- Versteckt aber entdeckbar

**Contra:**
- Long-Press ist nicht offensichtlich
- Wie lädt man Presets dann?
- Braucht trotzdem Preset-Liste irgendwo

**Bewertung:** ⭐⭐ (gut für Speichern, löst Laden nicht)

---

### Ansatz G: Presets in Settings + Quick-Access

Presets werden in Settings verwaltet, auf Timer nur Schnellzugriff.

```
Settings-Screen:
┌─────────────────────────────────────┐
│ ← Einstellungen                     │
│                                     │
│ Timer-Presets                       │
│ ┌─────────────────────────────────┐ │
│ │ Morgen-Meditation          ✏️ > │ │
│ │ 20 Min · 5er Intervall · Gong   │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ Kurze Pause                ✏️ > │ │
│ │ 10 Min · Kein Intervall         │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ + Neues Preset erstellen        │ │
│ └─────────────────────────────────┘ │
│                                     │
│ Gong-Sounds                         │
│ ...                                 │
└─────────────────────────────────────┘

Timer-Screen (mit Ansatz B Chips):
┌─────────────────────────────────────┐
│  [Morgen]  [Kurz]  [⚙️]             │
│              20:00                  │
│         [ ▶ Starten ]               │
└─────────────────────────────────────┘
```

**Pro:**
- Klare Trennung: Verwalten vs. Nutzen
- Settings ist logischer Ort für Konfiguration
- Timer bleibt clean

**Contra:**
- Mehr Navigation für Preset-Erstellung
- Zwei Orte die man kennen muss

**Bewertung:** ⭐⭐⭐⭐ (saubere Architektur)

---

### Ansatz H: Kontextbasierte Automatik

App schlägt basierend auf Tageszeit automatisch passendes Preset vor.

```
┌─────────────────────────────────────┐
│         Stille Meditation           │
│                                     │
│     Vorschlag für jetzt (7:30):     │
│     ┌─────────────────────────┐     │
│     │ ☀️ Morgen-Meditation    │     │
│     │    20 Min · 5er Gong    │     │
│     │       [Starten]         │     │
│     └─────────────────────────┘     │
│                                     │
│     Andere Optionen:                │
│     [Kurz] [Abend] [Manuell]        │
└─────────────────────────────────────┘
```

**Zeitregeln (Beispiel):**
- 05:00-10:00 → Morgen-Preset
- 10:00-14:00 → Kurz-Preset (Mittagspause)
- 18:00-23:00 → Abend-Preset
- Sonst → Letztes verwendet

**Pro:**
- Null Taps zum Starten der "richtigen" Meditation
- Intelligent und hilfreich
- Reduziert Entscheidungslast

**Contra:**
- Braucht initiales Setup (welches Preset wann?)
- Könnte User bevormunden
- Komplexität vs. "Simplicity first"

**Bewertung:** ⭐⭐⭐ (cool aber vielleicht over-engineered)

---

### Ansatz I: Minimale Variante - Nur Dauer-Presets

Reduziert auf das Wesentliche: Nur Dauer speichern, Rest bleibt global.

```
┌─────────────────────────────────────┐
│         Stille Meditation           │
│                                     │
│   [5']  [10']  [20']  [30']  [+]    │  ← Nur Dauer
│                                     │
│              20:00                  │
│                                     │
│         [ ▶ Starten ]               │
└─────────────────────────────────────┘
```

**Logik:**
- Dauer ist der häufigste Wechsel
- Sounds/Intervalle bleiben global in Settings
- Simpler = besser?

**Pro:**
- Extrem simpel
- Löst 80% des Problems
- Keine komplexe Preset-Verwaltung

**Contra:**
- Hilft nicht wenn man verschiedene Sound-Setups will
- Zu simpel für Power-User

**Bewertung:** ⭐⭐⭐ (MVP-Kandidat)

---

## Kombinationsvorschläge

### Empfehlung 1: Minimal (für Puristen)

**Ansatz I + F kombiniert:**

```
┌─────────────────────────────────────┐
│         Stille Meditation           │
│                                     │
│   [5']  [10']  [20']  [30']         │  ← Dauer-Schnellwahl
│                                     │
│              20:00                  │
│                                     │
│         [ ▶ Starten ]               │  ← Long-Press speichert
│                                     │
│    Eigene: [Morgen]  [Abend]        │  ← Gespeicherte Presets
└─────────────────────────────────────┘
```

- Dauer-Chips für schnellen Wechsel (häufigster Use Case)
- Long-Press speichert komplettes Preset
- Eigene Presets als zweite Reihe (optional, nur wenn welche existieren)

---

### Empfehlung 2: Praktisch (empfohlen)

**Ansatz B + G kombiniert:**

```
Timer-Screen:
┌─────────────────────────────────────┐
│         Stille Meditation           │
│                                     │
│  [Morgen]  [Kurz]  [Abend]  [+]     │
│                                     │
│              20:00                  │
│                                     │
│         [ ▶ Starten ]               │
│                                     │
│         ⚙️ Einstellungen            │
└─────────────────────────────────────┘

[+] öffnet Sheet:
┌─────────────────────────────────────┐
│ Preset erstellen                    │
│                                     │
│ Name: [Fokus-Session          ]     │
│                                     │
│ Dauer: 25 Minuten                   │
│ Vorbereitung: 10 Sekunden           │
│ Intervall-Gong: Aus                 │
│ Start-Gong: Classic Bowl            │
│ Hintergrund: Stille                 │
│                                     │
│       [Abbrechen] [Speichern]       │
└─────────────────────────────────────┘

Settings → Presets verwalten:
┌─────────────────────────────────────┐
│ Timer-Presets                       │
│                                     │
│ ☰ Morgen-Meditation            ✏️   │
│ ☰ Kurze Pause                  ✏️   │
│ ☰ Abend-Routine                ✏️   │
│                                     │
│ Tipp: Reihenfolge durch Ziehen      │
│       ändern                        │
└─────────────────────────────────────┘
```

**Features:**
- Chips auf Timer-Screen für Ein-Tap-Zugriff
- [+] erstellt neues Preset mit aktuellen Einstellungen als Vorlage
- Settings für Umbenennen, Löschen, Reihenfolge ändern
- Max. 5-6 Presets (mehr = Überladen)

---

### Empfehlung 3: Umfassend (für Power-User)

**Ansatz B + G + H kombiniert:**

```
┌─────────────────────────────────────┐
│         Stille Meditation           │
│                                     │
│     Vorschlag: Morgen-Meditation    │
│     [Starten] oder [Andere...]      │
│                                     │
│  [Morgen]  [Kurz]  [Abend]  [+]     │
│                                     │
│              20:00                  │
│                                     │
│         [ ▶ Manuell Starten ]       │
└─────────────────────────────────────┘
```

- Automatischer Vorschlag basierend auf Tageszeit
- Fallback zu Chips
- Manueller Start für Abweichungen

---

## Preset-Datenmodell

### Was speichert ein Preset?

```swift
struct TimerPreset: Identifiable, Codable {
    let id: UUID
    var name: String
    var durationMinutes: Int
    var preparationSeconds: Int?
    var intervalMinutes: Int?
    var startGongSound: GongSound
    var startGongVolume: Float
    var intervalGongSound: GongSound?
    var intervalGongVolume: Float
    var backgroundSound: BackgroundSound
    var backgroundVolume: Float
    var sortOrder: Int
    var createdAt: Date
    var lastUsedAt: Date?
}
```

### Was speichert ein Preset NICHT?

- Keine Statistiken (widerspricht No-Gamification)
- Keine Tageszeit-Verknüpfung (in Empfehlung 3 wäre das separate Logik)
- Keine Farben/Icons (KISS)

---

## UI-Detail: Preset-Chip States

```
Normal:
┌─────────────┐
│   Morgen    │  ← Terracotta-Outline, transparent fill
└─────────────┘

Ausgewählt:
┌─────────────┐
│   Morgen    │  ← Terracotta-Fill, weiße Schrift
└─────────────┘

Keins ausgewählt (manuell):
┌─────────────┐ ┌─────────────┐
│   Morgen    │ │    Kurz     │  ← Alle nur Outline
└─────────────┘ └─────────────┘

Hinzufügen:
┌─────────────┐
│     +       │  ← Plus-Symbol, gestrichelte Outline
└─────────────┘
```

---

## Interaktionsdetails

### Preset auswählen

```
1. User tippt auf [Kurz]
2. Chip wird ausgefüllt (visuelles Feedback)
3. Timer-Anzeige ändert sich auf Preset-Dauer
4. Alle Settings werden auf Preset-Werte gesetzt
5. User tippt [Starten] → Meditation mit Preset-Config
```

### Manuell ändern nach Preset-Wahl

```
1. User wählt [Morgen] (20 Min)
2. User ändert manuell auf 25 Min
3. Chip [Morgen] wird de-selektiert (kein Chip aktiv)
4. Timer zeigt "25:00" (manuelle Einstellung)
5. Optional: "Als Preset speichern?" Hinweis
```

### Neues Preset erstellen

**Option A: Via [+] Button**
```
1. User tippt [+]
2. Sheet öffnet sich mit aktuellen Einstellungen
3. User gibt Namen ein
4. [Speichern] → Neuer Chip erscheint
```

**Option B: Via Settings**
```
1. User geht zu Settings → Presets
2. [+ Neues Preset]
3. Volle Konfiguration im Editor
4. [Speichern] → Erscheint auf Timer-Screen
```

**Option C: Via Long-Press (versteckt)**
```
1. User konfiguriert Timer manuell
2. Long-Press auf [Starten]
3. Prompt: "Als Preset speichern?"
4. Name eingeben → Gespeichert
```

---

## Edge Cases

### Kein Preset vorhanden

```
┌─────────────────────────────────────┐
│         Stille Meditation           │
│                                     │
│     Noch keine Presets              │
│     [+ Erstes Preset erstellen]     │
│                                     │
│              10:00                  │
│         [ ▶ Starten ]               │
└─────────────────────────────────────┘
```

Oder: Keine Chips anzeigen bis erstes Preset erstellt wird.

### Zu viele Presets (>6)

```
┌─────────────────────────────────────┐
│  [Morgen] [Kurz] [Abend] [...]      │  ← [...] öffnet vollständige Liste
└─────────────────────────────────────┘
```

Oder: Horizontales Scrolling der Chips.

### Preset löschen das gerade aktiv ist

```
1. User löscht [Morgen] in Settings
2. Zurück zum Timer
3. Kein Chip mehr aktiv
4. Timer behält aktuelle Einstellungen (aus gelöschtem Preset)
```

### Preset-Name zu lang

```
┌───────────────────┐
│ Morgen-Medita...  │  ← Truncation mit "..."
└───────────────────┘
```

Max. ~15-18 Zeichen sichtbar.

---

## Migration & Default-Presets

### Keine Default-Presets

Die App startet ohne vordefinierte Presets. User erstellt eigene.

**Begründung:**
- Presets sind persönlich
- Keine "fremden" Namen in der UI
- User versteht das Feature durch eigene Nutzung

### Alternative: Starter-Presets (opt-in)

Beim ersten Öffnen nach Update:

```
┌─────────────────────────────────────┐
│                                     │
│   Neu: Timer-Presets                │
│                                     │
│   Speichere deine Lieblings-        │
│   Einstellungen für schnellen       │
│   Zugriff.                          │
│                                     │
│   [Mit Beispielen starten]          │
│   [Selbst einrichten]               │
│                                     │
└─────────────────────────────────────┘
```

Beispiel-Presets:
- "Kurz" (5 Min, kein Intervall)
- "Standard" (20 Min, 5er Intervall)
- "Lang" (45 Min, 10er Intervall)

---

## Technische Überlegungen

### Speicherung

- Core Data Entity `TimerPreset` (iOS)
- Room Entity `TimerPresetEntity` (Android)
- Max. 10 Presets (soft limit via UI)
- Sync: Keine (lokal only, passt zur Privacy-First-Philosophie)

### Domain Model

```swift
// Domain/Models/TimerPreset.swift
struct TimerPreset: Identifiable, Equatable {
    let id: UUID
    let name: String
    let settings: MeditationSettings
    let sortOrder: Int
    let createdAt: Date
    let lastUsedAt: Date?

    func withUpdatedLastUsedAt(_ date: Date) -> TimerPreset {
        TimerPreset(id: id, name: name, settings: settings,
                    sortOrder: sortOrder, createdAt: createdAt,
                    lastUsedAt: date)
    }
}
```

### Repository Pattern

```swift
protocol TimerPresetRepository {
    func fetchAll() -> [TimerPreset]
    func save(_ preset: TimerPreset)
    func delete(_ preset: TimerPreset)
    func updateSortOrder(_ presets: [TimerPreset])
}
```

---

## Accessibility

- Chips müssen VoiceOver-Label haben: "Morgen-Meditation Preset, 20 Minuten"
- Ausgewählter Chip: "Ausgewählt, Morgen-Meditation Preset"
- [+] Button: "Neues Preset erstellen"
- Preset-Liste in Settings: Reorderable mit VoiceOver

---

## Offene Fragen

1. **Welcher Ansatz passt am besten zur App-Philosophie?**
   - Minimal (Dauer-Chips only)?
   - Praktisch (vollständige Presets)?
   - Umfassend (mit Auto-Vorschlägen)?

2. **Wo werden Presets erstellt?**
   - Auf dem Timer-Screen ([+] Button)?
   - In Settings?
   - Beides?

3. **Sollen Default-Presets angeboten werden?**
   - Keine (User erstellt eigene)?
   - Opt-in Starter-Set?

4. **Wie viele Presets maximal?**
   - 3-4 (sehr minimal)?
   - 6 (praktisch)?
   - Unbegrenzt mit Scrolling?

5. **Soll es Preset-Icons/Farben geben?**
   - Nein (Text only, KISS)?
   - Optional (User kann Emoji/Farbe wählen)?

6. **Plattform-Parität?**
   - iOS + Android gleichzeitig?
   - iOS first?

---

## Fazit

**Empfohlener Startpunkt: Empfehlung 2 (Praktisch)**

- Chips auf Timer für schnellen Zugriff
- [+] zum Erstellen mit aktuellen Einstellungen
- Settings für Verwaltung (Edit, Delete, Reorder)
- Keine Auto-Vorschläge (zu komplex für V1)
- Max. 6 Presets sichtbar

Dieser Ansatz:
- Löst das Kernproblem (schneller Wechsel zwischen Routinen)
- Bleibt minimal (keine Over-Engineering)
- Ist erweiterbar (Auto-Vorschläge können später kommen)
- Passt zur App-Philosophie (hilft ohne zu bevormunden)
