# Ticket shared-085: Store + Website spiegeln Meditationen-zuerst-IA

**Status**: [ ] TODO
**Prioritaet**: NIEDRIG
**Komplexitaet**: Niedrig — Reihenfolge-Anpassungen in Screenshot-Generator, Captions, Website-FAQ. Keine Code-Aenderungen an der App selbst.
**Phase**: 4-Polish

---

## Was

App-Store-Screenshots und Website fuehren mit dem Meditationen-Tab statt mit dem Timer. Konkret:
- App-Store-Screenshots zeigen zuerst die Meditations-Bibliothek / Player, danach den Timer.
- Website-FAQ (Support-Seite) listet Meditations-Bibliotheks-Fragen vor Timer-Fragen.

## Warum

Nach shared-084 ist der Meditationen-Tab der erste Tab. Marketing- und Support-Material soll dieselbe Prioritaet zeigen, damit Store-Listing, Website und App ein konsistentes Bild der Produktvision vermitteln (Library = Kernfeature, Timer = Add-on). App-Store-Description und Website-Hero sortieren bereits korrekt — Screenshots und FAQ noch nicht.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | shared-084    |
| Android   | [ ]    | shared-084    |

---

## Akzeptanzkriterien

### Marketing (beide Plattformen)
- [ ] App-Store-Screenshots zeigen zuerst Meditations-Bibliothek/Player, danach Timer-Screens
- [ ] Screenshot-Captions (title.strings bzw. Aequivalent) folgen der neuen Reihenfolge
- [ ] Screenshot-Generator (Fastlane / UI-Tests) erzeugt die neue Reihenfolge reproduzierbar
- [ ] Lokalisiert (DE + EN) — Captions sind in beiden Sprachen aktualisiert

### Website
- [ ] FAQ auf der Support-Seite startet mit einer Meditations-Bibliotheks-Frage statt mit "Wie starte ich einen Meditations-Timer?"
- [ ] FAQ-Reihenfolge in DE und EN identisch
- [ ] Falls Website-Screenshots Tab-Reihenfolge zeigen: aktualisiert

### Dokumentation
- [ ] CHANGELOG.md (Eintrag im Release in dem die Screenshots aktualisiert werden)

---

## Manueller Test

1. Fastlane-Screenshots neu generieren (iOS + Android)
2. Erwartung: Bibliothek/Player in den ersten Screenshots, Timer danach
3. Captions auf den Screenshots passen zur neuen Reihenfolge
4. Website lokal oder im _site-Build oeffnen → FAQ pruefen
5. Erwartung: Erste FAQ-Frage adressiert die Meditations-Bibliothek (Import / Wiedergabe), Timer-Fragen folgen

---

## Referenz

- shared-084 (Tab-Reorder in der App) — Voraussetzung
- shared-040 (App Store Narrativ und Screenshots) — bestehender Screenshot-Rahmen
- shared-078 (Emotionaler Ton App Store + Website) — angrenzende Texterneuerung
- iOS: `ios/fastlane/screenshots/` und `ios/fastlane/metadata/`
- Android: `android/fastlane/metadata/android/`
- Website: `docs/index.html`, `docs/support.html`

---

## Hinweise

- Beim naechsten Release mitveroeffentlichen, nicht zwischendurch — Store-Material wird nur mit Releases ausgerollt
- App-Store-Description (`description.txt`) und Website-Hero sortieren bereits Library vor Timer; diese muessen nicht erneut umgestellt werden, nur auf Konsistenz pruefen
- Wenn der Screenshot-Generator den Meditationen-Tab auswaehlt, muss eine importierte Beispiel-Bibliothek im UI-Test-Setup vorhanden sein (siehe shared-079 Screenshot-Pipeline)
