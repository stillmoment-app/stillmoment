# Android Play Store Listing

Texte und Materialien für den Google Play Store Eintrag.

## App-Informationen

| Feld | Wert |
|------|------|
| **App-Name** | Still Moment |
| **Kategorie** | Gesundheit & Fitness |
| **Inhaltsfreigabe** | PEGI 3 / USK 0 |
| **Preis** | Kostenlos |

---

## Kurzbeschreibung (max. 80 Zeichen)

**Deutsch:**
```
Meditation Timer mit sanften Gongs und geführten Meditationen
```

**English:**
```
Meditation timer with gentle gongs and guided meditations
```

---

## Vollständige Beschreibung (max. 4000 Zeichen)

### Deutsch

```
Still Moment ist dein warmherziger Begleiter für tägliche Meditation.

FEATURES:
• Flexibler Meditations-Timer (1-60 Minuten)
• Sanfte tibetische Klangschalen als Start- und Endsignal
• Optionale Intervall-Gongs (3, 5 oder 10 Minuten)
• Beruhigende Hintergrundklänge (Waldambiente oder Stille)
• Geführte Meditationen importieren und abspielen
• 15-Sekunden Countdown vor Meditationsbeginn
• Vollständig auf Deutsch und Englisch

DESIGN:
• Warme Erdtöne für eine entspannte Atmosphäre
• Minimalistisch und ablenkungsfrei
• TalkBack-Unterstützung für Barrierefreiheit

HINTERGRUND-WIEDERGABE:
• Timer läuft weiter bei gesperrtem Bildschirm
• Benachrichtigung zeigt verbleibende Zeit
• Perfekt für Meditation mit geschlossenen Augen

GEFÜHRTE MEDITATIONEN:
• Importiere deine eigenen MP3-Dateien
• Organisiere nach Lehrer oder Thema
• Vollständige Wiedergabesteuerung

PRIVATSPHÄRE:
• Keine Registrierung erforderlich
• Keine Werbung
• Keine Datenerfassung
• Alle Daten bleiben auf deinem Gerät

Beginne deine Meditationspraxis mit Still Moment.
```

### English

```
Still Moment is your warmhearted companion for daily meditation.

FEATURES:
• Flexible meditation timer (1-60 minutes)
• Gentle Tibetan singing bowls as start and end signals
• Optional interval gongs (3, 5, or 10 minutes)
• Soothing background sounds (forest ambience or silence)
• Import and play guided meditations
• 15-second countdown before meditation starts
• Available in English and German

DESIGN:
• Warm earth tones for a relaxed atmosphere
• Minimalist and distraction-free
• TalkBack support for accessibility

BACKGROUND PLAYBACK:
• Timer continues with screen locked
• Notification shows remaining time
• Perfect for meditating with eyes closed

GUIDED MEDITATIONS:
• Import your own MP3 files
• Organize by teacher or theme
• Full playback controls

PRIVACY:
• No registration required
• No ads
• No data collection
• All data stays on your device

Start your meditation practice with Still Moment.
```

---

## Release-Notes (v1.7.0)

### Deutsch

```
Version 1.7.0:

• 5 wählbare Gong-Klänge (Classic Bowl, Deep Resonance, Clear Strike, Deep Zen, Warm Zen)
• Lautstärkeregler für Hintergrundklänge und Gongs
• Sound-Vorschau in Einstellungen
• Konfigurierbare Vorbereitungszeit (10-30 Sek.)
• Lockscreen-Artwork bei geführten Meditationen
• Verbessertes Settings-Design mit Card-Layout
```

### English

```
Version 1.7.0:

• 5 selectable gong sounds (Classic Bowl, Deep Resonance, Clear Strike, Deep Zen, Warm Zen)
• Volume sliders for background sounds and gongs
• Sound preview in settings
• Configurable preparation time (10-30 sec.)
• Lock screen artwork for guided meditations
• Improved settings design with card layout
```

---

## Grafiken

### App-Icon (512x512 PNG)

Exportieren aus: `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.webp`

**Anforderungen:**
- 512 x 512 Pixel
- PNG-Format
- Ohne Alphakanal (kein Transparenz)
- Maximale Dateigröße: 1 MB

### Feature-Grafik (1024x500 PNG) - Optional

Eine Grafik die oben im Store-Eintrag angezeigt wird.

**Empfehlung:**
- App-Name "Still Moment" prominent
- Warme Erdtöne passend zum App-Design
- Einfaches, meditatives Motiv

### Screenshots

**Anforderungen:**
- Mindestens 2, empfohlen 4-8
- JPEG oder PNG (24-bit, kein Alpha)
- Mindestgröße: 320px
- Maximalgröße: 3840px
- Seitenverhältnis: 16:9 oder 9:16

**Empfohlene Screenshots:**
1. Timer im Leerlauf (Picker sichtbar)
2. Timer während Meditation
3. Einstellungen-Sheet
4. Bibliothek mit geführten Meditationen
5. Audio-Player

---

## Data Safety Fragebogen

### Datenerfassung

| Frage | Antwort |
|-------|---------|
| Sammelt die App Nutzerdaten? | Nein |
| Teilt die App Daten mit Dritten? | Nein |
| Werden Daten verschlüsselt übertragen? | N/A (keine Netzwerknutzung) |
| Können Nutzer die Löschung ihrer Daten beantragen? | N/A (keine Daten gespeichert) |

### Lokale Datenspeicherung

| Datentyp | Gespeichert? | Zweck |
|----------|--------------|-------|
| Timer-Einstellungen | Ja (lokal) | App-Präferenzen |
| Importierte Meditationen | Ja (lokal) | Wiedergabe |
| Analytics/Tracking | Nein | - |
| Crash-Reports | Nein | - |

---

## Content Rating Fragebogen

Erwartete Antworten für PEGI 3 / USK 0:

| Kategorie | Antwort |
|-----------|---------|
| Gewalt | Nein |
| Sexuelle Inhalte | Nein |
| Glücksspiel | Nein |
| Drogen | Nein |
| Nutzergenerierte Inhalte | Nein |
| In-App-Käufe | Nein |
| Werbung | Nein |
| Standortzugriff | Nein |

---

## Keystore-Erstellung

Befehl zum Erstellen des Upload-Keystores:

```bash
keytool -genkey -v -keystore stillmoment-upload.keystore \
  -alias stillmoment -keyalg RSA -keysize 2048 -validity 10000
```

**Wichtig:**
- Passwort im Passwort-Manager speichern
- Keystore-Datei sicher aufbewahren (Backup!)
- NIEMALS ins Git-Repository committen

### keystore.properties (Vorlage)

Erstelle `android/keystore.properties` mit folgendem Inhalt:

```properties
storeFile=../stillmoment-upload.keystore
storePassword=DEIN_PASSWORT
keyAlias=stillmoment
keyPassword=DEIN_PASSWORT
```

---

## Build-Befehl

```bash
cd android
./gradlew bundleRelease
```

**Output:** `android/app/build/outputs/bundle/release/app-release.aab`

---

## Checkliste

### Vor dem Upload
- [ ] Upload-Keystore erstellt und sicher gespeichert
- [ ] keystore.properties erstellt
- [ ] Release-Bundle gebaut: `./gradlew bundleRelease`
- [ ] Bundle auf Gerät getestet
- [ ] Screenshots erstellt (min. 2)
- [ ] App-Icon 512x512 exportiert

### Im Play Console
- [ ] App-Eintrag erstellt
- [ ] Store-Beschreibung (DE + EN) eingegeben
- [ ] Screenshots hochgeladen
- [ ] App-Icon hochgeladen
- [ ] Content Rating ausgefüllt
- [ ] Data Safety ausgefüllt
- [ ] Privacy Policy URL: https://stillmoment.app/privacy
- [ ] AAB-Bundle hochgeladen
- [ ] Release-Notes eingegeben
- [ ] Zur Überprüfung eingereicht

---

**Zuletzt aktualisiert:** 2026-01-09
