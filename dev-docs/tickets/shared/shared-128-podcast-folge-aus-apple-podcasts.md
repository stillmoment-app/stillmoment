---
id: shared-128
title: Podcast-Folge aus Apple Podcasts importieren
status:
  ios: in-progress
  android: in-progress
phase: 3-Feature
priority: mittel
depends_on: [shared-127]
---

# Ticket shared-128: Podcast-Folge aus Apple Podcasts importieren

**Plan iOS**: `dev-docs/tickets/plans/shared-128-ios.md`

**Plan Android**: `dev-docs/tickets/plans/shared-128-android.md`

**Komplexitaet**: Der Import-Weg (Teilen → Ladefenster → Bearbeiten-Dialog) existiert schon; neu ist das Aufloesen eines Apple-Podcasts-Links zur Audiodatei. Risiken: Apples Lookup-Dienst ist undokumentiert begrenzt (max. 200 neueste Folgen, teils weniger), und ob Still Moment im Teilen-Menue von Apple Podcasts erscheint, ist nur auf einem echten Geraet pruefbar. Der bestehende Link-Import wird an zwei Stellen mit angepasst: neue Verbindungsfehler-Meldung und Download in Datei auf iOS.

---

## Was

Wer in Apple Podcasts eine einzelne Folge teilt und Still Moment waehlt, bekommt diese Folge als Meditation in die Bibliothek — mit Folgentitel und Autor als Vorschlag im gewohnten Bearbeiten-Dialog. Gleiches gilt, wenn ein Apple-Podcasts-Folgenlink auf anderem Weg geteilt wird (z.B. aus Messenger oder Browser), auf iOS und Android.

## Warum

Es gibt viele gute Meditationen in Podcasts (z.B. Tara Brach, "Achtsam" von Deutschlandfunk Nova). Podcasts werden damit zu einer neuen Quelle fuer die Bibliothek: Entdeckt wird in der Podcast-App, uebernommen per Teilen. Heute scheitert ein geteilter Apple-Podcasts-Link mit "Keine Aufnahme gefunden", weil der Link auf eine Webseite zeigt und nicht auf die Audiodatei.

---

## Akzeptanzkriterien

<!-- Kriterien gelten fuer BEIDE Plattformen, sofern nicht anders markiert -->

### Vorab-Pruefung (iOS, echtes Geraet)
- [x] Verifiziert und im Ticket festgehalten: Still Moment erscheint im Teilen-Menue einer Folge in Apple Podcasts, und was dabei uebergeben wird. Falls nicht: Ticket stoppen und Vorgehen neu klaeren — **Ergebnis 2026-10-09: erscheint** (bestehende Share-Extension; ob zusaetzlich Text uebergeben wird, ist nicht geprueft — erst fuer shared-129 relevant)

### Feature (beide Plattformen)
- [x] Ein geteilter Apple-Podcasts-Folgenlink einer der neuesten Folgen fuehrt zum bekannten Ladefenster und danach zum Bearbeiten-Dialog
- [x] Bearbeiten-Dialog schlaegt als Titel den Folgentitel vor, als Lehrer:in den Autor des Podcasts; fehlt der Autor, den Namen des Podcasts
- [ ] Nach dem Speichern ist die Folge eine ganz normale Meditation und spielt ohne Internet ab
- [x] Die Audiodatei wird direkt beim Anbieter des Podcasts geladen
- [x] Abbrechen im Ladefenster bricht auch die Suche nach der Folge ab; es entsteht kein Eintrag
- [x] Links aus allen Laender-Varianten von Apple Podcasts (z.B. `/de/`, `/us/`) funktionieren
- [x] Netzwerkzugriffe nur nach einer Teilen-/Import-Aktion des Nutzers, ohne Geraete- oder Nutzerkennungen
- [x] Ladefenster unveraendert (keine neuen Texte, keine Fortschrittsanzeige)
- [ ] Eine Folge von ueber 2 Stunden laesst sich importieren. iOS laedt die Audiodatei dafuer direkt in eine Datei statt in den Arbeitsspeicher (wie Android); gilt auch fuer den bestehenden Link-Import

### Fehlerfaelle — genau drei Meldungen
- [x] Link auf einen ganzen Podcast (ohne einzelne Folge): Hinweis, eine einzelne Folge zu teilen. Nur Knopf "Schliessen"
- [x] Keine Internetverbindung, Zeitueberschreitung oder Apple ist gerade ueberlastet (Ratenlimit, HTTP 403/429 vom Lookup-Dienst): neue Meldung "spaeter erneut versuchen" mit "Erneut versuchen" und "Abbrechen". Wortlaut neutral, da nicht immer die Verbindung schuld ist (z.B. "Gerade nicht erreichbar")
- [x] Der bestehende Link-Import zeigt bei Verbindungsfehlern dieselbe neue Meldung (ersetzt dort "Download fehlgeschlagen" fuer Netzfehler); Texte auf iOS und Android identisch
- [x] Alles andere — Folge nicht gefunden (auch aeltere Folgen bis shared-129), Bezahl-/Abo-Folge, Video-Folge, Datei beim Anbieter nicht mehr vorhanden, unerwartete Antwort: "Diese Folge kann leider nicht uebernommen werden". Nur Knopf "Schliessen"
- [x] "Erneut versuchen" wird nur angeboten, wenn ein erneuter Versuch etwas aendern kann
- [x] Nie stilles Scheitern, keine technischen Begriffe in den Meldungen
- [x] Lokalisiert (DE + EN)
- [ ] Visuell konsistent zwischen iOS und Android

### Tests
- [x] Unit Tests iOS: Erkennen von Folgen- vs. Podcast-Links (inkl. Laender-Varianten), Finden der Folge in der Lookup-Antwort, Vorschlaege fuer Titel/Lehrer:in inkl. fehlendem Autor, Zuordnung jedes Fehlerfalls zu einer der drei Meldungen (inkl. Ratenlimit 403/429), Download in Datei inkl. Abbrechen
- [x] Unit Tests Android: dieselben Faelle

### Dokumentation
- [x] CHANGELOG.md
- [x] `dev-docs/reference/glossary.md`: Begriff fuer den Podcast-Import (Abgrenzung zum Link-Import)
- [x] `dev-docs/concepts/podcast-import.md`: Ergebnis der Vorab-Pruefung nachtragen

---

## Manueller Test

1. iOS: In Apple Podcasts eine aktuelle Folge eines Meditations-Podcasts oeffnen (z.B. "Achtsam", Deutschlandfunk Nova) → Teilen → Still Moment
2. Erwartung: Ladefenster, dann Bearbeiten-Dialog mit Folgentitel und Autor; nach Speichern spielt die Folge im Flugmodus ab
3. Android: Nur den Folgenlink (ohne weiteren Text) per Messenger an sich selbst schicken → Link teilen → Still Moment
4. Erwartung: identisches Verhalten
5. Einen ganzen Podcast teilen → Hinweis "einzelne Folge teilen"
6. Im Flugmodus eine Folge teilen → Hinweis "spaeter erneut versuchen"
7. Eine sehr alte Folge eines grossen Podcasts teilen (z.B. Tara Brach von 2019) → "Diese Folge kann leider nicht uebernommen werden" (bis shared-129 umgesetzt ist)
8. Eine Folge von ueber 2 Stunden teilen (iOS, moeglichst aelteres Geraet) → Import klappt
9. Bestehender Link-Import: direkten MP3-Link im Flugmodus teilen → dieselbe "spaeter erneut versuchen"-Meldung wie beim Podcast-Import

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
- Podcast-Folgen sind oft lang (60 Min. ≈ 55 MB, 3 h ≈ 170 MB). iOS laedt bisher per `session.data(for:)` die ganze Datei in den Arbeitsspeicher, Android schreibt per `copyTo` direkt in eine Datei. Entscheidung: iOS auf `session.download(for:)` umstellen (temporaere Datei noch im Callback verschieben). Abbrechen muss weiter ueber `cancelDownload()` greifen.
- Aufteilung iOS: Die Share-Extension bleibt unveraendert (nimmt `http/https`-Links an, schreibt sie in die Inbox). Erkennen des Apple-Podcasts-Links, Lookup und Fehlerzuordnung liegen in der App (vor dem Download im `InboxHandler`) — dort leben Ladefenster, Abbrechen und Meldungen; so ist der Aufbau wie auf Android. Titel/Lehrer:in aus dem Lookup muessen Vorrang vor den ID3-Tags der geladenen Datei bekommen.
- Keine vorgezogene Abstraktion fuer weitere Podcast-Apps — die kommen, wenn sie gebraucht werden.
- Entscheidungen und Recherche: `dev-docs/concepts/podcast-import.md`

---

## Referenz

- Bestehender Link-Import: shared-046, shared-091; Ladefenster: shared-082; Vorschlaege im Bearbeiten-Dialog: ios-043, shared-103
