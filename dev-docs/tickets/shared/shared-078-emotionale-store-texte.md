# Ticket shared-078: App Store + Website – Emotionaler Ton

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Aufwand**: ~2h (kein Code, nur Texte)
**Phase**: 4-Polish
**Abhaengigkeit**: shared-040 (App Store Narrativ + Screenshots) – kann unabhaengig umgesetzt werden

---

## Was

App Store Beschreibung (iOS + Android) und Website Hero-Text werden neu geschrieben: Das Philosophie-Zitat als emotionaler Opener, danach ein Satz zum USP, dann Privacy. Keine Feature-Listen.

## Warum

Aktuell kommunizieren Store und Website *was* die App kann — aber nicht *warum* sie existiert. Feature-Listen konkurrieren auf dem falschen Spielfeld (Headspace hat mehr Features). Die Zielgruppe (ernsthaft Meditierende mit eigenen Lehrern) sucht eine App, die ihren Werten entspricht — kein Tool. Das Philosophie-Zitat trifft diesen Geist in zwei Sätzen. Wer es liest und nickt, ist die richtige Person.

Struktur neu: **Geist → USP (1 Satz) → Privacy (1 Satz)**
Struktur alt: USP → Feature-Bulletpoints → Privacy → emotionaler Abschluss

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS (App Store) | [ ] | - |
| Android (Play Store) | [ ] | - |
| Website (index.html) | [ ] | - |

---

## Akzeptanzkriterien

### App Store Texte (iOS + Android)

- [ ] Langbeschreibung beginnt mit dem Philosophie-Zitat (kursiv oder als Absatz, kein Bulletpoint)
- [ ] Danach: 1 Satz USP ("Importiere deine eigenen Meditationen als MP3...")
- [ ] Danach: 1 Satz Privacy ("Kein Tracking, keine Werbung, kein Abo — alles bleibt auf deinem Gerät")
- [ ] Keine Feature-Listen mit Bulletpoints mehr (oder stark reduziert, ganz unten)
- [ ] Promotional Text (iOS): Zitat als Kurzform oder leer lassen
- [ ] Subtitle (iOS): unveraendert oder klarer USP-Fokus
- [ ] DE + EN lokalisiert

### Website (index.html)

- [ ] Hero-Tagline ersetzt "Meditation with your own content." durch etwas das den Geist transportiert
- [ ] Hero-Subtitle nicht mehr "Your own MP3s or silent meditation with timer – tailored to your preferences." (Produktdatenblatt-Sprache)
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
2. Pruefe: Beginnt die Beschreibung mit dem Zitat?
3. Pruefe: Gibt es noch Feature-Bulletpoint-Listen?
4. Website aufrufen → Hero: Transportiert der erste Text Stimmung statt Funktion?
5. DE + EN wechseln — beide Texte konsistent?

---

## Zitat-Text (Referenz)

> Meditiere nicht, um dich zu verbessern oder zu erlösen.\
> Tue es als Akt der Liebe —\
> der tiefen, warmen Freundschaft mit dir selbst.

EN:
> Don't meditate to improve yourself or to find redemption.\
> Do it as an act of love —\
> of deep, warm friendship with yourself.

---

## Hinweise

- Das Zitat ist kein Fremdtext — es ist die selbst formulierte App-Philosophie (keine Urheberrechtsfragen)
- App Store erlaubt kein Markdown/Kursiv in Beschreibungen — Zitat als eigenen Absatz setzen, Zeilenumbrüche durch Leerzeilen
- Promotional Text (iOS, max 170 Zeichen) kann jederzeit ohne Review geaendert werden — ideal zum Testen ob das Zitat als Kurzversion funktioniert
- shared-040 deckt Screenshots + Metadaten-Struktur ab; dieses Ticket fokussiert nur auf Texte und Ton
