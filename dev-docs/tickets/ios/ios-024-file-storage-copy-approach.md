# Ticket ios-024: File Storage auf Kopie-Ansatz umstellen

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Aufwand**: Mittel
**Abhaengigkeiten**: Keine
**Phase**: 2-Architektur

---

## Was

Importierte Meditations-Dateien in den App-Container kopieren statt Security-Scoped Bookmarks zu verwenden. Gleicher Ansatz wie Android.

## Warum

1. **Robustheit**: Keine "Datei nicht gefunden" Fehler wenn User Original-Datei verschiebt/loescht
2. **Einfacherer Code**: Kein Bookmark-Lifecycle-Management (`startAccessingSecurityScopedResource`, stale bookmarks)
3. **Konsistenz**: Gleicher Ansatz wie Android - weniger Platform-spezifische Bugs
4. **Vereinfacht ios-023**: Kein `isAppOwnedFile` Workaround mehr im PlayerViewModel

---

## Akzeptanzkriterien

- [ ] Import kopiert Datei nach `Application Support/Meditations/`
- [ ] `GuidedMeditation.fileBookmark: Data` ersetzt durch `fileURL: URL` (oder String-Pfad)
- [ ] Loeschen einer Meditation loescht auch die lokale Datei
- [ ] Migration: Bestehende Bookmarks werden zu lokalen Dateien migriert
- [ ] Security-Scoped-Bookmark-Code entfernt (`resolveBookmark`, `startAccessingSecurityScopedResource`, etc.)
- [ ] `isAppOwnedFile` Check in PlayerViewModel entfernt
- [ ] TestFixtureSeeder nutzt echten Import-Pfad (kopieren statt Bookmark)
- [ ] Unit Tests aktualisiert
- [ ] Bestehende Meditationen funktionieren nach Migration

---

## Manueller Test

**Neuer Import:**
1. Meditation importieren
2. Original-Datei in Dateien-App loeschen
3. Meditation abspielen
4. Erwartung: Playback funktioniert (lokale Kopie)

**Migration:**
1. App mit bestehenden Bookmarks starten
2. Erwartung: Meditationen werden automatisch migriert
3. Playback funktioniert fuer alle migrierten Meditationen

**Loeschen:**
1. Meditation loeschen
2. Erwartung: Speicherplatz wird freigegeben

---

## Referenz

- iOS aktuell: `ios/StillMoment/Infrastructure/Services/GuidedMeditationService.swift`
- Android (Ziel-Ansatz): `android/app/src/main/kotlin/com/stillmoment/data/repositories/GuidedMeditationRepositoryImpl.kt`
- PlayerViewModel: `ios/StillMoment/Application/ViewModels/GuidedMeditationPlayerViewModel.swift` (Zeile 88: `isAppOwnedFile`)
- TestFixtureSeeder: `ios/StillMoment-Screenshots/TestFixtureSeeder.swift`
- CLAUDE.md: Abschnitt "Android File Storage Strategy"

---

## Hinweise

### Trade-off: Speicherverbrauch

- Dateien werden dupliziert (ca. 5-20 MB pro Meditation)
- User kann Original nach Import loeschen
- App-Speicher wird beim Loeschen der Meditation freigegeben

### Migration bestehender Daten

- Beim ersten Start nach Update: Bookmarks aufloesen und Dateien kopieren
- Falls Bookmark nicht mehr aufloesbar: Meditation entfernen (mit Hinweis?)
- Migration nur einmal ausfuehren (Flag in UserDefaults)

### Dateipfad-Struktur

```
Application Support/
└── Meditations/
    ├── {uuid1}.mp3
    ├── {uuid2}.mp3
    └── ...
```

UUID als Dateiname verhindert Kollisionen bei gleichen Original-Dateinamen.

### Code-Entfernung

Nach Umstellung kann entfernt werden:
- `GuidedMeditationServiceProtocol.resolveBookmark()`
- `GuidedMeditationServiceProtocol.startAccessingSecurityScopedResource()`
- `GuidedMeditationServiceProtocol.stopAccessingSecurityScopedResource()`
- `GuidedMeditation.fileBookmark` Property
- `isAppOwnedFile` Check in PlayerViewModel

---
