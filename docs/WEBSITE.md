# Still Moment Marketing Website

Die Marketing-Website für die Still Moment iOS App, gebaut mit reinem HTML/CSS/JavaScript und optimiert für GitHub Pages.

## Features

✨ **Vollständige Marketing-Funktionen**:
- Hero Section mit App Icon und CTA
- Screenshot-Carousel mit iPhone-Mockups
- 6 animierte Feature-Cards
- Privacy-Banner (Datenschutz-Fokus)
- Footer mit Links und Kontaktinformationen

🌍 **Bilingualer Support**:
- Vollständiger Deutsch/Englisch Support
- Sprachumschalter im Header
- localStorage speichert Sprachauswahl
- Automatisches Laden der gespeicherten Sprache

🎨 **Design**:
- Exakte App-Farbpalette (Terracotta, Warm Sand, etc.)
- SF Pro Rounded Typography
- Responsive Design (Mobile-First)
- Smooth Animationen und Transitions
- iPhone-Mockups mit Notch

🔍 **SEO & Meta Tags**:
- Open Graph (Facebook)
- Twitter Cards
- Vollständige Meta-Descriptions
- Semantic HTML5

## Dateistruktur

```
docs/
├── index.html              # Haupt-Website
├── privacy.html            # Datenschutzerklärung
├── WEBSITE.md             # Diese Datei
├── images/
│   ├── app-icon.png       # App Icon (1024x1024)
│   └── screenshots/
│       ├── README.md      # Screenshot-Anleitung
│       ├── timer-ready-en.png    (noch zu erstellen)
│       ├── timer-ready-de.png    (noch zu erstellen)
│       ├── timer-running-en.png  (noch zu erstellen)
│       ├── timer-running-de.png  (noch zu erstellen)
│       ├── library-en.png        (noch zu erstellen)
│       ├── library-de.png        (noch zu erstellen)
│       ├── player-en.png         (noch zu erstellen)
│       └── player-de.png         (noch zu erstellen)
```

## Lokal testen

### Option 1: Mit Python (einfachste Methode)

```bash
cd docs
python3 -m http.server 8000
```

Öffne dann http://localhost:8000 im Browser.

### Option 2: Mit Node.js (http-server)

```bash
# Falls nicht installiert
npm install -g http-server

cd docs
http-server -p 8000
```

### Option 3: Direkt im Browser öffnen

```bash
open docs/index.html
```

**Hinweis**: Einige Features (localStorage) funktionieren möglicherweise nicht korrekt bei `file://` URLs. Verwende einen lokalen Server für vollständige Funktionalität.

## Screenshots hinzufügen

Siehe [docs/images/screenshots/README.md](images/screenshots/README.md) für detaillierte Anleitung zum Erstellen der App-Screenshots.

**Quick Start**:
1. Simulator starten
2. Sprache auf Englisch setzen
3. App öffnen und Screenshots machen (Cmd+S)
4. Sprache auf Deutsch setzen
5. Gleiche Screenshots wiederholen
6. Screenshots nach `docs/images/screenshots/` kopieren
7. Richtig benennen (siehe README)

## GitHub Pages Deployment

Die Website ist bereits für GitHub Pages konfiguriert.

### Automatisches Deployment

1. **Push zu GitHub**:
   ```bash
   git add docs/
   git commit -m "feat: Add marketing website with bilingual support"
   git push origin main
   ```

2. **GitHub Pages aktivieren** (nur beim ersten Mal):
   - Gehe zu Repository Settings
   - Navigiere zu "Pages" (linke Sidebar)
   - Unter "Source": Wähle "Deploy from a branch"
   - Unter "Branch": Wähle `main` und `/docs` folder
   - Klicke "Save"

3. **Website ist live**:
   - URL: https://stillmoment-app.github.io/stillmoment/
   - Deployment dauert 1-2 Minuten

### Custom Domain (optional)

Falls du eine eigene Domain verwenden möchtest:

1. Erstelle `docs/CNAME` Datei:
   ```bash
   echo "stillmoment.app" > docs/CNAME
   ```

2. DNS-Einstellungen bei deinem Domain-Provider:
   ```
   A Record: 185.199.108.153
   A Record: 185.199.109.153
   A Record: 185.199.110.153
   A Record: 185.199.111.153

   # Oder CNAME für Subdomain:
   CNAME: stillmoment-app.github.io
   ```

3. In GitHub Settings → Pages → Custom domain: Deine Domain eingeben

## Website-Komponenten

### Header
- Sticky Navigation
- App Icon + Logo
- Sprachumschalter (EN/DE)

### Hero Section
- App Icon (groß)
- Titel + Tagline
- "Coming Soon" CTA Button
- Zweisprachiger Content

### Screenshots Section
- Horizontaler Carousel
- 4 iPhone-Mockups mit Notch
- Platzhalter-Text bis Screenshots vorhanden
- Automatisches Ein-/Ausblenden bei vorhandenen Bildern

### Features Section
- 6 Feature-Cards in Grid-Layout
- Emoji-Icons
- Hover-Animationen
- Responsive (3 Spalten → 2 → 1)

### Privacy Banner
- Gradient-Hintergrund (Terracotta)
- Privacy-First Message
- Prominente Platzierung

### Footer
- 3-Spalten Layout (responsive)
- Links zu GitHub, Privacy, Contributing
- Kontaktinformationen
- Copyright-Hinweis

## Farben & Design-System

```css
/* App-Farben (aus StillMoment/Presentation/Views/Shared/Color+Theme.swift) */
--warm-cream: #FFF8F0;      /* Hintergrund */
--warm-sand: #F5E6D3;       /* Sekundärer Hintergrund */
--pale-apricot: #FFD4B8;    /* Gradient-Ende */
--terracotta: #D4876F;      /* Hauptakzent (Buttons, Links) */
--clay: #C97D60;            /* Hover-States */
--dusty-rose: #E8B4A0;      /* Soft Highlights */
--warm-black: #3D3228;      /* Text */
--warm-gray: #8B7D6B;       /* Sekundärer Text */
--ring-bg: #E8DDD0;         /* UI-Elemente */
```

## Browser-Kompatibilität

Getestet und funktioniert in:
- ✅ Chrome/Edge (Chromium)
- ✅ Firefox
- ✅ Safari (Desktop + iOS)
- ✅ Mobile Browser (iOS Safari, Chrome Mobile)

**Verwendete Technologien**:
- CSS Variables (alle modernen Browser)
- CSS Grid (IE11+ mit Fallback)
- localStorage API
- Vanilla JavaScript (keine Dependencies)

## Performance-Optimierung

### Aktuelle Optimierungen:
- Inline CSS (keine externen Requests)
- Minimal JavaScript
- Optimierte Bilder (PNG, sollten <500KB sein)
- CSS Transitions statt JavaScript-Animationen

### Empfohlene weitere Optimierungen:
```bash
# Bilder komprimieren
imageoptim docs/images/**/*.png

# Oder mit pngquant
pngquant --quality=65-80 docs/images/**/*.png
```

## Zukünftige Erweiterungen

Ideen für v2.0:
- [ ] Video-Demo der App
- [ ] Testimonials/Reviews Section
- [ ] Blog-Integration (App Updates)
- [ ] Newsletter-Signup
- [ ] App Store Badges (wenn App veröffentlicht)
- [ ] Analytics (privacy-friendly, z.B. Plausible)
- [ ] Dark Mode Toggle
- [ ] Mehr Sprachen (z.B. Französisch, Spanisch)

## Wartung

### Regelmäßige Updates:
- **Screenshots**: Bei UI-Änderungen aktualisieren
- **Features**: Bei neuen App-Features erweitern
- **Version**: Copyright-Jahr aktualisieren
- **Links**: Privacy Policy, Contributing Guide aktuell halten

### Monitoring:
- Prüfe GitHub Pages Status: https://github.com/stillmoment-app/stillmoment/deployments
- Teste alle Links regelmäßig
- Überprüfe Responsive Design auf verschiedenen Geräten

## Support & Fragen

Bei Fragen oder Problemen:
- **Issues**: https://github.com/stillmoment-app/stillmoment/issues
- **Email**: stillMoment@posteo.de
- **Maintainer**: @HelmutZechmann

---

**Letztes Update**: 2025-11-09
**Version**: 1.0
**Status**: ✅ Produktionsbereit (Screenshots fehlen noch)
