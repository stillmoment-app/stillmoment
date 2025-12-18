# Ticket shared-{NNN}: {Titel}

**Status**: [ ] TODO | [~] IN PROGRESS | [x] DONE
**Prioritaet**: KRITISCH | HOCH | MITTEL | NIEDRIG
**Aufwand**: iOS ~Xh + Android ~Xh
**Phase**: 1-Quick Fix | 2-Architektur | 3-Feature | 4-Polish | 5-QA

---

## Beschreibung

{Kurze Beschreibung des plattformuebergreifenden Features}

---

## Plattform-Status

| Plattform | Status | Aufwand | Abhaengigkeit |
|-----------|--------|---------|---------------|
| iOS       | [ ]    | ~Xh     | -             |
| Android   | [ ]    | ~Xh     | -             |

---

## Gemeinsame Akzeptanzkriterien

- [ ] Kriterium 1 (beide Plattformen)
- [ ] Kriterium 2 (beide Plattformen)

### Tests (PFLICHT)
- [ ] iOS: Unit Tests geschrieben/aktualisiert
- [ ] iOS: Bestehende Tests weiterhin gruen
- [ ] Android: Unit Tests geschrieben/aktualisiert
- [ ] Android: Bestehende Tests weiterhin gruen
- [ ] Manuelle Tests auf beiden Plattformen

### Dokumentation
- [ ] CHANGELOG.md: Feature-Eintrag (beide Plattformen)

---

## iOS-Subtask

### Akzeptanzkriterien (iOS)
- [ ] iOS-spezifisches Kriterium 1
- [ ] iOS-spezifisches Kriterium 2

### Betroffene Dateien (iOS)
- `ios/StillMoment/...`

### Technische Details (iOS)

```swift
// iOS-Code Beispiel
```

### Testanweisungen (iOS)

```bash
cd ios && make test-unit
```

---

## Android-Subtask

### Akzeptanzkriterien (Android)
- [ ] Android-spezifisches Kriterium 1
- [ ] Android-spezifisches Kriterium 2

### Betroffene Dateien (Android)
- `android/app/src/main/kotlin/...`

### Technische Details (Android)

```kotlin
// Android-Code Beispiel
```

### Testanweisungen (Android)

```bash
cd android && ./gradlew test
```

---

## UX-Konsistenz

{Anforderungen fuer konsistentes Verhalten auf beiden Plattformen}

| Aktion | iOS | Android |
|--------|-----|---------|
| ... | ... | ... |
