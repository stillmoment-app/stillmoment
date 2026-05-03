/* Library — Empty State + Content Guide Sheet (Ticket shared-039)
   Three empty-state directions + a localized content guide sheet (DE / EN).
   The "ⓘ" entry-point also lives in the Library nav bar so the guide is
   reachable once the library is no longer empty. */

const { useState: useStateLE, useEffect: useEffectLE } = React;
const { StatusBar: SB, TabBar: TB, Phone: Ph, Icons: Ic } = window.SM;

/* ---------- Shared ---------- */

const COPY = {
  de: {
    title: "Dein persönlicher Meditationsraum",
    body: "Importiere Meditationen von deinen Lieblingslehrern und erstelle so deine persönliche Bibliothek.",
    primary: "Meditation importieren",
    secondary: "Wo finde ich Meditationen?",
    headerTitle: "Geführte Meditationen",
    sheetTitle: "Wo finde ich Meditationen?",
    sheetIntro: "Eine kleine, kuratierte Auswahl. Kostenlos, frei zugänglich. Tippe einen Eintrag, um die Quelle im Browser zu öffnen.",
    sourcesLabel: "Quellen",
    note: "Links öffnen im System-Browser. Keine Tracking-Daten verlassen die App.",
    close: "Schließen",
  },
  en: {
    title: "Your Personal Meditation Space",
    body: "Bring meditations from your favorite teachers and build a library that's truly yours.",
    primary: "Import a meditation",
    secondary: "Where can I find meditations?",
    headerTitle: "Guided Meditations",
    sheetTitle: "Where to find meditations",
    sheetIntro: "A small, curated set. Free and openly accessible. Tap an entry to open the source in your browser.",
    sourcesLabel: "Sources",
    note: "Links open in the system browser. No tracking data leaves the app.",
    close: "Close",
  },
};

const SOURCES = {
  de: [
    {
      name: "Achtsamkeit & Selbstmitgefühl",
      author: "Jörg Mangold",
      desc: "MBSR, MSC, Körperscans. 3–49 Min. Als Arzt und Psychotherapeut zertifiziert.",
      host: "podcast",
    },
    {
      name: "Einfach meditieren",
      author: "Melissa Gein",
      desc: "Achtsamkeit, Selbstliebe, Schlaf. 6–19 Min. Direkt-Download via podcast.de.",
      host: "podcast.de",
    },
    {
      name: "Meditation-Download.de",
      author: null,
      desc: "Geführte Meditationen, kein Account nötig.",
      host: "meditation-download.de",
    },
    {
      name: "Zentrum für Achtsamkeit Köln",
      author: null,
      desc: "MBSR Body Scan, Sitzmeditation.",
      host: "achtsamkeit-koeln.de",
    },
  ],
  en: [
    {
      name: "Dharma Seed",
      author: null,
      desc: "Thousands of dharma talks & guided meditations. Direct MP3.",
      host: "dharmaseed.org",
    },
    {
      name: "Audio Dharma",
      author: "Gil Fronsdal",
      desc: "Vipassana tradition. Direct MP3.",
      host: "audiodharma.org",
    },
    {
      name: "Tara Brach",
      author: null,
      desc: "Guided meditations, RAIN practice. Direct MP3.",
      host: "tarabrach.com",
    },
    {
      name: "Jack Kornfield",
      author: null,
      desc: "Lovingkindness, forgiveness practices.",
      host: "jackkornfield.com",
    },
    {
      name: "UCLA Mindful",
      author: null,
      desc: "Research-based mindfulness. German translations also available.",
      host: "uclahealth.org",
    },
    {
      name: "Free Mindfulness Project",
      author: null,
      desc: "Creative-commons licensed, freely shareable.",
      host: "freemindfulness.org",
    },
  ],
};

/* ---------- Icons ---------- */

const InfoIcon = (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6"
       strokeLinecap="round" strokeLinejoin="round">
    <circle cx="12" cy="12" r="9"/>
    <path d="M12 11 V17"/>
    <circle cx="12" cy="7.6" r="0.6" fill="currentColor"/>
  </svg>
);

const PlusIcon = (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round">
    <path d="M12 6 V18"/><path d="M6 12 H18"/>
  </svg>
);

const ChevR = (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6"
       strokeLinecap="round" strokeLinejoin="round">
    <path d="M9 6 L15 12 L9 18"/>
  </svg>
);

const ExternalIcon = (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6"
       strokeLinecap="round" strokeLinejoin="round">
    <path d="M14 5 H19 V10"/>
    <path d="M19 5 L11 13"/>
    <path d="M18 14 V18 A2 2 0 0 1 16 20 H7 A2 2 0 0 1 5 18 V9 A2 2 0 0 1 7 7 H11"/>
  </svg>
);

/* ---------- Waveform glyphs ---------- */

function WaveformStatic({ size = 96, opacity = 1 }) {
  // Three stacked sine ribbons, soft fade edges — SF Symbols `waveform` feel
  return (
    <svg width={size} height={size * 0.6} viewBox="0 0 160 96"
         style={{ display: "block", opacity }}>
      <defs>
        <linearGradient id="wfFade" x1="0" x2="1" y1="0" y2="0">
          <stop offset="0" stopColor="var(--sm-accent-glow)" stopOpacity="0"/>
          <stop offset="0.18" stopColor="var(--sm-accent-glow)" stopOpacity="1"/>
          <stop offset="0.82" stopColor="var(--sm-accent-glow)" stopOpacity="1"/>
          <stop offset="1" stopColor="var(--sm-accent-glow)" stopOpacity="0"/>
        </linearGradient>
        <linearGradient id="wfFade2" x1="0" x2="1" y1="0" y2="0">
          <stop offset="0" stopColor="var(--sm-accent-text)" stopOpacity="0"/>
          <stop offset="0.18" stopColor="var(--sm-accent-text)" stopOpacity="0.55"/>
          <stop offset="0.82" stopColor="var(--sm-accent-text)" stopOpacity="0.55"/>
          <stop offset="1" stopColor="var(--sm-accent-text)" stopOpacity="0"/>
        </linearGradient>
      </defs>
      <path d="M0 48 C 24 48, 24 30, 48 30 S 72 48, 96 48 S 120 66, 144 66 S 160 48, 160 48"
            fill="none" stroke="url(#wfFade)" strokeWidth="2.4" strokeLinecap="round"/>
      <path d="M0 48 C 24 48, 24 22, 48 22 S 72 48, 96 48 S 120 74, 144 74 S 160 48, 160 48"
            fill="none" stroke="url(#wfFade2)" strokeWidth="1.6" strokeLinecap="round" opacity="0.7"/>
      <path d="M0 48 C 24 48, 24 38, 48 38 S 72 48, 96 48 S 120 58, 144 58 S 160 48, 160 48"
            fill="none" stroke="url(#wfFade2)" strokeWidth="1.2" strokeLinecap="round" opacity="0.5"/>
    </svg>
  );
}

function WaveformBars({ count = 9, height = 64 }) {
  // Center-symmetric bar waveform like SF Symbols `waveform`
  // Heights modulated, peak at center, soft edges
  const bars = Array.from({ length: count }, (_, i) => {
    const t = i / (count - 1);          // 0..1
    const mid = 1 - Math.abs(t * 2 - 1); // triangular
    const wave = 0.45 + 0.55 * Math.pow(mid, 0.6);
    return wave;
  });
  return (
    <div style={{
      display: "flex", alignItems: "center", justifyContent: "center",
      gap: 6, height,
    }}>
      {bars.map((h, i) => (
        <div key={i} style={{
          width: 4,
          height: `${h * 100}%`,
          borderRadius: 2,
          background: "linear-gradient(180deg, var(--sm-accent-glow), var(--sm-accent-soft))",
          opacity: 0.65 + 0.35 * h,
        }}/>
      ))}
    </div>
  );
}

/* ---------- Empty State A — Treu zur Spec (faithful) ---------- */

function EmptyStateA({ locale = "de", onImport, onGuide, onOpenGuide, activeTab = "med", setActiveTab }) {
  const t = COPY[locale];
  return (
    <Ph label={`Library Empty — A. Faithful (${locale.toUpperCase()})`}>
      <SB/>
      {/* Top nav: hamburger · title · + · ⓘ */}
      <div className="screen-content">
        <div style={{
          display: "flex", alignItems: "center", justifyContent: "space-between",
          padding: "8px 20px 16px",
        }}>
          <button className="icon-btn press" aria-label="Menü" style={{ width: 36, height: 36 }}>
            <span style={{ width: 16, height: 16 }}>
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round">
                <path d="M5 8 H19"/><path d="M5 16 H19"/>
              </svg>
            </span>
          </button>
          <div className="h-display" style={{ fontSize: 18 }}>{t.headerTitle}</div>
          <div style={{ display: "flex", gap: 8 }}>
            <button className="icon-btn press" aria-label="Importieren"
              onClick={onImport} style={{ width: 36, height: 36 }}>
              <span style={{ width: 16, height: 16 }}>{PlusIcon}</span>
            </button>
            <button className="icon-btn press" aria-label={t.secondary}
              onClick={onOpenGuide} style={{ width: 36, height: 36 }}>
              <span style={{ width: 16, height: 16 }}>{InfoIcon}</span>
            </button>
          </div>
        </div>

        {/* Empty content */}
        <div style={{
          display: "flex", flexDirection: "column", alignItems: "center",
          justifyContent: "center",
          padding: "80px 36px 0",
          textAlign: "center",
        }}>
          {/* Waveform */}
          <div style={{
            width: 120, height: 120, borderRadius: "50%",
            display: "flex", alignItems: "center", justifyContent: "center",
            background: "radial-gradient(circle, var(--sm-accent-dim) 0%, transparent 65%)",
            marginBottom: 32,
          }}>
            <WaveformStatic size={104}/>
          </div>

          <div className="h-display" style={{ fontSize: 26, lineHeight: 1.18, maxWidth: 260, marginBottom: 14 }}>
            {t.title}
          </div>
          <div style={{
            fontSize: 14, lineHeight: 1.55, color: "var(--sm-text-2)",
            maxWidth: 280, marginBottom: 36,
          }}>
            {t.body}
          </div>

          <button className="btn-primary press" onClick={onImport}
            style={{ fontSize: 15, padding: "14px 28px" }}>
            <span style={{ width: 16, height: 16, color: "#2a1208" }}>{PlusIcon}</span>
            {t.primary}
          </button>

          <button onClick={onGuide} className="press" style={{
            marginTop: 22,
            background: "transparent",
            border: "none",
            color: "var(--sm-accent-text)",
            fontFamily: "inherit",
            fontSize: 14,
            padding: "8px 12px",
            cursor: "pointer",
            textDecoration: "underline",
            textUnderlineOffset: "4px",
            textDecorationColor: "rgba(217,154,126,0.35)",
          }}>
            {t.secondary}
          </button>
        </div>
      </div>
      <TB active={activeTab} onChange={setActiveTab}/>
    </Ph>
  );
}

/* ---------- Empty State B — Atmend (breathing) ---------- */

function EmptyStateB({ locale = "de", onImport, onGuide, onOpenGuide, activeTab = "med", setActiveTab }) {
  const t = COPY[locale];
  return (
    <Ph label={`Library Empty — B. Breathing (${locale.toUpperCase()})`}>
      <SB/>
      <div className="screen-content">
        <div style={{
          display: "flex", alignItems: "center", justifyContent: "space-between",
          padding: "8px 20px 8px",
        }}>
          <div className="h-display" style={{ fontSize: 18 }}>{t.headerTitle}</div>
          <div style={{ display: "flex", gap: 8 }}>
            <button className="icon-btn press" onClick={onImport} style={{ width: 36, height: 36 }} aria-label="Importieren">
              <span style={{ width: 16, height: 16 }}>{PlusIcon}</span>
            </button>
            <button className="icon-btn press" onClick={onOpenGuide} style={{ width: 36, height: 36 }} aria-label={t.secondary}>
              <span style={{ width: 16, height: 16 }}>{InfoIcon}</span>
            </button>
          </div>
        </div>

        <div style={{
          display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center",
          padding: "60px 36px 0", textAlign: "center", position: "relative",
        }}>
          {/* Concentric pulse rings */}
          <div style={{ position: "relative", width: 220, height: 140, marginBottom: 28 }}>
            {[0, 1, 2].map(i => (
              <div key={i} style={{
                position: "absolute", inset: i * 22,
                borderRadius: "50%",
                border: "1px solid var(--sm-accent)",
                opacity: 0.32 - i * 0.08,
                animation: `sm-pulse 4.4s ease-in-out ${i * 0.6}s infinite`,
              }}/>
            ))}
            <div style={{
              position: "absolute", inset: 0,
              display: "flex", alignItems: "center", justifyContent: "center",
            }}>
              <WaveformBars count={11} height={56}/>
            </div>
          </div>

          <div style={{
            fontSize: 11, letterSpacing: "0.18em", textTransform: "uppercase",
            color: "var(--sm-accent-text)", marginBottom: 14, fontWeight: 500,
          }}>
            {locale === "de" ? "Noch keine Meditationen" : "No meditations yet"}
          </div>
          <div className="h-display" style={{ fontSize: 28, lineHeight: 1.15, maxWidth: 280, marginBottom: 16 }}>
            {t.title}
          </div>
          <div style={{ fontSize: 14, lineHeight: 1.55, color: "var(--sm-text-2)", maxWidth: 290, marginBottom: 32 }}>
            {t.body}
          </div>

          <button className="btn-primary press" onClick={onImport}
            style={{ fontSize: 15, padding: "14px 28px" }}>
            <span style={{ width: 16, height: 16, color: "#2a1208" }}>{PlusIcon}</span>
            {t.primary}
          </button>

          <button onClick={onGuide} className="press" style={{
            marginTop: 18,
            background: "transparent", border: "none",
            color: "var(--sm-accent-text)", fontFamily: "inherit",
            fontSize: 14, padding: "8px 12px", cursor: "pointer",
          }}>
            {t.secondary} →
          </button>
        </div>
      </div>
      <TB active={activeTab} onChange={setActiveTab}/>

      <style>{`
        @keyframes sm-pulse {
          0%   { transform: scale(0.92); opacity: 0; }
          25%  { opacity: 0.32; }
          100% { transform: scale(1.18); opacity: 0; }
        }
      `}</style>
    </Ph>
  );
}

/* ---------- Empty State C — Editorial / poetic ---------- */

function EmptyStateC({ locale = "de", onImport, onGuide, onOpenGuide, activeTab = "med", setActiveTab }) {
  const t = COPY[locale];
  return (
    <Ph label={`Library Empty — C. Editorial (${locale.toUpperCase()})`}>
      <SB/>
      <div className="screen-content">
        <div style={{
          display: "flex", alignItems: "center", justifyContent: "space-between",
          padding: "8px 20px 0",
        }}>
          <div className="h-display" style={{ fontSize: 18 }}>{t.headerTitle}</div>
          <div style={{ display: "flex", gap: 8 }}>
            <button className="icon-btn press" onClick={onImport} style={{ width: 36, height: 36 }} aria-label="Importieren">
              <span style={{ width: 16, height: 16 }}>{PlusIcon}</span>
            </button>
            <button className="icon-btn press" onClick={onOpenGuide} style={{ width: 36, height: 36 }} aria-label={t.secondary}>
              <span style={{ width: 16, height: 16 }}>{InfoIcon}</span>
            </button>
          </div>
        </div>

        {/* Big quiet card */}
        <div style={{ padding: "28px 20px 0" }}>
          <div style={{
            position: "relative",
            background: "linear-gradient(160deg, #3a201a 0%, #2a1610 55%, #1a0c08 100%)",
            border: "1px solid rgba(235,226,214,0.07)",
            borderRadius: 28,
            padding: "36px 26px 30px",
            overflow: "hidden",
            minHeight: 470,
          }}>
            {/* Background glow */}
            <div style={{
              position: "absolute", left: "50%", top: 60, transform: "translateX(-50%)",
              width: 320, height: 320, borderRadius: "50%",
              background: "radial-gradient(circle, rgba(214,138,110,0.16) 0%, transparent 65%)",
              pointerEvents: "none",
            }}/>

            <div style={{ position: "relative", display: "flex", flexDirection: "column", alignItems: "center", textAlign: "center" }}>
              <div style={{ marginTop: 30, marginBottom: 32 }}>
                <WaveformStatic size={150}/>
              </div>

              <div style={{
                fontSize: 11, letterSpacing: "0.2em", textTransform: "uppercase",
                color: "var(--sm-accent-text)", marginBottom: 14, fontWeight: 500,
              }}>
                {locale === "de" ? "Bring your own" : "Bring your own"}
              </div>

              <div className="h-display" style={{ fontSize: 30, lineHeight: 1.1, maxWidth: 270, marginBottom: 18 }}>
                {t.title}
              </div>
              <div style={{ fontSize: 14, lineHeight: 1.55, color: "var(--sm-text-2)", maxWidth: 280, marginBottom: 30 }}>
                {t.body}
              </div>

              <button className="btn-primary press" onClick={onImport}
                style={{ fontSize: 15, padding: "14px 28px", width: "100%", justifyContent: "center", maxWidth: 280 }}>
                <span style={{ width: 16, height: 16, color: "#2a1208" }}>{PlusIcon}</span>
                {t.primary}
              </button>
            </div>
          </div>
        </div>

        {/* Sekundäre Aktion außerhalb der Karte */}
        <div style={{ display: "flex", justifyContent: "center", padding: "18px 0 0" }}>
          <button onClick={onGuide} className="press" style={{
            background: "transparent", border: "1px solid rgba(235,226,214,0.08)",
            color: "var(--sm-text)", fontFamily: "inherit",
            fontSize: 13, padding: "10px 18px", borderRadius: 999, cursor: "pointer",
            display: "inline-flex", alignItems: "center", gap: 8,
          }}>
            <span style={{ width: 14, height: 14, color: "var(--sm-accent-text)", display: "inline-flex" }}>{InfoIcon}</span>
            {t.secondary}
          </button>
        </div>
      </div>
      <TB active={activeTab} onChange={setActiveTab}/>
    </Ph>
  );
}

/* ---------- Library populated — shows the persistent ⓘ entry ---------- */

const LIB_TRACKS = [
  { author: "Joerg Mangold",    title: "Atemraum am Morgen",    dur: "12:08" },
  { author: "Joerg Mangold",    title: "Body Scan, lang",       dur: "32:45" },
  { author: "Melissa Gein",     title: "Selbstmitgefühl",       dur: "9:22" },
  { author: "Eigene Aufnahme",  title: "Maria's Stimme",        dur: "4:12" },
];

function LibraryPopulatedWithGuide({ locale = "de", onOpenGuide, onImport, activeTab = "med", setActiveTab }) {
  const t = COPY[locale];
  const groups = LIB_TRACKS.reduce((a, x) => {
    (a[x.author] = a[x.author] || []).push(x); return a;
  }, {});

  return (
    <Ph label={`Library Populated — Guide reachable (${locale.toUpperCase()})`}>
      <SB/>
      <div className="screen-content scrollable">
        <div style={{
          display: "flex", alignItems: "center", justifyContent: "space-between",
          padding: "8px 20px 16px",
        }}>
          <div className="h-display" style={{ fontSize: 22 }}>{t.headerTitle}</div>
          <div style={{ display: "flex", gap: 8 }}>
            <button className="icon-btn press" onClick={onImport} style={{ width: 38, height: 38 }} aria-label="Importieren">
              <span style={{ width: 17, height: 17 }}>{PlusIcon}</span>
            </button>
            <button className="icon-btn press" onClick={onOpenGuide} style={{ width: 38, height: 38 }} aria-label={t.secondary}>
              <span style={{ width: 17, height: 17 }}>{InfoIcon}</span>
            </button>
          </div>
        </div>

        <div style={{ padding: "0 18px 110px" }}>
          {Object.entries(groups).map(([author, items]) => (
            <div key={author} style={{ marginBottom: 18 }}>
              <div style={{ display: "flex", alignItems: "baseline", justifyContent: "space-between", padding: "0 6px 8px" }}>
                <div style={{ fontSize: 16, fontFamily: "var(--sm-font-display)", color: "var(--sm-text)" }}>{author}</div>
                <div style={{ fontSize: 11, color: "var(--sm-text-3)", letterSpacing: "0.08em", textTransform: "uppercase" }}>
                  {items.length} {locale === "de" ? (items.length === 1 ? "Sitzung" : "Sitzungen") : (items.length === 1 ? "session" : "sessions")}
                </div>
              </div>
              <div className="card">
                {items.map((x, i) => (
                  <div key={x.title} style={{
                    borderTop: i === 0 ? "none" : "1px solid rgba(235,226,214,0.04)",
                    display: "flex", alignItems: "center", gap: 12,
                    padding: "14px 16px",
                  }}>
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ fontSize: 15, fontFamily: "var(--sm-font-display)", color: "var(--sm-text)" }}>{x.title}</div>
                      <div style={{ fontSize: 12, color: "var(--sm-text-2)", marginTop: 2 }}>{x.dur}</div>
                    </div>
                    <div style={{
                      width: 36, height: 36, borderRadius: "50%",
                      background: "linear-gradient(180deg, #d68a6e, #b06a4f)",
                      display: "inline-flex", alignItems: "center", justifyContent: "center",
                      boxShadow: "0 4px 12px rgba(196,122,94,0.4)",
                    }}>
                      <svg viewBox="0 0 24 24" width="16" height="16" fill="#2a1208" style={{ marginLeft: 2 }}>
                        <path d="M8 5 V19 L19 12 Z"/>
                      </svg>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          ))}

          {/* Hint card pointing at the persistent guide entry */}
          <button onClick={onOpenGuide} className="press" style={{
            width: "100%",
            display: "flex", alignItems: "center", gap: 14,
            padding: "14px 16px",
            marginTop: 6,
            background: "rgba(196,122,94,0.06)",
            border: "1px dashed rgba(196,122,94,0.22)",
            borderRadius: 18,
            color: "var(--sm-text)",
            fontFamily: "inherit",
            cursor: "pointer",
            textAlign: "left",
          }}>
            <span style={{
              width: 28, height: 28, borderRadius: "50%",
              background: "var(--sm-accent-dim)", color: "var(--sm-accent-text)",
              display: "inline-flex", alignItems: "center", justifyContent: "center",
            }}>
              <span style={{ width: 14, height: 14 }}>{InfoIcon}</span>
            </span>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 14 }}>{t.secondary}</div>
              <div style={{ fontSize: 11, color: "var(--sm-text-2)", marginTop: 2 }}>
                {locale === "de"
                  ? "Kuratierte Quellen — jederzeit hier oder über das ⓘ-Symbol oben."
                  : "Curated sources — always here, or via the ⓘ icon above."}
              </div>
            </div>
            <span style={{ width: 16, height: 16, color: "var(--sm-text-3)" }}>{ChevR}</span>
          </button>
        </div>
      </div>
      <TB active={activeTab} onChange={setActiveTab}/>
    </Ph>
  );
}

/* ---------- Content Guide Sheet ---------- */

function GuideSheet({ locale = "de", onClose, activeTab = "med", setActiveTab, label }) {
  const t = COPY[locale];
  const sources = SOURCES[locale];

  return (
    <Ph label={label || `Content Guide Sheet (${locale.toUpperCase()})`}>
      <SB/>

      {/* Dimmed underlay (suggests sheet) */}
      <div style={{
        position: "absolute", inset: 54, background: "rgba(10,6,4,0.55)",
        pointerEvents: "none",
      }}/>

      {/* Faint Library traces under the sheet */}
      <div style={{
        position: "absolute", inset: "54px 20px 0 20px", opacity: 0.18,
        pointerEvents: "none",
      }}>
        <div className="h-display" style={{ fontSize: 22, padding: "8px 0 16px" }}>{t.headerTitle}</div>
      </div>

      {/* Sheet */}
      <div style={{
        position: "absolute", left: 0, right: 0, bottom: 0,
        background: "linear-gradient(180deg, #2a1812 0%, #1d100b 100%)",
        borderTop: "1px solid rgba(235,226,214,0.08)",
        borderTopLeftRadius: 28, borderTopRightRadius: 28,
        boxShadow: "0 -20px 60px rgba(0,0,0,0.5)",
        height: 720,
        display: "flex", flexDirection: "column",
        overflow: "hidden",
      }}>
        {/* Grabber */}
        <div style={{ display: "flex", justifyContent: "center", padding: "10px 0 6px" }}>
          <div style={{ width: 38, height: 4, borderRadius: 999, background: "rgba(235,226,214,0.18)" }}/>
        </div>

        {/* Title row */}
        <div style={{
          display: "flex", alignItems: "center", justifyContent: "space-between",
          padding: "8px 22px 18px",
        }}>
          <div className="h-display" style={{ fontSize: 22 }}>{t.sheetTitle}</div>
          <button onClick={onClose} className="press" style={{
            width: 30, height: 30, borderRadius: "50%",
            background: "rgba(235,226,214,0.06)", border: "none", color: "var(--sm-text-2)",
            cursor: "pointer", display: "inline-flex", alignItems: "center", justifyContent: "center",
          }} aria-label={t.close}>
            <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
              <path d="M6 6 L18 18"/><path d="M18 6 L6 18"/>
            </svg>
          </button>
        </div>

        {/* Intro */}
        <div style={{
          padding: "0 22px 16px",
          fontSize: 13, lineHeight: 1.55, color: "var(--sm-text-2)",
        }}>
          {t.sheetIntro}
        </div>

        {/* Section header */}
        <div style={{
          padding: "0 22px 8px",
          display: "flex", alignItems: "baseline", justifyContent: "space-between",
        }}>
          <div className="h-section">
            {t.sourcesLabel} · {locale === "de" ? "Deutsch" : "English"}
          </div>
          <div style={{ fontSize: 11, color: "var(--sm-text-3)" }}>{sources.length}</div>
        </div>

        {/* Source list — scrollable */}
        <div style={{
          flex: 1, overflowY: "auto",
          padding: "0 18px 18px",
        }}>
          <div className="card" style={{ background: "rgba(255,255,255,0.02)" }}>
            {sources.map((s, i) => (
              <a key={s.name} href="#" onClick={(e) => e.preventDefault()}
                 className="press"
                 style={{
                   display: "flex", alignItems: "center", gap: 12,
                   padding: "14px 16px",
                   borderTop: i === 0 ? "none" : "1px solid rgba(235,226,214,0.05)",
                   color: "var(--sm-text)",
                   textDecoration: "none",
                 }}>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: "flex", alignItems: "baseline", gap: 8, flexWrap: "wrap" }}>
                    <div style={{ fontSize: 15, fontFamily: "var(--sm-font-display)" }}>{s.name}</div>
                    {s.author && (
                      <div style={{ fontSize: 12, color: "var(--sm-text-2)" }}>
                        · {s.author}
                      </div>
                    )}
                  </div>
                  <div style={{ fontSize: 12, color: "var(--sm-text-2)", marginTop: 4, lineHeight: 1.45 }}>
                    {s.desc}
                  </div>
                  <div style={{
                    fontSize: 12, color: "var(--sm-text-3)", marginTop: 6,
                    letterSpacing: "0.01em",
                  }}>
                    {s.host}
                  </div>
                </div>
                <span style={{
                  width: 22, height: 22,
                  display: "inline-flex", alignItems: "center", justifyContent: "center",
                  color: "var(--sm-accent-text)",
                  flexShrink: 0,
                }}>{ExternalIcon}</span>
              </a>
            ))}
          </div>

          {/* Footnote */}
          <div style={{
            display: "flex", gap: 10, alignItems: "flex-start",
            padding: "16px 8px 0",
            color: "var(--sm-text-3)", fontSize: 11, lineHeight: 1.55,
          }}>
            <span style={{ width: 14, height: 14, marginTop: 2, color: "var(--sm-text-3)", flexShrink: 0 }}>
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round">
                <circle cx="12" cy="12" r="9"/>
                <path d="M12 11 V17"/>
                <circle cx="12" cy="7.6" r="0.6" fill="currentColor"/>
              </svg>
            </span>
            <span>{t.note}</span>
          </div>
        </div>
      </div>

      <TB active={activeTab} onChange={setActiveTab}/>
    </Ph>
  );
}

window.SM_LibraryEmpty = {
  EmptyStateA, EmptyStateB, EmptyStateC,
  LibraryPopulatedWithGuide,
  GuideSheet,
};
