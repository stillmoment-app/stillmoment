# Feature-Konzept: Podcast-Import

**Status**: Konzept (validiert mit Prototyp + API-Tests)
**Erstellt**: 2026-01-02
**Aktualisiert**: 2026-01-04

## Übersicht

Meditationen aus Podcasts suchen, vorhören und in die Guided Meditations Bibliothek importieren.

**Kernproblem**: User haben Meditationen in Podcasts, aber keinen einfachen Weg, die MP3s zu extrahieren. Apple Podcasts und Spotify sind geschlossene Systeme ohne Export.

**Lösung**: Still Moment als "Brücke zur Quelle" - kein Podcast-Player, sondern Import-Tool.

## UI-Konzept

### Neuer Tab in der App-Navigation

```
┌─────────────────────────────────────────────────┐
│      [Timer]      [Library]      [Podcasts]     │
└─────────────────────────────────────────────────┘
                                       ↑
                                     NEU
```

- **Timer**: Meditation starten (besteht)
- **Library**: Alle gespeicherten Meditationen (besteht)
- **Podcasts**: Suchen, Preview, Import (neu)

### Podcasts-Tab

```
┌─────────────────────────────────────────────────┐
│  🔍 Thema suchen...                    [Finden] │
├─────────────────────────────────────────────────┤
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │ 🖼️ │ Morgenmeditation #42              │   │
│  │    │ Meditation Daily · 10 min         │   │
│  │    │ [▶️ Preview]        [+ Bibliothek]│   │
│  └─────────────────────────────────────────┘   │
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │ 🖼️ │ Bodyscan für Anfänger             │   │
│  │    │ Zen Daily · 15 min                │   │
│  │    │ [▶️ Preview]        [+ Bibliothek]│   │
│  └─────────────────────────────────────────┘   │
│                                                 │
└─────────────────────────────────────────────────┘
```

### User Flow

1. **Podcasts-Tab öffnen**: User sucht nach Thema (z.B. "Meditation", "Schlaf")
2. **Ergebnisse**: iTunes API liefert Episoden mit Cover, Titel, Dauer
3. **Preview**: Episode vorhören (Streaming)
4. **Import**: "In Bibliothek" lädt Episode herunter
5. **Library-Tab**: Importierte Episode erscheint wie jede andere Meditation

### Kein Unterschied in der Library

Importierte Podcast-Episoden sind normale Guided Meditations:

```
[Library-Tab]

Meine Meditationen

┌──────────────────────────┐
│ Morgenmeditation #42     │  ←── importiert via Podcasts-Tab
│ Meditation Daily         │
└──────────────────────────┘
┌──────────────────────────┐
│ Bodyscan.mp3             │  ←── importiert via Files
└──────────────────────────┘
┌──────────────────────────┐
│ Atemübung.m4a            │  ←── importiert via Files
└──────────────────────────┘
```

Die Quelle ist unterschiedlich, das Ergebnis identisch.

---

## Alternative: Share Extension (bevorzugt)

Statt eines dritten Tabs: Import via iOS Share Sheet.

### Warum Share Extension?

| Aspekt | Dritter Tab | Share Extension |
|--------|-------------|-----------------|
| Navigation | 3 Tabs (komplexer) | 2 Tabs (bleibt einfach) |
| User-Intent | "Ich stöbere" | "Ich will genau diese Episode" |
| iOS-Integration | Eigene UI | Nativer iOS-Flow |
| Quellen | Nur iTunes | Apple Podcasts, Safari, Overcast, etc. |

### User Flow

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Apple Podcasts │     │   iOS Share     │     │  Still Moment   │
│                 │ ──▶ │     Sheet       │ ──▶ │  Import Sheet   │
│  [Teilen]       │     │ [Still Moment]  │     │  [Importieren]  │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

1. User öffnet Episode in Apple Podcasts (oder Safari, Overcast, etc.)
2. User tippt "Teilen" → wählt "Still Moment"
3. Still Moment zeigt Import-Sheet mit Episode-Preview
4. User bestätigt → Download startet
5. Episode erscheint in Library

### Share-Link Format

```
https://podcasts.apple.com/de/podcast/episode-titel/id1654749564?i=1000741226134
                                                      │              │
                                                Podcast-ID      Episode-ID
```

### Technischer Flow: Link → Audio-URL

```
┌──────────────────────────────────────────────────────────────────────┐
│ 1. Share-Link parsen                                                 │
│    ├─► Podcast-ID: 1654749564 (aus Pfad "id...")                    │
│    └─► Episode-ID: 1000741226134 (aus Query "i=...")                │
├──────────────────────────────────────────────────────────────────────┤
│ 2. iTunes Lookup API                                                 │
│    GET https://itunes.apple.com/lookup?id={podcastId}               │
│        &entity=podcastEpisode&limit=200                              │
│                                                                      │
│    Response enthält alle Episoden mit trackId + episodeUrl          │
├──────────────────────────────────────────────────────────────────────┤
│ 3. Episode finden                                                    │
│    results.first { $0.trackId == episodeId }                        │
├──────────────────────────────────────────────────────────────────────┤
│ 4. Download                                                          │
│    Direkt von episodeUrl (z.B. sphinx.acast.com/.../media.mp3)      │
└──────────────────────────────────────────────────────────────────────┘
```

### API-Response Beispiel

```bash
curl "https://itunes.apple.com/lookup?id=1654749564&entity=podcastEpisode&limit=200"
```

```json
{
  "resultCount": 84,
  "results": [
    { "wrapperType": "collection", "collectionId": 1654749564, ... },
    {
      "wrapperType": "podcastEpisode",
      "trackId": 1000741226134,
      "trackName": "Superkalifragilistischexpialigetisch",
      "collectionName": "insomnicat – lächelnd einschlafen",
      "artistName": "insomnicat",
      "artworkUrl600": "https://is1-ssl.mzstatic.com/.../600x600bb.jpg",
      "episodeUrl": "https://sphinx.acast.com/p/open/s/.../media.mp3",
      "trackTimeMillis": 1558000,
      "releaseDate": "2025-12-14T05:00:00Z"
    }
  ]
}
```

### Limitierung: Max 200 Episoden

Die iTunes API liefert maximal 200 Episoden pro Podcast.

| Szenario | Verhalten |
|----------|-----------|
| Episode in Top 200 | Funktioniert |
| Episode älter (>200) | "Episode nicht gefunden" |

**Pragmatische Entscheidung:** Für Meditations-Podcasts ausreichend. Die meisten haben <200 Episoden, und User importieren typischerweise aktuelle Inhalte.

**Möglicher Fallback (nicht im MVP):** RSS-Feed parsen via `feedUrl` aus API-Response. Aber: Matching Episode-ID ↔ RSS-GUID nicht trivial.

### Kombinierte Strategie

Share Extension UND In-App-Suche sind kombinierbar:

```
[Library Tab]
    │
    └─► [+] Button
            │
            ├─► "Aus Dateien importieren" (besteht)
            └─► "Podcast-Episode suchen" (neu, öffnet Suche)

[Share Extension]
    │
    └─► Direkter Import aus Apple Podcasts etc.
```

---

## Technische Architektur

### Einfacher Ansatz: Nur iTunes API

```
┌──────────────────┐     ┌──────────────────┐
│  iTunes Search   │ ──▶ │   Audio File     │
│       API        │     │    Download      │
└──────────────────┘     └──────────────────┘
   (Suche & URL)            (Import)
```

**Kein RSS-Parsing nötig!** Die iTunes API liefert bei Podcasts direkt die volle MP3-URL.

### iTunes Search API

```bash
# Podcast-Episoden suchen
curl "https://itunes.apple.com/search?term=meditation&media=podcast&entity=podcastEpisode&limit=25"
```

Liefert direkt alles, was wir brauchen:

```json
{
  "trackName": "Morgenmeditation #42",
  "artistName": "Meditation Daily",
  "collectionName": "Meditation Daily Podcast",
  "artworkUrl600": "https://..../cover.jpg",
  "trackTimeMillis": 3762000,
  "episodeUrl": "https://traffic.megaphone.fm/XXX.mp3",
  "trackViewUrl": "https://podcasts.apple.com/..."
}
```

| Feld | Verwendung |
|------|------------|
| `trackName` | Episode-Titel |
| `artistName` / `collectionName` | Podcast-Name (für Attribution) |
| `artworkUrl600` | Cover-Bild |
| `trackTimeMillis` | Dauer in ms |
| `episodeUrl` | **Volle MP3-URL** (nicht nur Preview!) |
| `trackViewUrl` | Deep-Link zu Apple Podcasts |

**Wichtige Erkenntnis**: Anders als bei Musik liefert die iTunes API bei Podcasts die volle Episode-URL, nicht nur einen 30s-Preview. Das vereinfacht die Implementierung erheblich.

### Download & Speicherung

- Direkter Download von `episodeUrl` (Producer bekommt Stats)
- Lokale Speicherung (iOS: Documents, Android: Internal Storage)
- Metadaten in Core Data / Room

## Attribution & Ethics

### Download-Statistiken

**Podcast-Monetarisierung basiert auf Download-Zahlen.**

- Direkter Download vom Original-Server (kein Proxy/Cache)
- Producer sieht Download in seinen Analytics
- Entspricht dem Verhalten aller Standard-Podcast-Apps

### Sichtbare Attribution

Jede importierte Episode zeigt:
- Podcast-Name + Episode-Titel
- Autor/Creator
- Deep-Link zum Original-Podcast via `trackViewUrl` (öffnet Apple Podcasts)

### Wiederholtes Hören

Podcast-Analytics zählen nur unique Downloads (IAB-Standard). Wiederholtes Offline-Hören wird nicht getrackt - das ist bei allen Podcast-Apps so, nicht spezifisch für Still Moment.

## Privacy

| Aktion | Verhalten |
|--------|-----------|
| Suche via iTunes API | Apple sieht Suchanfrage |
| Download vom Original-Server | Producer sieht IP + Download |
| Wiedergabe in Still Moment | Komplett lokal, keine Telemetrie |
| Import-Daten | Keine Sync, keine Erfassung durch Still Moment |

**Still Moment sammelt keine Daten** über Hörverhalten oder importierte Podcasts.

## Geklärte Entscheidungen

| Frage | Entscheidung |
|-------|--------------|
| Feed-URL Discovery | iTunes Lookup API (Podcast-ID aus Share-Link oder Search) |
| Scope | Einzelne Episoden (kein Abo-Management) |
| UI-Integration | **Offen:** Share Extension (bevorzugt) vs. Dritter Tab |
| Bibliothek | Keine separate Podcast-Bibliothek - Import landet in bestehender Library |
| Technischer Ansatz | Nur iTunes API, kein RSS-Parsing (API liefert volle MP3-URL) |
| Episode-Lookup | Via Podcast-ID + Episode-ID (trackId) aus Share-Link |
| API-Limit | Max 200 Episoden - für Meditations-Podcasts ausreichend |

## Offene Fragen

- [ ] **UI-Entscheidung**: Share Extension vs. Dritter Tab vs. Beides?
- [ ] **Dateigröße**: Maximum festlegen? (Podcast-Episoden oft 50-200 MB)
- [ ] **Plattformen**: iOS first oder iOS + Android parallel?
- [ ] **Streaming vs. Download**: Erst streamen (Preview), dann optional downloaden?
- [ ] **Fehlerfall >200 Episoden**: Nur Fehlermeldung oder RSS-Fallback?

## Technische Anforderungen

### Komponenten

- iTunes Search API Client (JSON)
- HTTP-Client für Downloads
- Lokale Dateispeicherung
- Metadaten-Persistenz (Core Data / Room)
- Background-Download-Support (große Dateien)

### iOS-spezifisch

- `URLSession` für API-Calls und Downloads
- `Codable` für JSON-Parsing (kein XML nötig)
- Background URLSession für große Downloads
- Core Data Entity für importierte Episoden

### Android-spezifisch

- Retrofit/Ktor für API-Calls
- Kotlinx Serialization für JSON
- WorkManager für Background-Downloads
- Room Entity für importierte Episoden

## Prototyp

Ein Web-Prototyp (React) validiert den grundlegenden Flow:
- Suche via iTunes API funktioniert
- Episoden-Liste mit Cover, Titel, Dauer
- Streaming-Wiedergabe

**Abweichung zur finalen UI**: Prototyp hat eigene Bibliothek-Ansicht. In Still Moment landen Importe stattdessen in der bestehenden Library.

**Erkenntnis aus Prototyp-Analyse**: Die iTunes API liefert bei Podcasts (anders als bei Musik) die volle Episode-URL via `episodeUrl`. Kein RSS-Parsing nötig.
