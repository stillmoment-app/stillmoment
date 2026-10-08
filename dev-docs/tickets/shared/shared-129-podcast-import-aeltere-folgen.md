# Ticket shared-129: Podcast-Import auch fuer aeltere Folgen

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Komplexitaet**: Die Folge muss ueber ihren Titel im Feed des Anbieters gefunden werden, weil Apples Folgen-ID dort nicht vorkommt. Risiken: falsche Zuordnung bei gleichen Titeln (muss zur Fehlermeldung statt zum falschen Import fuehren), grosse Feeds (mehrere MB), und die Titelquelle haengt an Apples Webseite.
**Phase**: 3-Feature

---

## Was

Eine geteilte Apple-Podcasts-Folge soll sich auch dann importieren lassen, wenn sie nicht zu den neuesten Folgen des Podcasts gehoert. Fuer den Nutzer gibt es keinen Unterschied zu neuen Folgen: gleiches Ladefenster, gleiche Vorschlaege, gleiche Meldungen.

## Warum

Apples Lookup-Dienst liefert hoechstens die 200 neuesten Folgen eines Podcasts. Beim Tara-Brach-Podcast (ueber 1.600 Folgen) reicht das nur bis etwa Oktober 2024. Gerade bei Meditationen sind aeltere Folgen oft die wertvollsten — zeitlose Inhalte, die man ueber Jahre wieder hoert. Ohne diesen Weg scheitert ein grosser Teil der geteilten Folgen.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | shared-128    |
| Android   | [ ]    | shared-128    |

---

## Akzeptanzkriterien

<!-- Kriterien gelten fuer BEIDE Plattformen -->

### Feature (beide Plattformen)
- [ ] Eine geteilte Folge, die nicht unter den neuesten Folgen ist, wird importiert (z.B. Tara Brach, "Meditation: Being the Ocean…", Januar 2019)
- [ ] Die Folge wird nur importiert, wenn genau eine Folge im Feed exakt den gesuchten Titel traegt; bei keinem oder mehreren Treffern erscheint "Diese Folge kann leider nicht uebernommen werden" — nie eine falsche Folge
- [ ] Die Audiodatei kommt aus dem Feed des Anbieters, nicht von Apple
- [ ] Vorschlaege fuer Titel und Lehrer:in wie in shared-128
- [ ] Neue Folgen laufen weiter ueber den bisherigen Weg; Apples Webseite und der Feed werden nur abgerufen, wenn die Folge dort nicht gefunden wurde
- [ ] Abbrechen im Ladefenster bricht auch diese zusaetzlichen Abrufe ab
- [ ] Keine neuen Meldungen oder Texte gegenueber shared-128

### Tests
- [ ] Unit Tests iOS: eindeutiger Treffer, kein Treffer, mehrere gleiche Titel, Titel mit Sonderzeichen/HTML-Entities, Feed ohne Autor
- [ ] Unit Tests Android: dieselben Faelle

### Dokumentation
- [ ] CHANGELOG.md

---

## Manueller Test

1. In Apple Podcasts beim Tara-Brach-Podcast weit zurueckscrollen (2019 oder aelter), Folge teilen → Still Moment
2. Erwartung: Ladefenster, dann Bearbeiten-Dialog mit genau dieser Folge; Wiedergabe stimmt mit der Folge in Apple Podcasts ueberein
3. Eine aktuelle Folge teilen → Erwartung: unveraendert wie in shared-128
4. Identisch auf Android mit einem per Messenger geteilten Link

---

## Hinweise

- Der Folgentitel kommt aus der Link-Vorschau der Apple-Webseite zur Folge (`og:title` — dieselbe Angabe, die Messenger fuer Link-Vorschauen lesen). Live verifiziert 2026-10-08: vorhanden auch fuer Folgen von 2019.
- Die Seite enthaelt auch einen internen Datenblock mit der MP3-Adresse. **Den nicht verwenden**: undokumentiert, kann sich jederzeit aendern, und Apples Nutzungsbedingungen verbieten Page-Scraping. Bewusste Entscheidung: nur die Standard-Vorschauangabe, einmalig und vom Nutzer ausgeloest.
- Die Feed-Adresse steht in der Lookup-Antwort (`feedUrl`). Die Folgen-ID aus dem Link kommt im Feed nicht vor; Zuordnung deshalb ueber den exakten Titel (`<item><title>`).
- Der Kurzname im geteilten Link ist der Podcast-Name, nicht der Folgentitel — als Titelquelle ungeeignet.
- Weder Podcast Index noch Listen Notes koennen eine Apple-Folgen-ID aufloesen (Recherche 2026-10-08).
- Entscheidungen und Recherche: `dev-docs/concepts/podcast-import.md`
