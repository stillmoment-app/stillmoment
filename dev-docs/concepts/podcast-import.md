# Feature-Konzept: Podcast-Import

**Status**: Entschieden, in Tickets ueberfuehrt (shared-127, shared-128, shared-129, shared-133)
**Erstellt**: 2026-01-02
**Aktualisiert**: 2026-10-08 (Design-Interview; ersetzt die Fassung vom 2026-01-04)

## Uebersicht

Podcasts werden eine neue Quelle fuer die Bibliothek. Es gibt viele gute Meditationen in Podcasts (Tara Brach, "Achtsam" von Deutschlandfunk Nova, ...). **Entdeckt wird in der Podcast-App, uebernommen per Teilen.** Still Moment ist kein Podcast-Player und kein Podcast-Browser.

```
Apple Podcasts            Teilen-Menue          Still Moment
Folge oeffnen  ──Teilen──▶  Still Moment  ──▶  Ladefenster ──▶ Bearbeiten-Dialog ──▶ Bibliothek
```

Eine importierte Folge ist danach eine ganz normale Meditation — offline abspielbar, ohne Bezug zum Podcast.

## Entscheidungen

| Frage | Entscheidung | Begruendung |
|-------|--------------|-------------|
| Problem | Neue Quelle fuer Inhalte; Entdecken bleibt in der Podcast-App | Keine Browser-/Such-UI in der App ("Simplicity over features") |
| Einzelne Folge oder Podcast | Nur einzelne Folgen. Geteilter ganzer Podcast → Hinweis | Kein Folgen-Browser, kein Abo (kein Hintergrund-Netz, keine sich selbst fuellende Bibliothek) |
| Plattformen | MVP: Apple-Podcasts-Folgenlinks auf iOS **und** Android | Fachlich ein Feature; auf Android kommen Links per Messenger/Browser |
| Weitere Podcast-Apps | Spaeter, eigene Tickets. Keine vorgezogene Abstraktion | Gemeinsamkeiten erst an zwei echten Faellen erkennen |
| Datenschutz | Netzwerk nur auf ausdrueckliche Nutzeraktion, keine Kennungen; Apple-Abruf erlaubt; Datenschutzerklaerung ehrlich anpassen | Grundwert ist "kein Tracking, keine eigenen Server, nichts ohne Zutun" — nicht "null Netzwerk". Datenschutzerklaerung war seit dem Link-Import ohnehin ungenau |
| Link → Audiodatei | 1. Apples Lookup-Dienst. 2. Sonst: Titel aus `og:title` der Apple-Folgenseite, exakte Titelsuche im Feed des Anbieters | Offizieller Weg fuer neue Folgen; Standard-Vorschauangabe + oeffentlicher Feed fuer aeltere |
| Ausgeschlossen | Internen Datenblock der Apple-Seite auslesen (wie yt-dlp); interne Apple-API mit Token | Undokumentiert, bricht jederzeit, klares Page-Scraping |
| Titel / Lehrer:in | Titel = Folgentitel; Lehrer:in = Autor des Podcasts, sonst Podcast-Name; Bearbeiten-Dialog wie gewohnt | Bessere Vorschlaege als ID3-Tags von Podcast-MP3s |
| Herkunft speichern | Nein (kein Podcast-Name, kein Deep-Link, kein Artwork) | Fairness ist durch Download direkt beim Anbieter erfuellt; kein neues Datenfeld ohne Nutzen fuer die meditierende Person |
| Fehlermeldungen | Genau drei, nach Handlungsmoeglichkeit: "einzelne Folge teilen" / "keine Verbindung, spaeter erneut" / "kann leider nicht uebernommen werden" | Ursache (Bezahl-Folge, Video, nicht gefunden) aendert fuer den Nutzer nichts und ist technisch oft nicht unterscheidbar |
| Ladeanzeige | Bestehendes Ladefenster (shared-082) unveraendert; Abbrechen stoppt auch die Suche | Suchschritte sind fuer den Nutzer ein technisches Detail; Fortschrittsanzeige wurde in shared-082 bewusst verworfen |
| Sichtbarkeit | Anleitung "So importierst du aus Apple Podcasts" (iOS + Android, Ausgangspunkt podcasts.apple.com) in "Wo finde ich Meditationen?" | Feature beginnt in einer anderen App und ist sonst unauffindbar |

## Tickets

| Ticket | Inhalt |
|--------|--------|
| shared-127 | Datenschutzerklaerung, Store-Texte, Website, README: ehrlich zu Netzwerkzugriffen (inkl. Apple-Abruf) |
| shared-128 | Podcast-Import ueber den Lookup-Dienst (neueste Folgen), iOS + Android — umgesetzt 2026-10 |
| shared-129 | Rueckfallweg fuer aeltere Folgen (og:title + Feed) |
| shared-133 | Anleitung "So importierst du aus Apple Podcasts", iOS + Android, Ausgangspunkt podcasts.apple.com |

## Spaeter (noch keine Tickets)

- **AntennaPod (Android)**: teilt laut Quellcode wahlweise die direkte MP3-Adresse oder die Datei selbst — funktioniert vermutlich schon heute ueber den Link-Import. Pruefen und dokumentieren, ggf. Android-Anleitung.
- **Weitere Podcast-Apps**: Pocket Casts (`pca.st/...`, kein dokumentierter Aufloesungsweg), Spotify (`open.spotify.com/episode/...`, oft kein oeffentlicher Feed → nicht machbar).
- **Podcast-Eintraege in der Quellenliste** ("Wo finde ich Meditationen?"): redaktionelle Auswahl, Pruefung kostenlos/Lizenz, Verhalten des Knopfs auf Android klaeren.

## Recherche-Ergebnisse (2026-10-08)

### Geteilter Link

```
https://podcasts.apple.com/de/podcast/achtsam-deutschlandfunk-nova/id1528936478?i=1000792422344
                                      └── Podcast-Kurzname ──────┘   └ Podcast-ID ┘  └─ Folgen-ID ─┘
```

Der Kurzname im geteilten Link ist der **Podcast**, nicht die Folge (echter geteilter Link verifiziert).

**Geraetetest (2026-10-09, shared-128):** Still Moment erscheint im Teilen-Menue einer Folge in Apple Podcasts (bestehende Share-Extension, Aktivierung ueber `public.url`). Ob Apple Podcasts zusaetzlich zum Link Text (z.B. den Folgentitel) uebergibt, ist nicht geprueft — relevant erst fuer shared-129.

### Apples Lookup-Dienst

`https://itunes.apple.com/lookup?id=<Podcast-ID>&entity=podcastEpisode&limit=200` — kein Schluessel noetig.

| Feld | Bedeutung |
|------|-----------|
| `trackId` | = Folgen-ID aus dem Link |
| `episodeUrl` | MP3-Adresse beim Anbieter |
| `trackName` | Folgentitel |
| `collectionName` | Podcast-Name |
| `artistName` | Autor — **nur beim Podcast-Eintrag**, nicht bei Folgen |
| `episodeContentType` | `audio` / `video` |
| `feedUrl` | RSS-Feed des Anbieters |

- Hoechstens die **200 neuesten** Folgen, teils weniger (The Daily: 44). Tara Brach: 1.633 Folgen, Lookup reicht bis ca. Oktober 2024.
- Direkte Abfrage per Folgen-ID: 0 Treffer.
- Ratenlimit laut Apple ca. 20 Abrufe/Minute. Nutzungsbedingungen zielen auf Bewerbung von Apple-Inhalten — Nutzung nur zur Aufloesung ist Grauzone, aber verbreitet.
- Beispiel "Achtsam": 89 Folgen, `artistName` = "Deutschlandfunk Nova" (Sender, nicht die Sprecherinnen).

### Apple-Folgenseite

- Enthaelt fuer alte und neue Folgen (getestet: 2019, 2021, 2026) den Titel in `og:title` und die MP3-Adresse in einem internen JSON-Block (`serialized-server-data` → `mediaEnclosures[0].streamUrl`).
- Apples Website-Bedingungen verbieten "page-scrape" und automatisierten Zugriff. Entscheidung: nur `og:title` lesen (wie eine Link-Vorschau), einmalig und vom Nutzer ausgeloest; den internen Block nicht.

### RSS-Feed

- Podcast-Ebene: `<title>` (Podcast-Name), `<itunes:author>` (Autor), `<itunes:owner>` (Kontakt, nicht anzeigen).
- Folgen-Ebene: `<title>` (Folgentitel), optional `<itunes:title>`, `<guid>`, `<enclosure>` (Audiodatei).
- Die Apple-Folgen-ID kommt im Feed nicht vor → Zuordnung nur ueber den Titel.

### Wie Apple Podcasts selbst laedt

Bei normalen RSS-Podcasts laedt das Geraet direkt vom Anbieter; Hoster zaehlen das als Download. Seit iOS 26.4 spielt Apple bei Partner-Hostern teils HLS-Streams, die MP3 bleibt als Rueckfall. Kein Beleg fuer Apple-eigene Kopien. → Laden aus dem Feed ist ein normaler, vom Anbieter gezaehlter Download.

### Andere Werkzeuge

- yt-dlp: liest den internen Datenblock der Apple-Seite (fuer uns ausgeschlossen).
- Podcast Index: Lookup nur per Podcast-ID, nicht per Folgen-ID.
- Listen Notes: empfiehlt Titelsuche, warnt vor unzuverlaessiger Zuordnung.
- Kein Dienst bildet Apple-Folgen-IDs auf Feed-GUIDs ab.

## Umsetzungsentscheidungen (shared-128, 2026-10-09)

- Aufloesung in der App, nicht in der iOS-Share-Extension (dort leben Ladefenster, Abbrechen und Meldungen; gleicher Aufbau wie Android).
- Lookup schickt das Land aus dem Link mit (`&country=<land>`); Links ohne Laender-Segment (`podcasts.apple.com/podcast/...`) werden ohne `country` abgefragt.
- `http://`-Audioadressen werden auf `https://` umgestellt (iOS ATS und Android blockieren unverschluesselte Verbindungen).
- Apple-Ratenlimit (HTTP 403/429) → "Gerade nicht erreichbar" mit "Erneut versuchen", nicht "kann nicht uebernommen werden".
- Diese Meldung ersetzt im Link-Import "Download fehlgeschlagen" fuer reine Netzfehler; "Erneut versuchen" nur, wo ein neuer Versuch etwas aendern kann.
- iOS laedt per `URLSession.download(for:)` direkt in eine Datei (vorher komplett in den Arbeitsspeicher).

## Verworfene Ansaetze (Fassung 2026-01)

- **Dritter Tab "Podcasts" mit Suche und Vorhoeren**: macht die App zum Podcast-Browser.
- **Sichtbare Attribution mit Deep-Link zu Apple Podcasts**: kein Nutzen fuer die meditierende Person, fuehrt aus der App hinaus.
- **"200 Folgen reichen"**: fuer Meditations-Podcasts widerlegt — aeltere, zeitlose Folgen sind oft die wertvollsten.
