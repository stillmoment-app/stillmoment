# Ticket android-016: Storage-Unterschiede Dokumentation

**Status**: [x] DONE
**Prioritaet**: NIEDRIG
**Aufwand**: Klein (~1h)
**Abhaengigkeiten**: android-014
**Phase**: 5-QA

---

## Beschreibung

Die Support-Seite und Dev-Dokumentation muessen aktualisiert werden, um die unterschiedlichen Storage-Strategien zwischen iOS und Android zu erklaeren.

**Hintergrund:**
- **iOS**: Verwendet Security-Scoped Bookmarks - Datei bleibt am Originalort (iCloud, Files App)
- **Android**: Kopiert Datei in App-internen Storage - zuverlaessiger Zugriff, aber mehr Speicherplatz

User muessen verstehen:
- Android: Original-Datei kann nach Import geloescht werden
- Android: Meditation loeschen entfernt auch die Kopie
- iOS: Original-Datei muss erreichbar bleiben

---

## Akzeptanzkriterien

- [x] Support-Seite (docs/support.html) mit "Platform Differences" Sektion
- [x] FAQ-Eintrag zu Import-Unterschieden (DE + EN)
- [x] CLAUDE.md Android-Architektur-Sektion aktualisiert
- [ ] Optional: In-App Hinweis beim Import (Android)

---

## Betroffene Dateien

### Zu aendern:
- `docs/support.html` - Neue Sektion "Platform Differences"
- `CLAUDE.md` - Android Storage-Strategie dokumentieren

### Optional:
- `android/app/src/main/res/values/strings.xml` - Import-Hinweis String
- `android/app/src/main/res/values-de/strings.xml` - Deutsche Uebersetzung

---

## Technische Details

### Support-Seite Erweiterung

```html
<!-- Platform Differences -->
<div class="support-section">
    <h2 class="lang-en">Platform Differences (iOS vs Android)</h2>
    <h2 class="lang-de hidden">Plattform-Unterschiede (iOS vs Android)</h2>

    <div class="faq-item">
        <h3 class="lang-en">How does meditation import work differently?</h3>
        <h3 class="lang-de hidden">Wie unterscheidet sich der Meditations-Import?</h3>

        <p class="lang-en">
            <strong>iOS:</strong> References the original file location (iCloud Drive, Files app).
            The original file must remain accessible for playback to work.<br><br>
            <strong>Android:</strong> Copies the file to app storage during import.
            This uses more storage space but ensures reliable playback even after app restart.
            You can safely delete the original file after importing.
        </p>
        <p class="lang-de hidden">
            <strong>iOS:</strong> Referenziert den Original-Speicherort (iCloud Drive, Dateien-App).
            Die Original-Datei muss fuer die Wiedergabe erreichbar bleiben.<br><br>
            <strong>Android:</strong> Kopiert die Datei beim Import in den App-Speicher.
            Das verbraucht mehr Speicherplatz, garantiert aber zuverlaessige Wiedergabe auch nach App-Neustart.
            Du kannst die Original-Datei nach dem Import sicher loeschen.
        </p>
    </div>

    <div class="faq-item">
        <h3 class="lang-en">Why does Android copy files instead of referencing them?</h3>
        <h3 class="lang-de hidden">Warum kopiert Android Dateien statt sie zu referenzieren?</h3>

        <p class="lang-en">
            Android's Storage Access Framework (SAF) doesn't reliably maintain file access
            permissions after app restart, especially for files from Downloads or cloud storage.
            Copying ensures your meditations always play, regardless of where the original file came from.
        </p>
        <p class="lang-de hidden">
            Androids Storage Access Framework (SAF) behaelt Dateizugriffs-Berechtigungen nach
            App-Neustart nicht zuverlaessig, besonders bei Dateien aus Downloads oder Cloud-Speicher.
            Das Kopieren stellt sicher, dass deine Meditationen immer abspielbar sind,
            unabhaengig davon, woher die Original-Datei stammt.
        </p>
    </div>

    <div class="faq-item">
        <h3 class="lang-en">What happens to storage when I delete a meditation?</h3>
        <h3 class="lang-de hidden">Was passiert mit dem Speicher, wenn ich eine Meditation loesche?</h3>

        <p class="lang-en">
            <strong>iOS:</strong> Only the reference is removed. The original file remains untouched.<br><br>
            <strong>Android:</strong> The copied file in app storage is deleted, freeing up space.
        </p>
        <p class="lang-de hidden">
            <strong>iOS:</strong> Nur die Referenz wird entfernt. Die Original-Datei bleibt unveraendert.<br><br>
            <strong>Android:</strong> Die kopierte Datei im App-Speicher wird geloescht und gibt Speicherplatz frei.
        </p>
    </div>
</div>
```

### CLAUDE.md Erweiterung

Unter "Android Architecture" eine neue Subsektion:

```markdown
### File Storage Strategy (Android)

**Problem**: Android SAF (Storage Access Framework) persistable permissions are unreliable,
especially with Downloads folder and cloud providers (Google Drive, OneDrive, etc.).

**Solution**: Copy imported files to app-internal storage during import.

**Flow**:
1. User selects file via OpenDocument picker
2. `GuidedMeditationRepositoryImpl.importMeditation()` copies file to `filesDir/meditations/`
3. Local `file://` URI is stored in DataStore (not original `content://` URI)
4. On delete, local copy is also removed

**Trade-offs**:
| Aspect | iOS (Bookmarks) | Android (Copy) |
|--------|-----------------|----------------|
| Storage | No duplication | File copied |
| Reliability | High | Very High |
| Original file | Must stay accessible | Can be deleted |
| Delete behavior | Reference only | File deleted |

**Code locations**:
- `GuidedMeditationRepositoryImpl.kt:copyFileToInternalStorage()`
- `GuidedMeditationRepositoryImpl.kt:deleteMeditation()` (also deletes local file)
- `AudioPlayerService.kt:play()` (handles both `file://` and `content://` URIs)
```

---

## Zeitpunkt

Diese Dokumentation sollte aktualisiert werden:
- **Support-Seite**: Wenn Android-Version im Play Store veroeffentlicht wird
- **CLAUDE.md**: Kann sofort aktualisiert werden (Dev-Dokumentation)

---

## Referenzen

- Ticket android-014: setDataSource Fix (Ursache fuer diese Aenderung)
- [Android SAF Guide](https://developer.android.com/guide/topics/providers/document-provider)
- [iOS Security-Scoped Bookmarks](https://developer.apple.com/documentation/foundation/nsurl/1417051-bookmarkdata)
