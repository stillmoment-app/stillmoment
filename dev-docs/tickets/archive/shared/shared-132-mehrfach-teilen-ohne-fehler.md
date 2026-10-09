---
id: shared-132
title: "Mehrfaches Teilen an Still Moment: kein Fehler, der zuletzt geteilte Eintrag gewinnt"
status:
  ios: done
  android: done
phase: 4-Polish
priority: hoch
depends_on: []
---

# Ticket shared-132: Mehrfaches Teilen an Still Moment: kein Fehler, der zuletzt geteilte Eintrag gewinnt

**Plan (iOS)**: `dev-docs/tickets/plans/shared-132-ios.md`
**Plan (Android)**: `dev-docs/tickets/plans/shared-132-android.md`

## Was

**Beobachtet:** Auf iOS erscheint „Import fehlgeschlagen“, wenn dieselbe Adresse ein zweites Mal über das Teilen-Menü an Still Moment geteilt wird, bevor die App den ersten Link-Import übernommen hat. Das passiert auch bei zwei verschiedenen Adressen mit gleichem Ende (z. B. `https://www.audiodharma.org/talks/25401/download` und `https://www.audiodharma.org/talks/25402/download`) und bei zweimal derselben geteilten Audiodatei.

**Erwartet:** Mehrfaches Teilen führt nie zu einer Fehlermeldung. Es gilt auf beiden Plattformen dieselbe Regel: Der zuletzt geteilte Eintrag wird importiert, frühere, noch nicht übernommene Einträge entfallen. Derselbe Link oder dieselbe Datei, mehrfach geteilt, ergibt genau einen Import.

**Umstände:** Teilen aus Safari, einem anderen Browser oder der Dateien-App, mehrmals hintereinander, bevor die App den ersten Eintrag übernommen hat. Typisch: versehentlich doppelt getippt.

## Warum

Wer zweimal teilt, bekommt eine Fehlermeldung, obwohl der erste Import ganz normal weiterläuft. Das verunsichert, gerade bei einem nicht-technischen Publikum. Der Link-Import ist ein zentraler Weg in die Bibliothek.

---

## Akzeptanzkriterien

<!-- Gelten fuer BEIDE Plattformen. -->

- [ ] Dieselbe Adresse zweimal geteilt, bevor die App sie übernommen hat: kein „Import fehlgeschlagen“, die Meditation steht danach genau einmal in der Bibliothek.
- [ ] Dieselbe Audiodatei zweimal geteilt: kein Fehler, eine Meditation.
- [ ] `…/talks/25401/download`, dann `…/talks/25402/download` geteilt, bevor die App den ersten übernommen hat: kein Fehler, importiert wird 25402.
- [ ] iOS und Android verhalten sich in diesen drei Fällen gleich.
- [ ] Erhalt: Wird eine Meditation geteilt, die schon in der Bibliothek steht, erscheint weiterhin der Hinweis „Schon da“.
- [ ] Erhalt: Einzelnes Teilen von Link, Podcast-Folge oder Audiodatei funktioniert wie bisher, einschließlich der Fehlermeldungen (nicht erreichbar, keine Aufnahme gefunden, Podcast ohne Folge) und „Erneut versuchen“.
- [ ] Erhalt: Geteilte Einträge, die nie übernommen werden, werden weiterhin nach 24 Stunden weggeräumt.

---

## Manueller Test

1. iOS: Still Moment schließen (nicht im Vordergrund).
2. In Safari `https://www.audiodharma.org/talks/25401/download` an Still Moment teilen, direkt danach ein zweites Mal.
3. Erwartung: Beide Male „Fast geschafft“, kein „Import fehlgeschlagen“.
4. `https://www.audiodharma.org/talks/25402/download` teilen, dann Still Moment öffnen.
5. Erwartung: Ein Bearbeiten-Blatt für 25402. Nach dem Speichern steht nur 25402 neu in der Bibliothek.
6. Android: 25401 teilen und, während er noch lädt, erneut 25401 teilen. Erwartung: ein Import, kein Fehler. Dann während des Ladens 25402 teilen. Erwartung: Importiert wird 25402.

---

## Nicht Teil dieses Tickets

- Mehrere verschiedene geteilte Einträge alle nacheinander importieren (Warteschlange, ein Bearbeiten-Blatt nach dem anderen).

---

## Hinweise

- **„Der zuletzt geteilte gewinnt“ ist eine bewusste Entscheidung des Users.** Eine Warteschlange für mehrere Einträge wäre deutlich aufwendiger: mehrere wartende Einträge, mehrere Bearbeiten-Blätter, Bezug von „Erneut versuchen“. Der Nutzen ist gering, weil man im Normalfall einen Vortrag teilt und ihn dann hört. Auf iOS fordert die Erfolgsmeldung ohnehin dazu auf, Still Moment zu öffnen.
- Laut Recherche verhält sich Android schon so: Ein neuer Link ersetzt den laufenden Download, derselbe Link wird nicht doppelt geladen. Auf Android ist das Ticket also voraussichtlich nur zu prüfen, nicht umzubauen.
- Auf iOS übernimmt die App schon heute nur den neuesten geteilten Eintrag. Fehlerhaft ist das Ablegen in der Teilen-Ansicht, wenn ein gleichnamiger Eintrag noch wartet.
- Bei geteilten Adressen ist der Dateiname oft nichtssagend („download“): 25401 und 25402 sind verschiedene Meditationen.

---

## Ergebnis

- **iOS:** Ursache war `moveItem` auf einen schon vorhandenen Inbox-Namen. Die Ablage liegt jetzt in `ShareInbox` (App- und Extension-Target) und ersetzt einen gleichnamigen wartenden Eintrag atomar (`rename(2)` bzw. `Data.write(.atomic)`). Das Datum einer geteilten Datei wird vor dem Ablegen gesetzt; scheitert das, meldet die Extension einen Fehler statt falschen Erfolg.
- **Android:** Die Annahme „verhält sich schon so“ stimmte nur zum Teil. Chrome teilt mit `NEW_DOCUMENT | MULTIPLE_TASK`, ohne `launchMode="singleTask"` startete jedes Teilen eine eigene Activity mit eigenem Download (am Emulator belegt). Außerdem lief ein abgelöster Download im Hintergrund weiter, und „Abbrechen“ griff danach nicht. Neu: `SharedLinkImport` im `SharedLinkImportViewModel` (überlebt Neuerzeugung der Activity), `singleTask`, `setIntent` in `onNewIntent`.
- **Nebenbefund, mit erledigt:** audiodharma.org liefert manche Vorträge (z. B. 25402) als `binary/octet-stream` aus; beide Plattformen lehnten das seit shared-131 ab. Der Typ steht jetzt auf beiden Akzeptanzlisten.
- **Manuell getestet:** iOS-Simulator (Ticket-Schritte 1–5 in Original-Reihenfolge, „Schon da“, Abspielen von 25402) und Android-Emulator (Schritt 6, „Schon da“, „Abbrechen“, Kaltstart per Teilen, Zurück, Launcher, „Öffnen mit“ zweimal, Benachrichtigung, Dunkelmodus während des Ladens).
- **Bekannte Einschränkung (Android, bewusst nicht behoben):** Teilt man vom Timer-Tab aus und wechselt während des Ladens den Dunkelmodus, wechselt die App danach nicht von selbst in die Bibliothek. Das Bearbeiten-Blatt geht nicht verloren, es erscheint beim Antippen des Meditationen-Tabs.
- **Nicht umgesetzt (Folgetickets):** Teilen während eines laufenden Imports (iOS übernimmt erst beim nächsten Öffnen; Android: Datei während Link lädt), Aufräumen von `cacheDir/dl_*` auf Android, Link ohne Pfad auf iOS (stiller Fehlschlag), lange Dateinamen verdrängen die Dauer im Bearbeiten-Blatt.
