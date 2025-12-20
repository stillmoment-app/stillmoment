# Lesbarkeit (DDD-Fokus)

Spricht der Code die Sprache der Domaene?

## Nur melden wenn wirklich problematisch

### Ubiquitous Language
- Technische Namen statt Domaenen-Begriffe wo Domaenen-Begriffe existieren
- Inkonsistente Begriffe fuer das gleiche Konzept
- Namen die irrefuehren oder das Falsche suggerieren

### Aussagekraeftige Namen
- Name erklaert nicht was die Sache tut/ist
- Generische Namen (`data`, `info`, `manager`, `handler`) wo spezifischere passen
- Abkuerzungen die nicht offensichtlich sind

### Struktur
- Schwer zu folgende Kontrollfluss-Logik
- Tiefe Verschachtelung die den Code schwer lesbar macht
- Wichtige Logik versteckt in Nebensaetzen

## Domaenen-Sprache des Projekts

### Timer-Domaene
- `MeditationTimer`, `TimerState` (running, paused, completed, countdown)
- `MeditationSettings` (intervalGongsEnabled, backgroundSoundId)
- `countdown`, `running`, `paused`, `completed` (States)

### Audio-Domaene
- `AudioSource` (timer, guidedMeditation)
- `AudioSessionCoordinator` (koordiniert zwischen Features)
- `BackgroundSound`, `IntervalGong`, `CompletionGong`

### Library-Domaene
- `GuidedMeditation` (importierte Meditation mit Metadaten)
- `teacher`, `displayName`, `duration`

## Gute Beispiele aus dem Projekt

```swift
// Gut: Domaenen-Sprache
func startCountdown()
func pauseMeditation()
func requestAudioSession(for source: AudioSource)

// Schlecht: Technisch
func startTimer()
func toggle()
func requestSession(type: Int)
```

## NICHT melden

- "Ich wuerde den Namen anders waehlen" (wenn er klar ist)
- "Koennte ausfuehrlicher sein" (wenn er ausreichend ist)
- Rein stilistische Praeferenzen
