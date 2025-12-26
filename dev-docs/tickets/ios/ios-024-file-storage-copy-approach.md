# Ticket ios-024: File Storage auf Kopie-Ansatz umstellen

**Status**: [x] DONE
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

- [x] Import kopiert Datei nach `Application Support/Meditations/`
- [x] `GuidedMeditation.fileBookmark: Data` ersetzt durch `fileURL: URL` (oder String-Pfad)
- [x] Loeschen einer Meditation loescht auch die lokale Datei
- [x] Migration: Bestehende Bookmarks werden zu lokalen Dateien migriert
- [x] Einmal-Flag in UserDefaults (`guidedMeditationsMigratedToLocalFiles_v1`)
- [x] Nicht-auflösbare Bookmarks: Meditation wird entfernt (mit Logging)
- [x] Security-Scoped-Bookmark-Code entfernt (`resolveBookmark`, `startAccessingSecurityScopedResource`, etc.)
- [x] `isAppOwnedFile` Check in PlayerViewModel entfernt
- [x] TestFixtureSeeder nutzt echten Import-Pfad (kopieren statt Bookmark)
- [x] Unit Tests aktualisiert
- [x] Bestehende Meditationen funktionieren nach Migration

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

**Trigger:** `loadMeditations()` prueft Einmal-Flag beim App-Start

**Ablauf:**
1. Pruefe Flag `guidedMeditationsMigratedToLocalFiles_v1` in UserDefaults
2. Falls nicht gesetzt und Bookmarks vorhanden → Migration starten
3. Fuer jede Meditation mit Bookmark:
   - Bookmark aufloesen → URL
   - Security-Scoped Access aktivieren
   - Datei nach `Application Support/Meditations/{uuid}.mp3` kopieren
   - `localFilePath` setzen, `fileBookmark` auf nil
4. Bei Fehler (Bookmark nicht aufloesbar): Meditation entfernen + Logging
5. Flag setzen → Migration laeuft nur einmal

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
