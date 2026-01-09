# Ticket shared-018: Lock Screen Artwork

**Status**: [x] DONE
**Prioritaet**: MITTEL
**Aufwand**: Klein
**Abhaengigkeiten**: Keine
**Phase**: 4-Polish

---

## Was

Das App-Icon soll im Lock Screen / Notification Player angezeigt werden, wenn eine Guided Meditation laeuft.

## Warum

Aktuell ist der quadratische Bereich fuer Artwork im Lock Screen Player leer. Das sieht unfertig aus und verschenkt eine Branding-Moeglichkeit.

---

## Akzeptanzkriterien

### Feature
- [x] iOS: App-Icon erscheint im Lock Screen Player
- [x] iOS: App-Icon erscheint im Control Center
- [x] Android: App-Icon erscheint in Media Notification
- [x] Android: App-Icon erscheint im Lock Screen Player

### Tests
- [x] iOS: Unit Test verifiziert dass Artwork gesetzt wird
- [x] Android: Unit Test verifiziert dass Artwork gesetzt wird

### Dokumentation
- [x] CHANGELOG.md

---

## Manueller Test

### iOS
1. App starten, Guided Meditation abspielen
2. iPhone sperren (Power-Taste)
3. Lock Screen betrachten
4. Erwartung: App-Icon erscheint im quadratischen Bereich links

### Android
1. App starten, Guided Meditation abspielen
2. Notification Shade herunterziehen
3. Erwartung: App-Icon erscheint in der Media Notification

---

## Referenz

- iOS: `ios/StillMoment/Infrastructure/Services/AudioPlayerService.swift` - `setupNowPlayingInfo()`
- Android: `android/app/src/main/kotlin/com/stillmoment/infrastructure/audio/MediaSessionManager.kt` - `setMetadata()`

---

## Hinweise

### iOS
- `MPMediaItemPropertyArtwork` benoetigt `MPMediaItemArtwork` Wrapper um `UIImage`
- App-Icon verfuegbar unter Asset-Name "AppIcon"

### Android
- `METADATA_KEY_ART` erwartet ein `Bitmap`
- App-Icon als Drawable laden und zu Bitmap konvertieren
