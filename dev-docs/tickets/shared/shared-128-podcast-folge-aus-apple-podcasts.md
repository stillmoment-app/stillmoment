# Ticket shared-128: Podcast-Folge aus Apple Podcasts importieren

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Komplexitaet**: Der Import-Weg (Teilen → Ladefenster → Bearbeiten-Dialog) existiert schon; neu ist das Aufloesen eines Apple-Podcasts-Links zur Audiodatei. Risiken: Apples Lookup-Dienst ist undokumentiert begrenzt (max. 200 neueste Folgen, teils weniger), und ob Still Moment im Teilen-Menue von Apple Podcasts erscheint, ist nur auf einem echten Geraet pruefbar.
**Phase**: 3-Feature

---

## Was

Wer in Apple Podcasts eine einzelne Folge teilt und Still Moment waehlt, bekommt diese Folge als Meditation in die Bibliothek — mit Folgentitel und Autor als Vorschlag im gewohnten Bearbeiten-Dialog. Gleiches gilt, wenn ein Apple-Podcasts-Folgenlink auf anderem Weg geteilt wird (z.B. aus Messenger oder Browser), auf iOS und Android.

## Warum

Es gibt viele gute Meditationen in Podcasts (z.B. Tara Brach, "Achtsam" von Deutschlandfunk Nova). Podcasts werden damit zu einer neuen Quelle fuer die Bibliothek: Entdeckt wird in der Podcast-App, uebernommen per Teilen. Heute scheitert ein geteilter Apple-Podcasts-Link mit "Keine Aufnahme gefunden", weil der Link auf eine Webseite zeigt und nicht auf die Audiodatei.

---

## Plattform-Status

| Plattform | Status | Abhaengigkeit |
|-----------|--------|---------------|
| iOS       | [ ]    | shared-127    |
| Android   | [ ]    | shared-127    |

---

## Akzeptanzkriterien

<!-- Kriterien gelten fuer BEIDE Plattformen, sofern nicht anders markiert -->

### Vorab-Pruefung (iOS, echtes Geraet)
- [ ] Verifiziert und im Ticket festgehalten: Still Moment erscheint im Teilen-Menue einer Folge in Apple Podcasts, und was dabei uebergeben wird. Falls nicht: Ticket stoppen und Vorgehen neu klaeren

### Feature (beide Plattformen)
- [ ] Ein geteilter Apple-Podcasts-Folgenlink einer der neuesten Folgen fuehrt zum bekannten Ladefenster und danach zum Bearbeiten-Dialog
- [ ] Bearbeiten-Dialog schlaegt als Titel den Folgentitel vor, als Lehrer:in den Autor des Podcasts; fehlt der Autor, den Namen des Podcasts
- [ ] Nach dem Speichern ist die Folge eine ganz normale Meditation und spielt ohne Internet ab
- [ ] Die Audiodatei wird direkt beim Anbieter des Podcasts geladen
- [ ] Abbrechen im Ladefenster bricht auch die Suche nach der Folge ab; es entsteht kein Eintrag
- [ ] Links aus allen Laender-Varianten von Apple Podcasts (z.B. `/de/`, `/us/`) funktionieren
- [ ] Netzwerkzugriffe nur nach einer Teilen-/Import-Aktion des Nutzers, ohne Geraete- oder Nutzerkennungen
- [ ] Ladefenster unveraendert (keine neuen Texte, keine Fortschrittsanzeige)

### Fehlerfaelle — genau drei Meldungen
- [ ] Link auf einen ganzen Podcast (ohne einzelne Folge): Hinweis, eine einzelne Folge zu teilen
- [ ] Keine Internetverbindung oder Zeitueberschreitung: Hinweis, es spaeter erneut zu versuchen (bestehende Meldung des Link-Imports, falls passend)
- [ ] Alles andere — Folge nicht gefunden (auch aeltere Folgen bis shared-129), Bezahl-/Abo-Folge, Video-Folge, Datei beim Anbieter nicht mehr vorhanden, unerwartete Antwort: "Diese Folge kann leider nicht uebernommen werden"
- [ ] Nie stilles Scheitern, keine technischen Begriffe in den Meldungen
- [ ] Lokalisiert (DE + EN)
- [ ] Visuell konsistent zwischen iOS und Android

### Tests
- [ ] Unit Tests iOS: Erkennen von Folgen- vs. Podcast-Links (inkl. Laender-Varianten), Finden der Folge in der Lookup-Antwort, Vorschlaege fuer Titel/Lehrer:in inkl. fehlendem Autor, Zuordnung jedes Fehlerfalls zu einer der drei Meldungen
- [ ] Unit Tests Android: dieselben Faelle

### Dokumentation
- [ ] CHANGELOG.md
- [ ] GLOSSARY.md: Begriff fuer den Podcast-Import (Abgrenzung zum Link-Import)
- [ ] `dev-docs/concepts/podcast-import.md`: Ergebnis der Vorab-Pruefung nachtragen

---

## Manueller Test

1. iOS: In Apple Podcasts eine aktuelle Folge eines Meditations-Podcasts oeffnen (z.B. "Achtsam", Deutschlandfunk Nova) → Teilen → Still Moment
2. Erwartung: Ladefenster, dann Bearbeiten-Dialog mit Folgentitel und Autor; nach Speichern spielt die Folge im Flugmodus ab
3. Android: Denselben Folgenlink per Messenger an sich selbst schicken → Link teilen → Still Moment
4. Erwartung: identisches Verhalten
5. Einen ganzen Podcast teilen → Hinweis "einzelne Folge teilen"
6. Im Flugmodus eine Folge teilen → Hinweis "spaeter erneut versuchen"
7. Eine sehr alte Folge eines grossen Podcasts teilen (z.B. Tara Brach von 2019) → "Diese Folge kann leider nicht uebernommen werden" (bis shared-129 umgesetzt ist)

---

## UX-Konsistenz

| Verhalten | iOS | Android |
|-----------|-----|---------|
| Woher der Link kommt | Teilen aus Apple Podcasts, Browser, Messenger | Teilen aus Browser, Messenger (kein Apple Podcasts auf Android) |

---

## Hinweise

- Ein geteilter Link hat die Form `podcasts.apple.com/<land>/podcast/<podcast-kurzname>/id<Podcast-ID>?i=<Folgen-ID>`. Er enthaelt den Podcast-Namen, **nicht** den Folgentitel.
- Apples Lookup-Dienst (`itunes.apple.com/lookup?id=<Podcast-ID>&entity=podcastEpisode&limit=200`) braucht keinen Schluessel. Die Folgen-ID entspricht dort `trackId`; die Audiodatei steht in `episodeUrl`, der Folgentitel in `trackName`, der Autor nur beim Podcast-Eintrag (`artistName`), `episodeContentType` unterscheidet Audio/Video. Eine direkte Abfrage per Folgen-ID liefert 0 Treffer. Ratenlimit laut Apple ca. 20 Abrufe/Minute.
- Grenze: hoechstens die 200 neuesten Folgen, bei manchen Podcasts weniger. Aeltere Folgen loest shared-129.
- Beispiel Deutschlandfunk Nova: Autor ist der Sender, nicht die Sprecherinnen. Das ist erwartet — der Bearbeiten-Dialog ist zum Korrigieren da.
- Folgentitel enthalten oft Beiwerk wie "(20:34 Min.)". Nichts automatisch abschneiden.
- Podcast-Folgen sind oft lang (60 Min. ≈ 50–60 MB). Pruefen, ob der bestehende Download auf iOS (laedt bisher die ganze Datei in den Arbeitsspeicher) dafuer taugt.
- Keine vorgezogene Abstraktion fuer weitere Podcast-Apps — die kommen, wenn sie gebraucht werden.
- Entscheidungen und Recherche: `dev-docs/concepts/podcast-import.md`

---

## Referenz

- Bestehender Link-Import: shared-046, shared-091; Ladefenster: shared-082; Vorschlaege im Bearbeiten-Dialog: ios-043, shared-103
