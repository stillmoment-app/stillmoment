# Android Play Store - Plattform-spezifisch

Android-spezifische Informationen für Google Play Console.

> **Gemeinsame Texte** (Beschreibung, Release Notes, Screenshots) siehe: `STORE_CONTENT_SHARED.md`

**Zuletzt aktualisiert:** 2026-01-09

---

## Kategorie & Rating

| Feld | Wert |
|------|------|
| **Kategorie** | Gesundheit & Fitness |
| **Inhaltsfreigabe** | PEGI 3 / USK 0 |
| **Preis** | Kostenlos |

---

## Data Safety Fragebogen

### Datenerfassung

| Frage | Antwort |
|-------|---------|
| Sammelt die App Nutzerdaten? | Nein |
| Teilt die App Daten mit Dritten? | Nein |
| Werden Daten verschlüsselt übertragen? | N/A (keine Netzwerknutzung) |
| Können Nutzer Löschung beantragen? | N/A (keine Daten gespeichert) |

### Lokale Datenspeicherung

| Datentyp | Gespeichert? | Zweck |
|----------|--------------|-------|
| Timer-Einstellungen | Ja (lokal) | App-Präferenzen |
| Importierte Meditationen | Ja (lokal) | Wiedergabe |
| Analytics/Tracking | Nein | - |
| Crash-Reports | Nein | - |

---

## Content Rating Fragebogen

Erwartete Antworten für PEGI 3 / USK 0:

| Kategorie | Antwort |
|-----------|---------|
| Gewalt | Nein |
| Sexuelle Inhalte | Nein |
| Glücksspiel | Nein |
| Drogen | Nein |
| Nutzergenerierte Inhalte | Nein |
| In-App-Käufe | Nein |
| Werbung | Nein |
| Standortzugriff | Nein |

---

## Grafiken

### App-Icon (512x512 PNG)

Exportieren aus: `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.webp`

**Anforderungen:**
- 512 x 512 Pixel
- PNG-Format
- Ohne Alphakanal (keine Transparenz)
- Max. Dateigröße: 1 MB

### Feature-Grafik (1024x500 PNG) - Optional

**Empfehlung:**
- App-Name "Still Moment" prominent
- Warme Erdtöne passend zum App-Design
- Einfaches, meditatives Motiv

### Screenshot-Anforderungen

- Mindestens 2, empfohlen 4-8
- JPEG oder PNG (24-bit, kein Alpha)
- Mindestgröße: 320px
- Maximalgröße: 3840px
- Seitenverhältnis: 16:9 oder 9:16

---

## Keystore-Erstellung

```bash
keytool -genkey -v -keystore stillmoment-upload.keystore \
  -alias stillmoment -keyalg RSA -keysize 2048 -validity 10000
```

**Wichtig:**
- Passwort im Passwort-Manager speichern
- Keystore-Datei sicher aufbewahren (Backup!)
- NIEMALS ins Git-Repository committen

### keystore.properties (Vorlage)

Erstelle `android/keystore.properties`:

```properties
storeFile=../stillmoment-upload.keystore
storePassword=DEIN_PASSWORT
keyAlias=stillmoment
keyPassword=DEIN_PASSWORT
```

---

## Build-Befehl

```bash
cd android
./gradlew bundleRelease
```

**Output:** `android/app/build/outputs/bundle/release/app-release.aab`

---

## Play Console Checklist

### Vor dem Upload
- [ ] Upload-Keystore erstellt und sicher gespeichert
- [ ] keystore.properties erstellt
- [ ] Release-Bundle gebaut: `./gradlew bundleRelease`
- [ ] Bundle auf Gerät getestet
- [ ] Screenshots erstellt (min. 2)
- [ ] App-Icon 512x512 exportiert

### Im Play Console
- [ ] App-Eintrag erstellt
- [ ] Store-Beschreibung DE + EN eingegeben (siehe SHARED)
- [ ] Screenshots hochgeladen
- [ ] App-Icon hochgeladen
- [ ] Content Rating ausgefüllt
- [ ] Data Safety ausgefüllt
- [ ] Privacy Policy URL: https://stillmoment-app.github.io/stillmoment/privacy.html
- [ ] AAB-Bundle hochgeladen
- [ ] Release-Notes eingegeben (siehe SHARED)
- [ ] Zur Überprüfung eingereicht
