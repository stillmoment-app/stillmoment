# App Store Release Plan - Still Moment v1.0

Dieser Plan führt Schritt für Schritt durch die erstmalige Veröffentlichung im App Store.

## Status-Übersicht

| Phase | Status | Beschreibung |
|-------|--------|--------------|
| 1. Sicherheits-Audit | ⬜ | Secrets & sensible Daten prüfen |
| 2. Code-Qualität | ⬜ | Tests, Linting, Coverage |
| 3. App-Konfiguration | ⬜ | Version, Bundle ID, Icons |
| 4. Privacy & Legal | ⬜ | Datenschutz, Nutzungsbedingungen |
| 5. App Store Connect | ⬜ | Account, App-Eintrag erstellen |
| 6. Metadata | ⬜ | Beschreibung, Keywords, Screenshots |
| 7. Build & Upload | ⬜ | Archive erstellen, hochladen |
| 8. Review & Release | ⬜ | Prüfung, Freigabe |

---

## Phase 1: Sicherheits-Audit ⬜

### 1.1 Secrets-Scan durchführen
```bash
# Pre-commit hook prüft bereits auf Secrets
git diff --cached | grep -E "(password|secret|api_key|token)"

# Manuell alle tracked Files prüfen
git ls-files | xargs grep -l -E "(DEVELOPMENT_TEAM|@icloud.com|password=)" 2>/dev/null
```

**Aktueller Status:**
- ✅ `.gitignore` enthält Secrets-Patterns (`*.mobileprovision`, `*.p12`, `.env`, `secrets.json`)
- ✅ `Local.xcconfig` (mit Team ID) ist gitignored
- ✅ Git-Commits nutzen anonyme GitHub-Email
- ✅ `DEVELOPMENT_TEAM` ist NICHT in `project.pbxproj` (wird via xcconfig geladen)
- ✅ Keine API-Keys oder Passwörter im Code gefunden
- ⚠️ `token` in `AudioPlayerService.swift` ist nur eine lokale Variable (kein Secret)

### 1.2 Checkliste
- [ ] `git log` auf persönliche Emails prüfen
- [ ] Keine API-Keys/Secrets in Swift-Dateien
- [ ] Keine Testdaten mit echten Nutzerdaten
- [ ] Screenshots enthalten keine persönlichen Daten

---

## Phase 2: Code-Qualität ⬜

### 2.1 Qualitätsprüfungen
```bash
make check              # Format + Lint + Localization
make test               # Alle Tests (Unit + UI) + Coverage
```

**Aktueller Status:**
- ✅ `make check` bestanden (Format, Lint, Lokalisierung)
- ✅ Unit-Tests bestanden
- [ ] UI-Tests ausführen
- [ ] Coverage ≥80% verifizieren

### 2.2 Checkliste
- [ ] Keine SwiftLint-Warnungen
- [ ] Keine Compiler-Warnungen
- [ ] Alle Tests grün
- [ ] Coverage-Ziel erreicht

---

## Phase 3: App-Konfiguration ⬜

### 3.1 Version & Build
**Aktuell im Projekt:**
- Version: `1.0` (MARKETING_VERSION)
- Build: `1` (CURRENT_PROJECT_VERSION)
- Bundle ID: `com.stillmoment.StillMoment`

### 3.2 Checkliste
- [ ] Version 1.0.0 korrekt gesetzt
- [ ] Build Number für Release (z.B. 1)
- [ ] Bundle ID registriert in Apple Developer Portal
- [ ] App Icon vorhanden (1024x1024) ✅

### 3.3 Info.plist Prüfung
**Aktuell konfiguriert:**
- ✅ `UIBackgroundModes`: audio
- ✅ `NSUserNotificationsUsageDescription`: Vorhanden
- ✅ `NSPrivacyPolicyURL`: https://stillmoment-app.github.io/stillmoment/privacy.html
- ✅ `NSHumanReadableContactURL`: Support-URL

**Noch zu prüfen:**
- [ ] Privacy URLs erreichbar?
- [ ] Privacy Policy existiert?

---

## Phase 4: Privacy & Legal ⬜

### 4.1 Datenschutzerklärung
URL: https://stillmoment-app.github.io/stillmoment/privacy.html

**Checkliste:**
- [ ] Privacy Policy auf Website veröffentlicht
- [ ] Deutsche + Englische Version
- [ ] Beschreibt Datenerfassung (keine, nur lokal)
- [ ] Kontaktmöglichkeit enthalten

### 4.2 App Privacy Details (App Store)
Still Moment sammelt **keine** Nutzerdaten:
- Keine Analytics
- Keine Tracking
- Keine Netzwerkverbindungen
- Alle Daten lokal (UserDefaults, lokale Dateien)

**App Store Angabe:** "Data Not Collected"

---

## Phase 5: App Store Connect ⬜

### 5.1 Voraussetzungen
- [ ] Apple Developer Program Mitgliedschaft ($99/Jahr)
- [ ] App Store Connect Zugang
- [ ] Distribution Certificate erstellt
- [ ] App Store Provisioning Profile erstellt

### 5.2 App-Eintrag erstellen
1. App Store Connect → Apps → "+"
2. Plattform: iOS
3. Name: "Still Moment"
4. Primary Language: Deutsch
5. Bundle ID: `com.stillmoment.StillMoment`
6. SKU: `stillmoment-ios-1`

---

## Phase 6: Metadata ⬜

### 6.1 App-Informationen

**Deutscher Text:**
```
Name: Still Moment
Untertitel: Meditations-Timer

Beschreibung:
Still Moment ist dein warmherziger Begleiter für die tägliche Meditationspraxis.

Funktionen:
• Flexibler Timer von 1-60 Minuten
• Sanfte Klangschalen-Gongs zum Start und Ende
• Optionale Intervall-Gongs (alle 3, 5 oder 10 Minuten)
• Beruhigende Hintergrundklänge (Stille oder Waldatmosphäre)
• Geführte Meditationen importieren und abspielen
• Vollständige Hintergrund-Unterstützung
• VoiceOver-optimiert für Barrierefreiheit

Keine Werbung. Keine Abonnements. Keine Datensammlung.
Einfach meditieren.

Keywords: meditation,timer,achtsamkeit,entspannung,ruhe,gong,klangschale,mindfulness
```

**Englischer Text:**
```
Name: Still Moment
Subtitle: Meditation Timer

Description:
Still Moment is your warmhearted companion for daily meditation practice.

Features:
• Flexible timer from 1-60 minutes
• Gentle singing bowl gongs at start and end
• Optional interval gongs (every 3, 5, or 10 minutes)
• Calming background sounds (silence or forest ambience)
• Import and play guided meditations
• Full background audio support
• VoiceOver optimized for accessibility

No ads. No subscriptions. No data collection.
Just meditate.

Keywords: meditation,timer,mindfulness,relaxation,calm,gong,singing bowl,zen
```

### 6.2 Kategorie & Altersfreigabe
- **Primäre Kategorie:** Health & Fitness
- **Sekundäre Kategorie:** Lifestyle
- **Altersfreigabe:** 4+ (keine bedenklichen Inhalte)

### 6.3 Screenshots
**Vorhanden in `docs/images/screenshots/`:**

| Screenshot | DE | EN |
|------------|----|----|
| Timer (Hauptansicht) | ✅ | ✅ |
| Timer (läuft) | ✅ | ✅ |
| Timer (pausiert) | ✅ | ✅ |
| Einstellungen | ✅ | ✅ |
| Bibliothek | ✅ | ✅ |
| Player | ✅ | ✅ |

**App Store Anforderungen:**
- iPhone 6.7" Display (iPhone 16 Plus): Mindestens 3 Screenshots
- Format: 1290 x 2796 px (oder 2796 x 1290 px landscape)

---

## Phase 7: Build & Upload ⬜

### 7.1 Vor dem Archive
```bash
# Finale Qualitätsprüfung
make check
make test

# Clean Build
rm -rf build/
```

### 7.2 Archive erstellen (Xcode)
1. Gerät auswählen: "Any iOS Device (arm64)"
2. Product → Archive
3. Warten bis Build fertig

### 7.3 Upload zu App Store Connect
1. Window → Organizer
2. Archive auswählen → "Distribute App"
3. "App Store Connect" → Next
4. "Upload" → Next
5. Signing-Optionen prüfen → Upload

### 7.4 Checkliste
- [ ] Archive erfolgreich erstellt
- [ ] Keine Compiler-Warnungen
- [ ] Upload erfolgreich
- [ ] Build in App Store Connect sichtbar

---

## Phase 8: Review & Release ⬜

### 8.1 Zur Prüfung einreichen
1. App Store Connect → App auswählen
2. Build hinzufügen (hochgeladener Build)
3. Alle Metadata ausgefüllt
4. Screenshots hochgeladen
5. "Add for Review"
6. "Submit to App Review"

### 8.2 Review-Prozess
- **Typische Dauer:** 24-48 Stunden (manchmal länger)
- **Status prüfen:** App Store Connect → Activity

### 8.3 Mögliche Ablehnungsgründe
- [ ] Background Audio ohne legitimen Use-Case → Wir haben kontinuierlichen Sound
- [ ] Fehlende Privacy Policy → URL in Info.plist
- [ ] Screenshots nicht repräsentativ → Echte App-Screenshots
- [ ] Incomplete Metadata → Alles ausgefüllt

### 8.4 Nach Genehmigung
- [ ] Release-Datum wählen (sofort oder geplant)
- [ ] "Release This Version"
- [ ] App ist im App Store! 🎉

---

## Nächste Schritte

Wir arbeiten die Phasen nacheinander ab. Starte mit:

1. **Phase 1**: Sicherheits-Audit finalisieren
2. **Phase 4**: Privacy Policy erstellen/prüfen
3. **Phase 5**: App Store Connect einrichten

Sag Bescheid, wenn du bereit bist!
