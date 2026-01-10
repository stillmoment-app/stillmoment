# iOS App Store - Plattform-spezifisch

iOS-spezifische Metadaten für App Store Connect.

> **Gemeinsame Texte** (Beschreibung, Release Notes, Screenshots) siehe: `STORE_CONTENT_SHARED.md`

**Zuletzt aktualisiert:** 2026-01-09

---

## Keywords (max. 100 Zeichen)

```
meditation,app,guided,mindfulness,library,zen,calm,offline,privacy,free,timer,yoga
```
**Zeichen:** 82/100

**Alternative Keywords:**
```
meditate,achtsamkeit,klangschale,gong,bell,silent,vipassana,zazen,wellness,relax
```

---

## Promotional Text (max. 170 Zeichen)

### English
```
Meditation as it should be. A gift, not a product — free and open source. Guided meditation library + silent timer. No ads, no tracking, no distractions.
```
**Zeichen:** 155/170

### Deutsch
```
Meditation, wie sie sein sollte. Ein Geschenk, kein Produkt — kostenlos und Open Source. Geführte Meditationen + stiller Timer. Keine Werbung, kein Tracking.
```
**Zeichen:** 160/170

---

## Kategorie & Rating

| Feld | Wert |
|------|------|
| **Primary Category** | Health & Fitness |
| **Secondary Category** | Lifestyle |
| **Age Rating** | 4+ |

---

## Privacy Labels (App Store Connect)

**Status:** "No, this app does not collect data"

- Contact Info: Not collected
- Health & Fitness: Not collected
- Financial Info: Not collected
- Location: Not collected
- User Content: Not collected
- Identifiers: Not collected
- Usage Data: Not collected
- Diagnostics: Not collected

---

## App Review Notes

```
Thank you for reviewing Still Moment!

BACKGROUND AUDIO EXPLANATION:
This meditation timer uses background audio to support meditation with locked screens. The implementation is fully Apple-compliant:

1. Start gong (Tibetan singing bowl) - clearly audible
2. Background audio loop during meditation:
   - Silent Ambience: 15% volume (subtle ambient soundscape)
   - Forest Ambience: 15% volume (natural forest sounds)
3. Optional interval gongs every 3/5/10 minutes - clearly audible
4. Completion gong - clearly audible

This provides continuous audio content (not a "silent audio trick") to legitimize background mode. The app properly activates/deactivates the audio session for energy efficiency.

TESTING THE APP:
1. Start a 2-minute meditation with interval gongs enabled (Settings → Interval Gongs → 3 minutes)
2. Lock the screen
3. You'll hear the start gong, then background audio, then completion gong
4. Background audio keeps the timer active while screen is locked

PRIVACY:
The app collects zero data. All settings and meditation files are stored locally. No internet connection required. Privacy Manifest included.

GUIDED MEDITATIONS:
The MP3 import feature allows users to bring their own meditation audio files. Files remain on the user's device - we only store references (security-scoped bookmarks). No files are uploaded or transmitted.

ACCESSIBILITY:
Full VoiceOver support with 44+ accessibility labels in German and English.

Feel free to contact me with any questions!
```

---

## Build Information

| Feld | Wert |
|------|------|
| **Bundle ID** | com.stillmoment.StillMoment |
| **Minimum iOS** | 16.0 |
| **Xcode** | 26.0+ |
| **Swift** | 5.9+ |

---

## Screenshot-Größen (iOS)

| Device | Größe |
|--------|-------|
| iPhone 6.7" (15 Pro Max) | 1290 x 2796 px |
| iPhone 6.5" (11 Pro Max) | 1242 x 2688 px |
| iPad Pro 12.9" (3rd gen+) | 2048 x 2732 px |

---

## Submission Checklist

### Technisch
- [ ] Privacy Policy URL in Info.plist
- [ ] Support URL in Info.plist
- [ ] App-Icon 1024x1024px vorhanden
- [ ] Screenshots für alle Größen
- [ ] Build via Xcode hochgeladen
- [ ] TestFlight-Tests abgeschlossen

### Metadata
- [ ] App-Name und Subtitle (siehe SHARED)
- [ ] App-Beschreibung DE + EN (siehe SHARED)
- [ ] Keywords eingegeben (≤100 Zeichen)
- [ ] Promotional Text (optional)
- [ ] Kategorie: Health & Fitness
- [ ] Age Rating: 4+
- [ ] Privacy Labels: "No data collected"

### App Review
- [ ] Background Audio erklärt
- [ ] Testanweisungen enthalten
- [ ] Kontakt für Reviewer

### Legal
- [ ] Copyright-Information
- [ ] Export Compliance beantwortet

---

## Tipps für Approval

1. **Background Audio transparent erklären** - Apple schätzt Ehrlichkeit
2. **Privacy betonen** - Apple liebt Privacy-First Apps
3. **Auf echtem Gerät testen** - Hintergrund-Audio mit gesperrtem Bildschirm
4. **Schnell antworten** - Bei Fragen innerhalb 24h reagieren
