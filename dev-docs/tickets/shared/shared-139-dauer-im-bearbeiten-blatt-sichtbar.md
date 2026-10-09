---
id: shared-139
title: "Bearbeiten-Blatt: Dauer bleibt neben langem Dateinamen sichtbar"
status:
  ios: todo
  android: todo
phase: 4-Polish
priority: niedrig
depends_on: []
---

# Ticket shared-139: Bearbeiten-Blatt: Dauer bleibt neben langem Dateinamen sichtbar

## Was

**Beobachtet:** Die Datei-Info im Bearbeiten-Blatt zeigt „Dateiname · Dauer“ auf höchstens zwei Zeilen. Ist der Dateiname lang, wird die Zeile am Ende mit „…“ gekürzt, und die Dauer verschwindet ganz. Beispiel beim Import von `https://www.audiodharma.org/talks/25402/download`: `20260504-David_Lorey-IMC-dharmette_the_heart_of_practice_1_of_5_this_a…` ohne Dauer. Auf Android zeigt die Datei-Info außerdem die effektive Dauer statt der vollen Dateilänge.

**Erwartet:** Die Dauer ist immer sichtbar. Ist der Dateiname zu lang, wird er in der Mitte gekürzt, sodass Anfang und Endung lesbar bleiben (Muster: `20260504-David_Lorey-IMC-….mp3 · 19:52`). Beide Plattformen zeigen dort die volle Dateilänge.

**Umstände:** Beim Import und beim Bearbeiten einer Meditation mit langem Dateinamen, typisch bei Vorträgen von audiodharma.org und bei Podcast-Folgen. iOS und Android.

## Warum

Die Dauer hilft beim Import zu erkennen, ob die richtige Aufnahme kommt, gerade wenn Titel und Lehrer erst noch angepasst werden. Lange Dateinamen sind bei den Quellen, die die App empfiehlt, die Regel.

---

## Akzeptanzkriterien

<!-- Gelten fuer BEIDE Plattformen. -->

- [ ] Beim Import von 25402 zeigt die Datei-Info die Dauer (19:52) und einen in der Mitte gekürzten Dateinamen, dessen Endung `.mp3` sichtbar ist.
- [ ] Kurze Dateinamen erscheinen ungekürzt wie bisher, gefolgt von der Dauer.
- [ ] Bei einer zugeschnittenen Meditation zeigt die Datei-Info auf beiden Plattformen die volle Dateilänge, nicht die zugeschnittene Dauer.
- [ ] Bei größter Schrift (Dynamic Type bzw. Schriftgröße) bleiben Dateiname und Dauer lesbar, die Dauer wird nicht abgeschnitten.
- [ ] Erhalt: VoiceOver bzw. TalkBack lesen Dateiname und Dauer weiterhin zusammen als ein Element vor.

---

## Manueller Test

1. `https://www.audiodharma.org/talks/25402/download` an Still Moment teilen und die App öffnen.
2. Erwartung: Das Bearbeiten-Blatt zeigt unter dem Namen den gekürzten Dateinamen mit sichtbarer Endung `.mp3` und „· 19:52“.
3. Eine Meditation mit kurzem Dateinamen bearbeiten. Erwartung: Dateiname vollständig, dahinter die Dauer.
4. Eine Meditation zuschneiden und erneut bearbeiten. Erwartung: Die Datei-Info zeigt die volle Dateilänge.

---

## Hinweise

- Entscheidung des Users: Dauer immer sichtbar, Dateiname in der Mitte gekürzt.
- Laut Glossar gehört in die Datei-Info die volle Dateilänge, in Liste und Player die effektive Dauer. iOS hält sich daran, Android zieht nach.
