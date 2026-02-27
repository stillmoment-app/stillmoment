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
