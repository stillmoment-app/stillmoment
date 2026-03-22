# Ticket shared-078: App Store + Website – Emotionaler Ton

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Aufwand**: ~3h (kein Code, nur Texte)
**Phase**: 4-Polish
**Abhaengigkeit**: shared-040 (App Store Narrativ + Screenshots) – kann unabhaengig umgesetzt werden

---

## Was

App Store Texte (iOS + Android) und Website Hero-Text werden neu geschrieben. Subtitle wird funktional mit USP, Promotional Text bekommt das Philosophie-Zitat, Description fuehrt mit Zielgruppe und laesst Privacy als beilaeufiges Vertrauenssignal wirken — nicht als Hauptargument.

## Warum

Aktuell kommunizieren Store und Website *was* die App kann — aber nicht *warum* sie existiert. Feature-Listen konkurrieren auf dem falschen Spielfeld (Headspace hat mehr Features). Die Zielgruppe (ernsthaft Meditierende mit eigenen Lehrern) sucht eine App, die ihren Werten entspricht — kein Tool.

**Wettbewerbsanalyse:** Die grossen Apps (Calm, Headspace, Insight Timer) fuehren mit Social Proof und Keyword-Spam. Nischen-Apps die herausstechen (Oak, Plum Village) fuehren mit Haltung und Identitaet. Still Moment sollte diesem Muster folgen.

**Privacy als Differenzierung:** Still Moment ist die einzige Meditations-App mit Apples "No Data Collected"-Badge. Keine andere App — auch nicht Oak, Plum Village oder Medito — kann das vorweisen. Aber: den durchschnittlichen User interessiert Privacy nicht als Hauptargument. Es wirkt staerker als beilaeufiges Vertrauenssignal ("Ach, die tracken auch nicht") als wenn es geschrien wird.

**Struktur neu:**

| Feld | Inhalt | Zweck |
|------|--------|-------|
| Subtitle | Funktionaler USP + "Kein Abo" | Informiert, spricht jeden an |
| Promotional Text | Philosophie-Zitat (komplett) | Emotionaler Moment, filtert Zielgruppe |
| Description vor "Mehr" | Zielgruppen-Satz | Wer sich angesprochen fuehlt, tippt Mehr |
| Description nach "Mehr" | Features → Privacy | Informiert + baut Vertrauen auf |

**Struktur alt:** USP → Feature-Bulletpoints → Privacy → emotionaler Abschluss

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS (App Store) | [ ] | - |
| Android (Play Store) | [ ] | - |
| Website (index.html) | [ ] | - |

---

## Textvorschlaege

### Subtitle (iOS, max 30 Zeichen)

DE: `Deine MP3-Meditationen. Kein Abo.` (34 — muss gekuerzt werden, z.B. "Deine MP3s. Kein Abo." = 22)
EN: `Your meditation MP3s. No sub.` (29) oder `Your MP3s. No subscription.` (28)

### Promotional Text (iOS, max 170 Zeichen)

DE:
> Meditiere nicht, um dich zu verbessern. Tue es als Akt der Liebe — der tiefen, warmen Freundschaft mit dir selbst.

(115 Zeichen)

EN:
> Don't meditate to improve yourself. Do it as an act of love — of deep, warm friendship with yourself.

(103 Zeichen)

### Description (iOS)

**Vor "Mehr" (erste 3 Zeilen):**

DE:
> Still Moment ist fuer Menschen, die bereits eine Praxis haben — und eine App suchen, die sich zuruecknimmt.

EN:
> Still Moment is for people who already have a practice — and want an app that steps back.

**Nach "Mehr":**

DE:
> Importiere deine gefuehrten Meditationen als MP3 — oder nutze den stillen Timer mit Klangschalen und Intervall-Gongs.
>
> Kein Tracking. Keine Werbung. Alles bleibt auf deinem Geraet.
>
> ◦ Eigene MP3s importieren und verwalten
> ◦ Stille Meditation mit konfigurierbarem Timer
> ◦ Klangschalen und Intervall-Gongs
> ◦ Kein Account, keine Cloud, kein Abo

EN:
> Import your guided meditations as MP3 — or use the silent timer with singing bowls and interval gongs.
>
> No tracking. No ads. Everything stays on your device.
>
> ◦ Import and manage your own MP3s
> ◦ Silent meditation with configurable timer
> ◦ Singing bowls and interval gongs
> ◦ No account, no cloud, no subscription

### Description (Android — SEO-relevant)

Android indexiert die Full Description fuer die Suche. Deshalb zusaetzlich am Ende:

> Meditation App, Timer, MP3, Klangschale, Singing Bowl, Gong, Guided Meditation, Silent Meditation, Achtsamkeit, Mindfulness, Offline, Private, No Tracking

---

## Akzeptanzkriterien

### App Store Texte (iOS)

- [ ] Subtitle: funktionaler USP mit "Kein Abo" (kein Keyword-Spam)
- [ ] Promotional Text: Philosophie-Zitat komplett (nicht gekuerzt)
- [ ] Description beginnt mit Zielgruppen-Satz (nicht mit Zitat)
- [ ] Privacy als Vertrauenssignal nach Features, nicht als Opener
- [ ] Feature-Liste kompakt am Ende
- [ ] DE + EN lokalisiert

### Play Store Texte (Android)

- [ ] Short Description: analog zu iOS Subtitle
- [ ] Full Description: gleiche Struktur wie iOS, aber mit keyword-reicher Sektion am Ende (Google indexiert Description fuer Suche, Apple nicht)
- [ ] DE + EN lokalisiert

### Website (index.html)

- [ ] Hero-Tagline ersetzt "Meditation with your own content." durch etwas das den Geist transportiert
- [ ] Hero-Subtitle weg von Produktdatenblatt-Sprache
- [ ] Zitat sichtbar auf der Seite — entweder im Hero oder als eigene Section
- [ ] DE + EN lokalisiert

### Qualitaet

- [ ] Kein Marketing-Kitsch ("Transform your life", "Find inner peace") — authentisch und ruhig
- [ ] Texte klingen wie ein Mensch, nicht wie ein Produkt
- [ ] Gegenlesen: kein Denglisch, keine Rechtschreibfehler

### Dokumentation

- [ ] Fastlane Metadaten aktualisiert: `ios/fastlane/metadata/de-DE/description.txt`, `en-US/description.txt`
- [ ] Android Play Store Listing aktualisiert (manuell in Play Console oder via Fastlane)

---

## Manueller Test

1. App Store Connect → Vorschau der Beschreibung
2. Pruefe: Steht das Zitat im Promotional Text (nicht in der Description)?
3. Pruefe: Beginnt die Description mit dem Zielgruppen-Satz?
4. Pruefe: Privacy kommt nach Features, nicht davor?
5. Play Store → Pruefe: Keyword-Sektion am Ende vorhanden?
6. Website aufrufen → Hero: Transportiert der erste Text Stimmung statt Funktion?
7. DE + EN wechseln — beide Texte konsistent?

---

## Zitat-Text (Referenz)

> Meditiere nicht, um dich zu verbessern oder zu erloesen.\
> Tue es als Akt der Liebe —\
> der tiefen, warmen Freundschaft mit dir selbst.

EN:
> Don't meditate to improve yourself or to find redemption.\
> Do it as an act of love —\
> of deep, warm friendship with yourself.

---

## Hinweise

- Das Zitat ist kein Fremdtext — es ist die selbst formulierte App-Philosophie (keine Urheberrechtsfragen)
- App Store erlaubt kein Markdown/Kursiv in Beschreibungen — Zitat als eigenen Absatz setzen
- Promotional Text (iOS, max 170 Zeichen) kann jederzeit ohne Review geaendert werden
- iOS App Store indexiert die Description NICHT fuer die Suche — Suchrelevanz kommt aus Name, Subtitle und Keywords (hidden). Description kann rein emotional sein
- Android Play Store indexiert die Full Description — deshalb keyword-reiche Sektion am Ende noetig
- Still Moment hat Apples "No Data Collected"-Badge (PrivacyInfo.xcprivacy: leere Arrays). Keine andere Meditations-App hat das — aber nicht als Hauptargument verwenden
- shared-040 deckt Screenshots + Metadaten-Struktur ab; dieses Ticket fokussiert nur auf Texte und Ton
