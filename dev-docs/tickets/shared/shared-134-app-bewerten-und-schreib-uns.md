---
id: shared-134
title: "App bewerten und Schreib uns in den Einstellungen"
status:
  ios: todo
  android: todo
phase: 3-Feature
priority: mittel
depends_on: []
---

# Ticket shared-134: App bewerten und Schreib uns in den Einstellungen

## Was

Im Info-Bereich der Einstellungen gibt es zwei neue Einträge:

- **App bewerten** öffnet die Seite von Still Moment im App Store bzw. bei Google Play, direkt dort, wo man eine Bewertung schreibt.
- **Schreib uns** öffnet eine neue E-Mail an `hello@stillmoment.app`. Untertitel: „Hallo sagen, danke sagen, Feedback geben“.

## Warum

Wer die App mag oder etwas loswerden möchte, findet heute in der App keinen Weg dazu. Die Kontaktadresse steht nur auf der Website. Bewertungen helfen anderen, die App zu finden. Nachrichten von Nutzern sind die einzige Rückmeldung, die es gibt, weil die App bewusst nichts misst.

---

## Akzeptanzkriterien

- [ ] Der Info-Bereich der Einstellungen zeigt die Einträge „App bewerten“ und „Schreib uns“
- [ ] Tippen auf „App bewerten“ öffnet die Store-Seite von Still Moment mit der Möglichkeit, eine Bewertung zu schreiben (iOS: App Store, Android: Google Play)
- [ ] Ist auf Android keine Play-Store-App vorhanden, öffnet sich die Google-Play-Seite der App im Browser
- [ ] Tippen auf „Schreib uns“ öffnet das Mail-Programm mit einer neuen Nachricht an `hello@stillmoment.app`, mit vorausgefülltem Betreff (z. B. „Still Moment“)
- [ ] Der Text der Nachricht enthält App-Version und Betriebssystem-Version. Die Person sieht diese Angaben vor dem Senden und kann sie löschen
- [ ] Ist kein Mail-Programm eingerichtet, sieht die Person die Adresse `hello@stillmoment.app` und kann sie kopieren. Tippen bleibt nie ohne Reaktion
- [ ] Die App fragt nie von sich aus nach einer Bewertung: kein Bewertungsfenster nach Meditationen, beim Start oder zu einem anderen Zeitpunkt
- [ ] Beide Einträge haben Accessibility-Labels und -Hinweise, die sagen, dass die App verlassen wird (Store bzw. Mail-Programm)
- [ ] Die bestehenden Einträge im Info-Bereich (Klänge, Datenschutz, Version) bleiben erhalten und funktionieren weiterhin

---

## Manueller Test

1. Einstellungen öffnen, zum Info-Bereich scrollen
2. „App bewerten“ tippen → Store-Seite von Still Moment öffnet sich, Bewerten ist möglich
3. Zurück zur App, „Schreib uns“ tippen → Mail-Programm öffnet eine neue Nachricht an `hello@stillmoment.app` mit Betreff, App-Version und Betriebssystem im Text
4. Auf einem Gerät ohne eingerichtetes Mail-Programm (z. B. Simulator/Emulator) „Schreib uns“ tippen → die Adresse wird angezeigt und lässt sich kopieren
5. Erwartung: auf beiden Plattformen identisch, bis auf den jeweiligen Store

---

## Nicht Teil dieses Tickets

- Automatische Bewertungsanfrage (Bewertungsfenster der Systeme), auch nicht nach X Meditationen
- Feedback-Formular, Web-Formular oder Feedback-Dienste von Drittanbietern
- Anzeige oder Abfrage von Bewertungen in der App

---

## Hinweise

- **Kein automatisches Bewertungsfenster:** Die App soll sich wie eine Pause anfühlen, nicht wie ein Anstupsen. Die Bewertungsfenster der Systeme (iOS StoreKit, Google In-App Review) eignen sich außerdem nicht für einen Button. Apple und Google begrenzen, wie oft sie erscheinen, und raten davon ab, sie an einen Button zu hängen, weil das Tippen sonst ohne Reaktion bleiben kann. Deshalb öffnet der Eintrag die Store-Seite.
- **E-Mail statt Formular:** Kein Server, kein Drittanbieter. Die Person entscheidet selbst, was sie schickt und unter welcher Adresse. Das passt zu „Privacy is non-negotiable“.
- **Store-Adressen:** iOS `https://apps.apple.com/app/id<APP_ID>?action=write-review`, Android `market://details?id=<package>`, als Ausweichlösung `https://play.google.com/store/apps/details?id=<package>`.
- **Ton:** warm und einladend, nicht nach Support-Formular klingend. Bezeichnungen: „App bewerten“, „Schreib uns“, Untertitel „Hallo sagen, danke sagen, Feedback geben“ (EN sinngemäß).
- **Produktphilosophie:** Die Einträge helfen nicht direkt beim Meditieren. Sie sind passiv, erscheinen nur in den Einstellungen und drängen sich nicht auf.
