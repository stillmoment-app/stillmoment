# android-072 Implementation Log

---

## IMPLEMENT
Status: DONE
Commits:
- c85928b test(android): #android-072 add unit tests for SoundCatalogRepositoryImpl JSON parsing

Challenges:
<!-- CHALLENGES_START -->
- keine
<!-- CHALLENGES_END -->

Summary:
Unit-Tests fuer SoundCatalogRepositoryImpl geschrieben. Tests pruefen JSON-Parsing via companion object parseSoundsJson() ohne Android Context. Abgedeckt: Katalog hat mehr als 2 Eintraege, Silent-Sound-Erkennung, rawResourceName-Konvertierung, Pflichtfelder vorhanden, und SerializationException bei ungueltigem JSON.

---

## CLOSE
Status: DONE
Commits:
- 9f04331 feat(android): #android-072 wire SoundCatalogRepository into AudioService and DI module

---

## FIX 1
Status: DONE
Commits:
- c10c45a feat(android): #android-072 load built-in sounds from SoundCatalogRepository in PraxisEditor

Challenges:
<!-- CHALLENGES_START -->
- BackgroundSound.allSounds und BackgroundSound.findOrDefault waren in mehr Dateien referenziert als die Aufgabe nannte (TimerScreen.kt, SettingsSheet.kt, AudioService.kt) -- alle mussten migriert werden
- AudioService.getBackgroundSoundResourceId wurde von companion auf private instance method geaendert -- 3 Tests die die companion method testeten mussten entfernt werden
- mockSoundCatalogRepository.findById() returnierte default null -- 7 AudioServiceTest Background-Preview-Tests schlugen fehl weil playBackgroundPreview intern soundCatalogRepository.findById() aufruft
- 11 Test-Dateien brauchten FakeSoundCatalogRepository als neuen Constructor-Parameter -- systematisch alle TimerViewModel- und PraxisEditorViewModel-Tests aktualisiert
<!-- CHALLENGES_END -->

Summary:
Alle BackgroundSound.allSounds und BackgroundSound.findOrDefault Referenzen durch SoundCatalogRepository ersetzt. builtInSounds als State in PraxisEditorUiState und TimerUiState hinzugefuegt, durch ViewModel-Konstruktoren injiziert und in SelectBackgroundSoundScreen und TimerScreen Configuration Pills durchgereicht. FakeSoundCatalogRepository fuer Tests erstellt und in alle 11 betroffenen Test-Dateien integriert.

---

## REVIEW 1
Verdict: PASS

make check: OK
make test: OK

DISCUSSION:
<!-- DISCUSSION_START -->
- android/app/src/main/assets/sounds.json:1 - Die Android-JSON hat die neuen Sounds (rain, ocean, birds), die iOS-JSON hat noch nicht (iOS hat nur silent + forest). Das ist laut Ticket explizit gewollt ("mindestens dieselben wie iOS"), ist aber eine Cross-Platform-Divergenz. Wenn iOS erweitert wird, muss das in android-072 dokumentiert oder ein Folgeticket erstellt werden.
- android/app/src/main/kotlin/com/stillmoment/presentation/ui/timer/SelectBackgroundSoundScreen.kt:78-84 - `iconForBackgroundSound()` bildet nur "forest" auf ein passendes Icon ab (`Icons.Filled.Forest`). Alle anderen nicht-stillen Sounds fallen auf `VolumeUp` zurück. Das ist funktional korrekt, aber semantisch schwach. Wenn irgendwann spezifische Icons fuer rain/ocean/birds hinzukommen, muss hier manuell erweitert werden.
<!-- DISCUSSION_END -->

Summary:
Alle Akzeptanzkriterien sind erfuellt. sounds.json ist Single Source of Truth mit 5 Eintraegen. Das BackgroundSound.kt companion object ist auf `SILENT_ID` bereinigt (allSounds, nameEnglish, nameGerman entfernt). Die JSON-Struktur ist konform zu iOS (id, filename, name.en/de, description.en/de, volume), und die Sound-IDs sind rueckwaertskompatibel. Die `resolveRawResourceId`-Methode kennt alle 5 raw resources (forest_ambience, rain_ambience, ocean_waves, birds_chirping, silence). Das Dropdown zeigt alle Sounds via `builtInSounds` aus dem SoundCatalogRepository. Die Preview-Methode `playBackgroundPreview()` geht durch `getBackgroundSoundResourceId()` -> `soundCatalogRepository.findById()` -> `resolveRawResourceId()` und ist fuer alle Sounds verdrahtet. Die Unit-Tests decken alle drei Ticket-Anforderungen ab (>2 Eintraege, Pflichtfelder, SerializationException). make check und make test sind grueen.
