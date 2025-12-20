# Ticket-Philosophie Validierung

Checkliste zur Pruefung ob ein Ticket der Philosophie "WAS und WARUM, nicht WIE" entspricht.

## Red Flags

### 1. Code im Ticket

**Warnung wenn:**
- Code-Bloecke (```) vorhanden
- Swift/Kotlin-Syntax erkennbar
- Pseudo-Code Beschreibungen

**Besser:**
> "Timer-Sound soll bei App-Wechsel weiterlaufen"

statt:
> "In AudioService.swift die Methode playBackgroundAudio() aufrufen wenn UIApplication.willResignActiveNotification"

---

### 2. Dateinamen/Pfade

**Warnung wenn:**
- Konkrete Dateinamen genannt
- Pfade wie `ios/StillMoment/...`
- Zeilennummern referenziert

**Besser:**
> "Background-Audio Komponente soll..."

statt:
> "In ios/StillMoment/Infrastructure/Services/AudioService.swift Zeile 142..."

---

### 3. Implementierungs-Verben

**Warnung wenn:**
- "Implementiere..."
- "Aendere..."
- "Fuege hinzu..."
- "Refactore..."
- "Extrahiere..."

**Besser:**
> "Timer soll X koennen"

statt:
> "Implementiere eine neue Methode die X macht"

---

### 4. Architektur-Details

**Warnung wenn:**
- Pattern-Namen (Singleton, Factory, etc.)
- Layer-Referenzen (Domain, Infrastructure)
- Interface/Protocol-Definitionen

**Besser:**
> "Audio-Wiedergabe soll bei Konflikt automatisch pausieren"

statt:
> "Fuege AudioSessionCoordinatorProtocol im Domain-Layer hinzu und implementiere das Singleton-Pattern"

---

### 5. API-Aufrufe

**Warnung wenn:**
- Konkrete API-Methoden genannt
- Framework-spezifische Aufrufe
- System-Notifications

**Besser:**
> "App soll auf Kopfhoerer-Taste reagieren"

statt:
> "Registriere MPRemoteCommandCenter.shared().togglePlayPauseCommand"

---

## Erlaubt im Ticket

| Erlaubt | Beispiel |
|---------|----------|
| Referenz auf existierenden Code | "Wie beim Timer-Feature" |
| Nicht-offensichtliche Hinweise | "iOS erfordert Audio-Session fuer Lockscreen" |
| Bekannte Fallstricke | "Achtung: Safari behandelt Audio anders" |
| Recherchierte API-Namen | "AVAudioSession Kategorie beachten" |

---

## Validierungs-Logik

```
FUER jede Red-Flag-Kategorie:
  WENN Beschreibung Muster enthaelt:
    ZEIGE Warnung
    SCHLAGE bessere Formulierung vor
    FRAGE: "Soll ich das Ticket trotzdem so erstellen?"
```

## Beispiel-Warnungen

**Eingabe:**
> "Implementiere in AudioService.swift eine Methode stopWithFade() die den Sound ueber 2 Sekunden ausblendet"

**Warnung:**
```
Die Beschreibung enthaelt Implementierungs-Details:
- Dateiname: AudioService.swift
- Implementierungs-Verb: "Implementiere"
- Methoden-Name: stopWithFade()

Vorschlag:
"Ambient-Sound soll beim Stoppen sanft ausblenden (ca. 2 Sekunden)"

Soll ich das Ticket mit dem Vorschlag erstellen?
```
