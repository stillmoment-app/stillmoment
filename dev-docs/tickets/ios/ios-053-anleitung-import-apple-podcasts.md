# Ticket ios-053: Anleitung "So importierst du aus Apple Podcasts"

**Status**: [ ] TODO
**Prioritaet**: MITTEL
**Komplexitaet**: Gering. Zwei Anleitungen mit Banner existieren bereits als Vorlage; neu sind Texte und ein dritter Eintrag.
**Abhaengigkeiten**: shared-128
**Phase**: 4-Polish

---

## Was

"Wo finde ich Meditationen?" bekommt neben den Anleitungen fuer Browser und Dateien eine dritte: "So importierst du aus Apple Podcasts" — mit Banner und drei Schritten (Folge oeffnen → Teilen → Still Moment, in der App fertigstellen).

## Warum

Der Podcast-Import beginnt ausserhalb von Still Moment, im Teilen-Menue einer anderen App. Ohne Hinweis entdeckt ihn kaum jemand. Die Anleitung macht Podcasts als Quelle fuer die Bibliothek sichtbar.

---

## Akzeptanzkriterien

### Feature
- [ ] "Wo finde ich Meditationen?" zeigt einen dritten Banner "So importierst du aus Apple Podcasts" im Stil der bestehenden Banner
- [ ] Antippen oeffnet eine Anleitung in drei Schritten im Stil der bestehenden Anleitungen
- [ ] Die Schritte beschreiben den tatsaechlichen Ablauf in Apple Podcasts (am Geraet nachvollzogen)
- [ ] Erwaehnt, dass nur einzelne Folgen uebernommen werden koennen, nicht ganze Podcasts
- [ ] Nicht-technische Sprache, Ton wie die bestehenden Anleitungen
- [ ] Lokalisiert (DE + EN)
- [ ] Accessibility-Labels wie bei den bestehenden Bannern

### Tests
- [ ] Bestehende Tests der Anleitungen/Banner um den dritten Eintrag erweitert

### Dokumentation
- [ ] CHANGELOG.md

---

## Manueller Test

1. Bibliothek → "Wo finde ich Meditationen?" oeffnen
2. Erwartung: drei Banner (Browser, Dateien, Apple Podcasts)
3. Apple-Podcasts-Banner antippen, die drei Schritte in Apple Podcasts nachspielen
4. Erwartung: Die Folge landet wie beschrieben in der Bibliothek

---

## Hinweise

- Bewusst nur iOS: Apple Podcasts gibt es auf Android nicht. Eine Android-Anleitung folgt erst, wenn dort Podcast-Apps (z.B. AntennaPod) unterstuetzt bzw. geprueft sind.
- Podcast-Eintraege in der Quellenliste sind **nicht** Teil dieses Tickets (eigene Kuratierungsaufgabe, siehe `dev-docs/concepts/podcast-import.md`).
