# Android Release-Testplan

**Typ**: Manueller Testplan, vor jedem Release durchführen
**Dauer**: ca. 30 Minuten
**Gegenstück**: `TEST_PLAN_IOS.md` — gleiche Struktur, gleiche Nummerierung, gleiche Begriffe

---

## Voraussetzungen

- Echtes Android-Gerät (kein Emulator), Ton an, Medienlautstärke mittel
- **Aktuelle Play-Store-Version ist installiert** (für den Upgrade-Test in Abschnitt 0); die neue Version liegt bereit — über einen Test-Track der Play Console oder als gleich signiertes Release-Build für `adb install -r`
- Zwei Test-MP3s im Download-Ordner, je 2–5 Minuten lang, mit Interpret und Titel in den Tags
- Eine weitere MP3/M4A als eigener Hintergrundklang
- Test-Link für den Link-Import: Download-Link eines Vortrags auf audiodharma.org (z. B. `https://www.audiodharma.org/talks/25407/download`) oder ein MP3-Link von tarabrach.com
- Eine einzelne Folge auf podcasts.apple.com im Browser (z. B. aus dem Podcast von Tara Brach)
- Kopfhörer mit Taste (kabelgebunden oder Bluetooth)
- Zweites Telefon für den Anruf-Test

## Was dieser Plan nicht prüft

Automatisierte Tests decken bereits ab: Zustandsautomat des Timers, Intervall- und Vorbereitungslogik,
Such- und Filterregeln, Import-Vorschläge, Regeln des Wiedergabe-Bereichs, Audio-Koordination als Logik
(Unit-Tests) sowie Bildschirme und Navigation (Compose-UI-Tests).

Dieser Plan prüft nur, was dort nicht geht: hörbares Audio auf echtem Gerät, Sperrbildschirm und
Hintergrund, Systeminteraktionen, Barrierefreiheit, Darstellung und den Upgrade-Pfad.
Begriffe nach `dev-docs/reference/glossary.md`.

---

## 0. Vorbereitung und Upgrade-Pfad (~5 Min)

Dieser Abschnitt kommt zuerst, weil er in der **Store-Version** beginnen muss. Die hier gesetzten
Werte nutzen die Abschnitte 1 und 2.

### 0.1 In der Store-Version einrichten
- [ ] Erste Test-MP3 importieren; im Bearbeiten-Blatt „Wiedergabebereich" auf ca. 0:30 bis 1:30 setzen, „Gong am Anfang" und „Gong am Ende" einschalten, speichern
- [ ] Timer-Praxis: Dauer 2 Min, Vorbereitung 10 s, Gong „Klarer Anschlag", Intervall-Gongs an (alle 1 Min), Hintergrundklang „Waldatmosphäre"
- [ ] Unter Hintergrundklang einen eigenen Klang importieren (er erscheint unter „Meine Klänge")
- [ ] Einstellungen: Darstellung „Hell", Vorbereitungszeit für geführte Meditationen an (10 s)

### 0.2 Neue Version darüber installieren
Neue Version über die bestehende installieren — die App vorher **nicht** deinstallieren.
Lehnt `adb install -r` wegen abweichender Signatur ab, über den Test-Track der Play Console installieren.
- [ ] App startet ohne Absturz
- [ ] Bibliothek: Meditation vorhanden, Lehrer und Titel unverändert, Dauer zeigt den Wiedergabe-Bereich (ca. 1:00)
- [ ] Bearbeiten-Blatt: Wiedergabe-Bereich und beide Gong-Schalter erhalten
- [ ] Timer: alle Praxis-Werte aus 0.1 erhalten
- [ ] Eigener Hintergrundklang steht weiter unter „Meine Klänge" und spielt
- [ ] Einstellungen: Darstellung „Hell" und Vorbereitungszeit 10 s erhalten

---

## 1. Kern-Use-Case: Timer bei gesperrtem Bildschirm (~5 Min)

Praxis aus 0.1. Start drücken, **sofort** Bildschirm sperren, Telefon weglegen.

### 1.1 Gongs und Hintergrundklang
- [ ] Nach 10 s Vorbereitung ist der Start-Gong hörbar
- [ ] Danach setzt der Hintergrundklang ein und läuft bei gesperrtem Bildschirm weiter
- [ ] Nach 1 Minute ist der Intervall-Gong hörbar
- [ ] Nach 2 Minuten ist der End-Gong hörbar und klingt vollständig aus; der Hintergrundklang verstummt
- [ ] Nach dem Entsperren erscheint der Abschluss-Bildschirm; „Fertig" führt zurück zum Timer
- [ ] (nur Android) Während der Timer läuft, steht die Benachrichtigung „Meditation läuft" in der Benachrichtigungsleiste; nach dem Ende verschwindet sie

### 1.2 Vibration statt Gong
- [ ] „Start & Ende" auf „Vibration", Dauer 1 Min, starten und sperren: Vibration am Anfang und am Ende auch bei gesperrtem Bildschirm spürbar

Danach „Start & Ende" wieder auf einen Klang stellen.

---

## 2. Kern-Use-Case: Geführte Meditation bei gesperrtem Bildschirm (~4 Min)

Meditation aus 0.1 antippen, abspielen, **sofort** Bildschirm sperren.

### 2.1 Ablauf
- [ ] Die Vorbereitungszeit (10 s) läuft gesperrt ab, danach Start-Gong, danach setzt das Audio bei ca. 0:30 ein (nicht am Dateianfang)
- [ ] Die Wiedergabe endet bei ca. 1:30, der End-Gong ist hörbar und klingt vollständig aus
- [ ] Nach dem Entsperren erscheint der Abschluss-Bildschirm

### 2.2 Steuerung auf dem Sperrbildschirm (zweiter Durchlauf)
- [ ] Sperrbildschirm zeigt Titel und Lehrer
- [ ] Pause und Wiedergabe funktionieren
- [ ] (nur Android) Die Medien-Benachrichtigung zeigt Wiedergabe/Pause und Stopp; Stopp beendet die Wiedergabe
- [ ] Ziehen am Fortschrittsbalken springt hörbar an die gewählte Stelle innerhalb des Wiedergabe-Bereichs

---

## 3. Unterbrechungen und Kopfhörer (~3 Min)

- [ ] Geführte Meditation läuft, Anruf kommt: Audio pausiert; nach dem Auflegen lässt sich die Wiedergabe fortsetzen
- [ ] Timer läuft gesperrt, Anruf annehmen und beenden: der End-Gong ist zum Ende trotzdem hörbar
- [ ] Musik-App spielt, dann Meditation starten: die Musik verstummt, die Meditation ist allein zu hören
- [ ] Mit Kopfhörern: Audio kommt über die Kopfhörer; Kopfhörer-Taste pausiert und setzt die geführte Meditation fort
- [ ] App aus den zuletzt verwendeten Apps wischen und neu starten: kein Absturz, Bibliothek vollständig

---

## 4. Import und Systeminteraktionen (~6 Min)

### 4.1 Dateien
- [ ] „+" in der Bibliothek öffnet die Dateiauswahl; zweite Test-MP3 auswählen: Bearbeiten-Blatt ist mit Lehrer und Titel aus den Tags vorbelegt; nach dem Speichern steht sie in der Liste und spielt
- [ ] (nur Android) Dateien-App: MP3 teilen → Still Moment: Still Moment öffnet sich direkt mit dem Bearbeiten-Blatt
- [ ] (nur Android) Dateien-App: MP3 antippen → „Öffnen mit" Still Moment: Still Moment öffnet sich mit dem Bearbeiten-Blatt

### 4.2 Link und Podcast
- [ ] Chrome: Test-Link teilen → Still Moment: Still Moment öffnet sich direkt, Ladeanzeige, danach Bearbeiten-Blatt; nach dem Speichern spielbar
- [ ] Chrome: auf podcasts.apple.com eine einzelne Folge teilen → Still Moment: Titel der Folge ist vorbelegt; nach dem Speichern spielbar
- [ ] Flugmodus an, Test-Link teilen: Meldung „Gerade nicht erreichbar" mit „Erneut versuchen"; Flugmodus aus, „Erneut versuchen" lädt die Datei

### 4.3 Wege nach außen
- [ ] „Wo finde ich Meditationen?" (Info-Knopf in der Bibliothek): Antippen einer Quelle öffnet den Browser
- [ ] Einstellungen → „App bewerten" öffnet die Google-Play-Seite von Still Moment
- [ ] Einstellungen → „Schreib uns" öffnet eine neue Mail an `hello@stillmoment.app` mit App-Version im Text
- [ ] Einstellungen → „Datenschutz" öffnet die Datenschutzerklärung

---

## 5. Hörbare Auswahl, Vorhören, Zuschnitt (~3 Min)

- [ ] Bibliothek: Meditation lange drücken: Vorhören ist hörbar, ein Fortschrittsregler erscheint; Antippen stoppt
- [ ] Timer → „Start & Ende": Antippen eines Klangs spielt ihn hörbar vor; Lautstärke-Regler ändert die Lautstärke hörbar
- [ ] Timer → „Hintergrundklang": eingebauter und eigener Klang sind beim Vorhören hörbar
- [ ] Bearbeiten-Blatt → „Wiedergabebereich": Wellenform erscheint; Vorhören spielt hörbar; die Griffe lassen sich mit dem Finger genau setzen
- [ ] Player: Ziehen in der Wellenform springt hörbar an die neue Stelle

---

## 6. Darstellung Hell und Dunkel (~3 Min)

Einstellungen → Erscheinungsbild → Darstellung.

- [ ] „Hell": Timer, Bibliothek, Player, Bearbeiten-Blatt, Zuschnitt-Editor und Einstellungen sind gut lesbar; keine fremd gefärbten (rein schwarzen oder weißen) Flächen oder Titel
- [ ] „Dunkel": dieselben Bildschirme ebenso
- [ ] „System": Wechsel des dunklen Designs in den Schnelleinstellungen wirkt sofort, ohne Neustart
- [ ] (nur Android) Status- und Navigationsleiste passen in beiden Modi zum App-Hintergrund und bleiben lesbar

---

## 7. Barrierefreiheit (~4 Min)

### 7.1 TalkBack
- [ ] Timer: Dauer lässt sich mit TalkBack einstellen (Lautstärketasten oder Wischen auf/ab bei fokussiertem Wählrad), der Wert wird angesagt; Start-Knopf ist benannt
- [ ] Bibliothek: Einträge werden mit Titel, Lehrer und Dauer angesagt; Suche und Dauer-Filter sind bedienbar
- [ ] Player: Wiedergabe, Pause und Position sind bedienbar, die Restzeit wird angesagt
- [ ] Import aus 4.1 lässt sich bis zum Speichern mit TalkBack abschließen

### 7.2 Große Schrift und fetter Text
Einstellungen → Bedienungshilfen → Anzeigegröße und Text (Bezeichnung je nach Hersteller).
- [ ] Schriftgröße auf Maximum: Timer, Bibliothek, Player und Einstellungen ohne abgeschnittenen Text; Start-Knopf erreichbar
- [ ] „Fettdruck" an: Texte in der App werden sichtbar kräftiger

---

## 8. Sprache (~1 Min)

- [ ] Gerätesprache Englisch: Timer, Bibliothek, Einstellungen und die Benachrichtigungen sind englisch, nirgends rohe Schlüssel
- [ ] Zurück auf Deutsch: Einzahl und Mehrzahl stimmen — Hinweis unter Intervall-Gongs lautet bei 1 Min „… jede Minute …", bei 2 Min „… alle 2 Minuten …"

---

## Bekannte Limitierungen

1. _____
2. _____

---

## Nach dem Test

Nach erfolgreichem Test weiter mit `RELEASE_GUIDE.md`.

---

## Sign-Off

| Tester | Datum | Version | Ergebnis |
|--------|-------|---------|----------|
| ______ | ______ | ______ | PASS / FAIL |

**Notizen:**

_
