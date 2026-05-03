/* Import flow — Ticket follow-up
   - Action sheet from "+" with three paths (Files / URL paste / Clipboard)
   - "Importieren als..." sheet redesigned in warm dark
   - Atmender Loading-Modal
   - In-App import guide (3 steps: Long-press → Teilen → Still Moment) */

const { useState: useStateIF, useEffect: useEffectIF } = React;
const { StatusBar: SBI, TabBar: TBI, Phone: PhI } = window.SM;

/* ---------- Icons ---------- */

const PlusIconHT = (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8"
       strokeLinecap="round">
    <path d="M12 5 V19"/><path d="M5 12 H19"/>
  </svg>
);
const FilesIcon = (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6"
       strokeLinecap="round" strokeLinejoin="round">
    <path d="M5 5 A2 2 0 0 1 7 3 H13 L17 7 V19 A2 2 0 0 1 15 21 H7 A2 2 0 0 1 5 19 Z"/>
    <path d="M13 3 V7 H17"/>
  </svg>
);
const LinkIcon = (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6"
       strokeLinecap="round" strokeLinejoin="round">
    <path d="M10 14 A4 4 0 0 1 10 8 L13 5 A4 4 0 0 1 19 11 L17 13"/>
    <path d="M14 10 A4 4 0 0 1 14 16 L11 19 A4 4 0 0 1 5 13 L7 11"/>
  </svg>
);
const ClipboardIcon = (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6"
       strokeLinecap="round" strokeLinejoin="round">
    <rect x="6" y="5" width="12" height="16" rx="2"/>
    <path d="M9 5 V4 A1 1 0 0 1 10 3 H14 A1 1 0 0 1 15 4 V5"/>
    <path d="M9 11 H15"/>
    <path d="M9 15 H13"/>
  </svg>
);
const PlayBadgeIcon = (
  <svg viewBox="0 0 24 24" fill="currentColor">
    <path d="M8 5 V19 L19 12 Z"/>
  </svg>
);
const CheckBadgeIcon = (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6"
       strokeLinecap="round" strokeLinejoin="round">
    <circle cx="12" cy="12" r="9"/>
    <path d="M8 12.5 L11 15.5 L16 9.5"/>
  </svg>
);
const WaveIcon = (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6"
       strokeLinecap="round">
    <path d="M4 12 V12"/>
    <path d="M8 9 V15"/>
    <path d="M12 6 V18"/>
    <path d="M16 9 V15"/>
    <path d="M20 12 V12"/>
  </svg>
);
const WindIcon = (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6"
       strokeLinecap="round" strokeLinejoin="round">
    <path d="M3 9 H14 A3 3 0 1 0 11 6"/>
    <path d="M3 14 H18 A3 3 0 1 1 15 17"/>
  </svg>
);
const LongPressIcon = (
  <svg viewBox="0 0 32 32" fill="none" stroke="currentColor" strokeWidth="1.4"
       strokeLinecap="round" strokeLinejoin="round">
    <circle cx="16" cy="16" r="6" opacity="0.35"/>
    <circle cx="16" cy="16" r="9" opacity="0.18"/>
    <circle cx="16" cy="16" r="3" fill="currentColor" stroke="none"/>
  </svg>
);
const ShareIcon = (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6"
       strokeLinecap="round" strokeLinejoin="round">
    <path d="M12 4 V16"/>
    <path d="M8 8 L12 4 L16 8"/>
    <rect x="5" y="13" width="14" height="8" rx="2"/>
  </svg>
);
const FlameSquare = (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6"
       strokeLinecap="round" strokeLinejoin="round">
    <path d="M12 21 C7 21 5 17 6 14 C7 11 9 11 9 8 C9 6 11 5 12 3 C12 7 16 8 17 12 C18 16 16 21 12 21 Z"/>
  </svg>
);
const CloseX = (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
    <path d="M6 6 L18 18"/><path d="M18 6 L6 18"/>
  </svg>
);
const BackArrow = (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
    <path d="M15 6 L9 12 L15 18"/>
  </svg>
);

/* ---------- Reusable bits ---------- */

function SheetShell({ children, height = 720 }) {
  return (
    <div style={{
      position: "absolute", left: 0, right: 0, bottom: 0,
      background: "linear-gradient(180deg, #2a1812 0%, #1d100b 100%)",
      borderTop: "1px solid rgba(235,226,214,0.08)",
      borderTopLeftRadius: 28, borderTopRightRadius: 28,
      boxShadow: "0 -20px 60px rgba(0,0,0,0.5)",
      height,
      display: "flex", flexDirection: "column", overflow: "hidden",
    }}>
      <div style={{ display: "flex", justifyContent: "center", padding: "10px 0 6px" }}>
        <div style={{ width: 38, height: 4, borderRadius: 999, background: "rgba(235,226,214,0.18)" }}/>
      </div>
      {children}
    </div>
  );
}

function SheetBackdrop() {
  return (
    <div style={{
      position: "absolute", inset: 54,
      background: "rgba(10,6,4,0.55)", pointerEvents: "none",
    }}/>
  );
}

function FaintLibraryUnderlay({ title = "Geführte Meditationen" }) {
  return (
    <div style={{
      position: "absolute", inset: "54px 20px 0 20px", opacity: 0.18,
      pointerEvents: "none",
    }}>
      <div className="h-display" style={{ fontSize: 22, padding: "8px 0 16px" }}>{title}</div>
    </div>
  );
}

/* ---------- 1A. Plus-Sheet — three paths ---------- */

function PlusActionSheet({ onClose, hasClipboardURL = true, clipboardHost = "zentrum-fuer-achtsamkeit.koeln" }) {
  return (
    <PhI label="Plus → Action Sheet (drei Wege)">
      <SBI/>
      <SheetBackdrop/>
      <FaintLibraryUnderlay/>
      <SheetShell height={hasClipboardURL ? 500 : 430}>
        <div style={{ padding: "8px 22px 4px" }}>
          <div className="h-display" style={{ fontSize: 22 }}>Meditation hinzufügen</div>
          <div style={{ fontSize: 13, color: "var(--sm-text-2)", marginTop: 6, lineHeight: 1.5 }}>
            Importiere eine Audiodatei in deine Bibliothek.
          </div>
        </div>

        <div style={{ flex: 1, padding: "20px 18px 12px", display: "flex", flexDirection: "column", gap: 10 }}>
          {/* Clipboard suggestion (only if pasteboard contains URL) */}
          {hasClipboardURL && (
            <button onClick={onClose} className="press" style={{
              display: "flex", alignItems: "center", gap: 14,
              padding: "14px 16px",
              background: "rgba(196,122,94,0.10)",
              border: "1px solid rgba(196,122,94,0.30)",
              borderRadius: 18, color: "var(--sm-text)",
              fontFamily: "inherit", textAlign: "left", cursor: "pointer",
            }}>
              <span style={{
                width: 36, height: 36, borderRadius: "50%",
                background: "var(--sm-accent-dim)", color: "var(--sm-accent-text)",
                display: "inline-flex", alignItems: "center", justifyContent: "center", flexShrink: 0,
              }}>
                <span style={{ width: 18, height: 18 }}>{ClipboardIcon}</span>
              </span>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{
                  fontSize: 11, letterSpacing: "0.14em", textTransform: "uppercase",
                  color: "var(--sm-accent-text)", fontWeight: 500,
                }}>
                  Aus Zwischenablage
                </div>
                <div style={{ fontSize: 14, fontFamily: "var(--sm-font-display)", marginTop: 4, lineHeight: 1.3 }}>
                  Link erkannt
                </div>
                <div style={{
                  fontSize: 12, color: "var(--sm-text-2)", marginTop: 3,
                  whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis",
                }}>
                  {clipboardHost}
                </div>
              </div>
            </button>
          )}

          {/* Files */}
          <button onClick={onClose} className="press" style={{
            display: "flex", alignItems: "center", gap: 14,
            padding: "14px 16px",
            background: "var(--sm-card)",
            border: "1px solid var(--sm-card-line)",
            borderRadius: 18, color: "var(--sm-text)",
            fontFamily: "inherit", textAlign: "left", cursor: "pointer",
          }}>
            <span style={{
              width: 36, height: 36, borderRadius: "50%",
              background: "rgba(235,226,214,0.06)", color: "var(--sm-text)",
              display: "inline-flex", alignItems: "center", justifyContent: "center", flexShrink: 0,
            }}>
              <span style={{ width: 18, height: 18 }}>{FilesIcon}</span>
            </span>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 15, fontFamily: "var(--sm-font-display)" }}>Aus Dateien</div>
              <div style={{ fontSize: 12, color: "var(--sm-text-2)", marginTop: 2 }}>
                Audio aus iCloud, Downloads oder lokalen Ordnern
              </div>
            </div>
          </button>

          {/* URL paste */}
          <button onClick={onClose} className="press" style={{
            display: "flex", alignItems: "center", gap: 14,
            padding: "14px 16px",
            background: "var(--sm-card)",
            border: "1px solid var(--sm-card-line)",
            borderRadius: 18, color: "var(--sm-text)",
            fontFamily: "inherit", textAlign: "left", cursor: "pointer",
          }}>
            <span style={{
              width: 36, height: 36, borderRadius: "50%",
              background: "rgba(235,226,214,0.06)", color: "var(--sm-text)",
              display: "inline-flex", alignItems: "center", justifyContent: "center", flexShrink: 0,
            }}>
              <span style={{ width: 18, height: 18 }}>{LinkIcon}</span>
            </span>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 15, fontFamily: "var(--sm-font-display)" }}>Von URL einfügen</div>
              <div style={{ fontSize: 12, color: "var(--sm-text-2)", marginTop: 2 }}>
                Direkten mp3-Link eingeben
              </div>
            </div>
          </button>
        </div>

        {/* Hint to share-sheet flow */}
        <div style={{
          padding: "12px 22px 18px",
          borderTop: "1px solid rgba(235,226,214,0.05)",
          display: "flex", alignItems: "center", gap: 10,
        }}>
          <span style={{ width: 14, height: 14, color: "var(--sm-text-3)", flexShrink: 0 }}>
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round">
              <circle cx="12" cy="12" r="9"/>
              <path d="M12 11 V17"/>
              <circle cx="12" cy="7.6" r="0.6" fill="currentColor"/>
            </svg>
          </span>
          <div style={{ fontSize: 11, color: "var(--sm-text-3)", lineHeight: 1.5, flex: 1 }}>
            Tipp: Im Browser auf einen mp3-Link long-pressen → Teilen → Still Moment.
          </div>
        </div>
      </SheetShell>
    </PhI>
  );
}

/* ---------- 1B. Plus-Sheet — variant: URL input inline ---------- */

function PlusActionSheetB({ onClose }) {
  const [url, setUrl] = useStateIF("");
  return (
    <PhI label="Plus → Action Sheet (URL prominent)">
      <SBI/>
      <SheetBackdrop/>
      <FaintLibraryUnderlay/>
      <SheetShell height={580}>
        <div style={{ padding: "8px 22px 4px" }}>
          <div className="h-display" style={{ fontSize: 22 }}>Meditation hinzufügen</div>
        </div>

        <div style={{ flex: 1, padding: "18px 18px 12px", display: "flex", flexDirection: "column", gap: 14 }}>
          {/* URL input prominent */}
          <div style={{
            background: "var(--sm-card)",
            border: "1px solid var(--sm-card-line)",
            borderRadius: 18,
            padding: "16px 16px 14px",
          }}>
            <div style={{
              fontSize: 11, letterSpacing: "0.12em", textTransform: "uppercase",
              color: "var(--sm-text-3)", fontWeight: 500, marginBottom: 8,
            }}>
              Von URL
            </div>
            <input
              type="text"
              value={url}
              onChange={(e) => setUrl(e.target.value)}
              placeholder="https://… .mp3"
              style={{
                width: "100%",
                background: "rgba(0,0,0,0.25)",
                border: "1px solid rgba(235,226,214,0.06)",
                borderRadius: 12,
                padding: "12px 14px",
                color: "var(--sm-text)",
                fontFamily: "inherit", fontSize: 14,
                outline: "none",
              }}
            />
            <div style={{ display: "flex", gap: 8, marginTop: 10 }}>
              <button className="press" style={{
                flex: 1,
                background: "rgba(235,226,214,0.05)", border: "1px solid rgba(235,226,214,0.06)",
                color: "var(--sm-text-2)", fontFamily: "inherit", fontSize: 13,
                padding: "10px", borderRadius: 999, cursor: "pointer",
              }}>Aus Zwischenablage</button>
              <button className="press" style={{
                flex: 1,
                background: "linear-gradient(180deg, var(--sm-accent-glow), var(--sm-accent-soft))",
                border: "none", color: "#2a1208", fontFamily: "inherit", fontSize: 13, fontWeight: 500,
                padding: "10px", borderRadius: 999, cursor: "pointer",
              }}>Laden</button>
            </div>
          </div>

          <div style={{
            display: "flex", alignItems: "center", gap: 10,
            color: "var(--sm-text-3)", fontSize: 11, letterSpacing: "0.08em", textTransform: "uppercase",
          }}>
            <span style={{ flex: 1, height: 1, background: "rgba(235,226,214,0.08)" }}/>
            oder
            <span style={{ flex: 1, height: 1, background: "rgba(235,226,214,0.08)" }}/>
          </div>

          {/* Files */}
          <button onClick={onClose} className="press" style={{
            display: "flex", alignItems: "center", gap: 14,
            padding: "14px 16px",
            background: "var(--sm-card)",
            border: "1px solid var(--sm-card-line)",
            borderRadius: 18, color: "var(--sm-text)",
            fontFamily: "inherit", textAlign: "left", cursor: "pointer",
          }}>
            <span style={{
              width: 36, height: 36, borderRadius: "50%",
              background: "rgba(235,226,214,0.06)", color: "var(--sm-text)",
              display: "inline-flex", alignItems: "center", justifyContent: "center",
            }}>
              <span style={{ width: 18, height: 18 }}>{FilesIcon}</span>
            </span>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 15, fontFamily: "var(--sm-font-display)" }}>Aus Dateien</div>
              <div style={{ fontSize: 12, color: "var(--sm-text-2)", marginTop: 2 }}>
                Audio aus iCloud, Downloads oder lokalen Ordnern
              </div>
            </div>
          </button>
        </div>

        <div style={{
          padding: "12px 22px 18px",
          borderTop: "1px solid rgba(235,226,214,0.05)",
        }}>
          <div style={{ fontSize: 11, color: "var(--sm-text-3)", lineHeight: 1.5 }}>
            Tipp: Im Browser auf einen mp3-Link long-pressen → Teilen → Still Moment.
          </div>
        </div>
      </SheetShell>
    </PhI>
  );
}

/* ---------- 2A. "Importieren als..." — redesigned ---------- */

function ImportAsSheet({ onClose, fileName = "anleitung-bodyscan-deutsch-mbsr.mp3" }) {
  const opts = [
    { id: "med",     icon: PlayBadgeIcon, title: "Geführte Meditation", desc: "Zur Meditationsbibliothek hinzufügen", accent: true },
    { id: "ambient", icon: WaveIcon,      title: "Klangkulisse",         desc: "Als Hintergrundklang verwenden" },
    { id: "intro",   icon: WindIcon,      title: "Einstimmung",          desc: "Als Einstimmung verwenden" },
  ];
  return (
    <PhI label="Importieren als… (neu)">
      <SBI/>
      <SheetBackdrop/>
      <FaintLibraryUnderlay/>
      <SheetShell height={620}>
        <div style={{ padding: "8px 22px 4px" }}>
          <div className="h-display" style={{ fontSize: 22 }}>Importieren als…</div>
          <div style={{
            fontSize: 12, color: "var(--sm-text-2)", marginTop: 6, lineHeight: 1.45,
            wordBreak: "break-all",
          }}>
            {fileName}
          </div>
        </div>

        <div style={{ flex: 1, padding: "18px 18px 12px", display: "flex", flexDirection: "column", gap: 10 }}>
          {opts.map((o, i) => (
            <button key={o.id} onClick={onClose} className="press" style={{
              display: "flex", alignItems: "center", gap: 14,
              padding: "16px 16px",
              background: o.accent ? "rgba(196,122,94,0.08)" : "var(--sm-card)",
              border: o.accent ? "1px solid rgba(196,122,94,0.25)" : "1px solid var(--sm-card-line)",
              borderRadius: 18, color: "var(--sm-text)",
              fontFamily: "inherit", textAlign: "left", cursor: "pointer",
            }}>
              <span style={{
                width: 40, height: 40, borderRadius: "50%",
                background: o.accent
                  ? "linear-gradient(180deg, var(--sm-accent-glow), var(--sm-accent-soft))"
                  : "rgba(235,226,214,0.06)",
                color: o.accent ? "#2a1208" : "var(--sm-text)",
                display: "inline-flex", alignItems: "center", justifyContent: "center", flexShrink: 0,
                boxShadow: o.accent ? "0 4px 12px rgba(196,122,94,0.3)" : "none",
              }}>
                <span style={{ width: 18, height: 18, marginLeft: o.id === "med" ? 2 : 0 }}>{o.icon}</span>
              </span>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 16, fontFamily: "var(--sm-font-display)", color: "var(--sm-text)" }}>
                  {o.title}
                </div>
                <div style={{ fontSize: 12, color: "var(--sm-text-2)", marginTop: 3 }}>
                  {o.desc}
                </div>
              </div>
              {o.accent && (
                <span style={{
                  fontSize: 10, letterSpacing: "0.12em", textTransform: "uppercase",
                  color: "var(--sm-accent-text)", fontWeight: 500,
                  padding: "4px 10px", borderRadius: 999, background: "var(--sm-accent-dim)",
                }}>
                  Häufig
                </span>
              )}
            </button>
          ))}
        </div>

        <div style={{ padding: "0 18px 18px" }}>
          <button onClick={onClose} className="press" style={{
            width: "100%",
            background: "rgba(235,226,214,0.04)",
            border: "1px solid rgba(235,226,214,0.07)",
            color: "var(--sm-text)", fontFamily: "inherit", fontSize: 15,
            padding: "14px", borderRadius: 999, cursor: "pointer",
          }}>
            Abbrechen
          </button>
        </div>
      </SheetShell>
    </PhI>
  );
}

/* ---------- 2B. Importieren als — variant: vertical stacked, more poetic ---------- */

function ImportAsSheetB({ onClose, fileName = "anleitung-bodyscan-deutsch-mbsr.mp3" }) {
  const [pick, setPick] = useStateIF("med");
  const opts = [
    { id: "med",     icon: PlayBadgeIcon, title: "Geführte Meditation" },
    { id: "ambient", icon: WaveIcon,      title: "Klangkulisse" },
    { id: "intro",   icon: WindIcon,      title: "Einstimmung" },
  ];
  const descs = {
    med:     "Wird in deiner Meditationsbibliothek gespeichert. Du kannst sie aus dem Timer oder der Bibliothek starten.",
    ambient: "Wird als sanfter Hintergrundklang während einer Sitzung abgespielt — mit eigener Lautstärke.",
    intro:   "Wird vor jeder Sitzung als kurze Einstimmung abgespielt — eine Brücke in die Stille.",
  };
  return (
    <PhI label="Importieren als… (Variante B)">
      <SBI/>
      <SheetBackdrop/>
      <FaintLibraryUnderlay/>
      <SheetShell height={680}>
        <div style={{ padding: "8px 22px 4px" }}>
          <div style={{
            fontSize: 11, letterSpacing: "0.18em", textTransform: "uppercase",
            color: "var(--sm-accent-text)", fontWeight: 500, marginBottom: 6,
          }}>
            Importieren als
          </div>
          <div className="h-display" style={{ fontSize: 22, lineHeight: 1.2 }}>
            Wofür möchtest du diese Aufnahme verwenden?
          </div>
          <div style={{ fontSize: 12, color: "var(--sm-text-3)", marginTop: 10, lineHeight: 1.45, wordBreak: "break-all" }}>
            {fileName}
          </div>
        </div>

        <div style={{ flex: 1, padding: "20px 18px 12px", display: "flex", flexDirection: "column", gap: 8 }}>
          {opts.map(o => {
            const active = pick === o.id;
            return (
              <button key={o.id} onClick={() => setPick(o.id)} className="press" style={{
                display: "flex", alignItems: "center", gap: 14,
                padding: "14px 16px",
                background: active ? "rgba(196,122,94,0.10)" : "transparent",
                border: active ? "1px solid rgba(196,122,94,0.30)" : "1px solid rgba(235,226,214,0.06)",
                borderRadius: 16, color: "var(--sm-text)",
                fontFamily: "inherit", textAlign: "left", cursor: "pointer",
              }}>
                <span style={{
                  width: 32, height: 32, borderRadius: "50%",
                  background: active ? "var(--sm-accent-dim)" : "rgba(235,226,214,0.05)",
                  color: active ? "var(--sm-accent-text)" : "var(--sm-text-2)",
                  display: "inline-flex", alignItems: "center", justifyContent: "center", flexShrink: 0,
                }}>
                  <span style={{ width: 16, height: 16, marginLeft: o.id === "med" ? 2 : 0 }}>{o.icon}</span>
                </span>
                <div style={{ flex: 1, fontSize: 15, fontFamily: "var(--sm-font-display)" }}>
                  {o.title}
                </div>
                <span style={{
                  width: 18, height: 18, borderRadius: "50%",
                  border: "1.5px solid " + (active ? "var(--sm-accent)" : "rgba(235,226,214,0.18)"),
                  display: "inline-flex", alignItems: "center", justifyContent: "center",
                }}>
                  {active && <span style={{ width: 8, height: 8, borderRadius: "50%", background: "var(--sm-accent)" }}/>}
                </span>
              </button>
            );
          })}

          <div style={{
            marginTop: 10,
            padding: "12px 14px",
            background: "rgba(0,0,0,0.18)",
            borderRadius: 14,
            fontSize: 12, color: "var(--sm-text-2)", lineHeight: 1.55,
          }}>
            {descs[pick]}
          </div>
        </div>

        <div style={{ padding: "0 18px 18px", display: "flex", gap: 10 }}>
          <button onClick={onClose} className="press" style={{
            flex: 1,
            background: "rgba(235,226,214,0.04)",
            border: "1px solid rgba(235,226,214,0.07)",
            color: "var(--sm-text)", fontFamily: "inherit", fontSize: 15,
            padding: "14px", borderRadius: 999, cursor: "pointer",
          }}>
            Abbrechen
          </button>
          <button onClick={onClose} className="press" style={{
            flex: 2,
            background: "linear-gradient(180deg, var(--sm-accent-glow), var(--sm-accent-soft))",
            border: "none", color: "#2a1208",
            fontFamily: "inherit", fontSize: 15, fontWeight: 600,
            padding: "14px", borderRadius: 999, cursor: "pointer",
            boxShadow: "0 16px 40px -12px rgba(196,122,94,0.5)",
          }}>
            Weiter
          </button>
        </div>
      </SheetShell>
    </PhI>
  );
}

/* ---------- 3. Loading modal — atmender Kreis ---------- */

function BreathingLoader({ onCancel, label = "Meditation wird geladen…" }) {
  // Constellation-style loader — five points slowly orbiting a calm center.
  // Distinct from the concentric-rings vocabulary used by Hypnobox & co.
  const orbits = [
    { r: 30, d: 6.5, phase: 0,    size: 5 },
    { r: 30, d: 6.5, phase: 1.3,  size: 4 },
    { r: 42, d: 9,   phase: 0.4,  size: 3.5 },
    { r: 42, d: 9,   phase: 3.0,  size: 3 },
    { r: 42, d: 9,   phase: 5.6,  size: 3.5 },
  ];
  return (
    <PhI label="Loading-Modal — Konstellation">
      <SBI/>
      <FaintLibraryUnderlay/>
      <div style={{ position: "absolute", inset: 54, background: "rgba(10,6,4,0.55)", pointerEvents: "none" }}/>

      <div style={{
        position: "absolute", inset: 0,
        display: "flex", alignItems: "center", justifyContent: "center",
        padding: "0 36px",
      }}>
        <div style={{
          background: "linear-gradient(180deg, #2e1a14 0%, #211210 100%)",
          border: "1px solid rgba(235,226,214,0.08)",
          borderRadius: 28,
          padding: "32px 28px 24px",
          width: "100%", maxWidth: 320,
          textAlign: "center",
          boxShadow: "0 30px 60px rgba(0,0,0,0.5)",
        }}>
          {/* Constellation */}
          <div style={{ position: "relative", width: 110, height: 110, margin: "0 auto 22px" }}>
            {/* Calm center */}
            <div style={{
              position: "absolute", left: "50%", top: "50%",
              width: 8, height: 8, marginLeft: -4, marginTop: -4,
              borderRadius: "50%",
              background: "var(--sm-accent-glow)",
              boxShadow: "0 0 18px var(--sm-accent-glow)",
              animation: "sm-core-glow 4.2s ease-in-out infinite",
            }}/>
            {orbits.map((o, i) => (
              <div key={i} style={{
                position: "absolute", left: "50%", top: "50%",
                width: 0, height: 0,
                animation: `sm-orbit ${o.d}s linear infinite`,
                animationDelay: `-${o.phase}s`,
              }}>
                <div style={{
                  position: "absolute",
                  left: o.r, top: -o.size / 2,
                  width: o.size, height: o.size,
                  borderRadius: "50%",
                  background: "var(--sm-accent-text)",
                  opacity: 0.7,
                  boxShadow: "0 0 6px rgba(217,154,126,0.6)",
                }}/>
              </div>
            ))}
          </div>

          <div className="h-display" style={{ fontSize: 18, marginBottom: 6 }}>{label}</div>
          <div style={{ fontSize: 12, color: "var(--sm-text-2)", lineHeight: 1.5, marginBottom: 22 }}>
            Einen Moment, wir holen die Aufnahme zu dir.
          </div>

          <button onClick={onCancel} className="press" style={{
            background: "rgba(235,226,214,0.04)",
            border: "1px solid rgba(235,226,214,0.08)",
            color: "var(--sm-accent-text)",
            fontFamily: "inherit", fontSize: 14,
            padding: "10px 22px", borderRadius: 999, cursor: "pointer",
          }}>
            Abbrechen
          </button>
        </div>
      </div>

      <style>{`
        @keyframes sm-orbit {
          from { transform: rotate(0deg); }
          to   { transform: rotate(360deg); }
        }
        @keyframes sm-core-glow {
          0%, 100% { opacity: 0.7; transform: scale(0.9); }
          50%      { opacity: 1;   transform: scale(1.15); }
        }
      `}</style>
    </PhI>
  );
}

/* ---------- 4. Import-Anleitung — How-to (3 steps) ---------- */

function HowToImportSheet({ onClose, variant = "browser" }) {
  const browserSteps = [
    {
      n: 1, icon: ShareIcon,
      title: "Im Browser teilen",
      body: "Long-Press auf den mp3-Link → „Teilen…“ wählen. Das iOS-Share-Sheet öffnet sich.",
    },
    {
      n: 2, icon: FlameSquare,
      title: "Still Moment auswählen",
      body: "Tippe Still Moment in der App-Reihe. iOS bestätigt kurz mit „Gespeichert“ — tippe OK.",
    },
    {
      n: 3, icon: PlayBadgeIcon,
      title: "In der App fertigstellen",
      body: "Wechsle zu Still Moment. Du landest direkt im Importieren-Screen — wähle Typ, Lehrer:in und Titel.",
    },
  ];
  const filesSteps = [
    {
      n: 1, icon: PlusIconHT,
      title: "„+“ in der Bibliothek tippen",
      body: "Wähle im Aktionsmenü „Aus Dateien“. Der iOS-Datei-Picker öffnet sich.",
    },
    {
      n: 2, icon: FilesIcon,
      title: "Audio-Datei wählen",
      body: "Navigiere zu iCloud, Downloads oder einem lokalen Ordner und tippe auf die Aufnahme.",
    },
    {
      n: 3, icon: PlayBadgeIcon,
      title: "Fertigstellen",
      body: "Du landest direkt im Importieren-Screen — wähle Typ, Lehrer:in und Titel.",
    },
  ];
  const steps = variant === "files" ? filesSteps : browserSteps;
  const title = variant === "files" ? "So importierst du aus deinen Dateien" : "So importierst du aus dem Browser";
  const intro = variant === "files"
    ? "Wenn die Audio-Datei schon auf deinem Gerät liegt, kannst du sie direkt aus der Bibliothek hinzufügen."
    : "Auf vielen Webseiten kannst du mp3-Aufnahmen direkt zu Still Moment senden — ohne Umweg über die Dateien-App.";
  return (
    <PhI label={variant === "files" ? "Anleitung — Import aus Dateien" : "Anleitung — Import per Share-Sheet"}>
      <SBI/>
      <SheetBackdrop/>
      <FaintLibraryUnderlay title="Wo finde ich Meditationen?"/>
      <SheetShell height={760}>
        <div style={{
          display: "flex", alignItems: "flex-start", justifyContent: "space-between",
          padding: "8px 22px 12px",
        }}>
          <div style={{ flex: 1, paddingRight: 16 }}>
            <div style={{
              fontSize: 11, letterSpacing: "0.16em", textTransform: "uppercase",
              color: "var(--sm-accent-text)", fontWeight: 500, marginBottom: 6,
            }}>
              Anleitung
            </div>
            <div className="h-display" style={{ fontSize: 22, lineHeight: 1.2 }}>
              {title}
            </div>
          </div>
          <button onClick={onClose} className="press" style={{
            width: 30, height: 30, borderRadius: "50%",
            background: "rgba(235,226,214,0.06)", border: "none", color: "var(--sm-text-2)",
            display: "inline-flex", alignItems: "center", justifyContent: "center", cursor: "pointer",
            flexShrink: 0,
          }} aria-label="Zurück">
            <span style={{ width: 16, height: 16 }}>{BackArrow}</span>
          </button>
        </div>

        <div style={{
          padding: "0 22px 16px",
          fontSize: 13, color: "var(--sm-text-2)", lineHeight: 1.55,
        }}>
          {intro}
        </div>

        <div style={{ flex: 1, overflowY: "auto", padding: "0 18px 24px" }}>
          {steps.map((s, i) => (
            <div key={s.n} style={{
              display: "flex", gap: 14,
              padding: "14px 16px",
              background: "var(--sm-card)",
              border: "1px solid var(--sm-card-line)",
              borderRadius: 18,
              marginBottom: 10,
            }}>
              <div style={{ display: "flex", flexDirection: "column", alignItems: "center", flexShrink: 0 }}>
                <div style={{
                  width: 32, height: 32, borderRadius: "50%",
                  background: "var(--sm-accent-dim)", color: "var(--sm-accent-text)",
                  display: "inline-flex", alignItems: "center", justifyContent: "center",
                  fontSize: 13, fontFamily: "var(--sm-font-display)", fontWeight: 500,
                }}>
                  {s.n}
                </div>
                {i < steps.length - 1 && (
                  <div style={{ width: 1, flex: 1, background: "rgba(235,226,214,0.08)", marginTop: 6, minHeight: 24 }}/>
                )}
              </div>
              <div style={{ flex: 1, paddingTop: 2 }}>
                <div style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 6 }}>
                  <span style={{ width: 18, height: 18, color: "var(--sm-text-2)" }}>{s.icon}</span>
                  <div style={{ fontSize: 15, fontFamily: "var(--sm-font-display)", color: "var(--sm-text)" }}>
                    {s.title}
                  </div>
                </div>
                <div style={{ fontSize: 12.5, color: "var(--sm-text-2)", lineHeight: 1.55 }}>
                  {s.body}
                </div>

              </div>
            </div>
          ))}
        </div>
      </SheetShell>
    </PhI>
  );
}

/* ---------- 5. Content guide sheet WITH inline how-to section ---------- */

function GuideSheetWithHowTo({ onClose, onOpenHowTo, onOpenHowToFiles }) {
  const sources = [
    { name: "Achtsamkeit & Selbstmitgefühl", author: "Jörg Mangold",
      desc: "MBSR, MSC, Körperscans. 3–49 Min. Als Arzt und Psychotherapeut zertifiziert.", host: "podcast" },
    { name: "Einfach meditieren", author: "Melissa Gein",
      desc: "Achtsamkeit, Selbstliebe, Schlaf. 6–19 Min. Direkt-Download via podcast.de.", host: "podcast.de" },
    { name: "Meditation-Download.de", author: null,
      desc: "Geführte Meditationen, kein Account nötig.", host: "meditation-download.de" },
    { name: "Zentrum für Achtsamkeit Köln", author: null,
      desc: "MBSR Body Scan, Sitzmeditation.", host: "zentrum-fuer-achtsamkeit.koeln" },
  ];

  return (
    <PhI label="Content Guide — mit Anleitung-Banner">
      <SBI/>
      <SheetBackdrop/>
      <FaintLibraryUnderlay/>
      <SheetShell height={770}>
        <div style={{
          display: "flex", alignItems: "center", justifyContent: "space-between",
          padding: "8px 22px 16px",
        }}>
          <div className="h-display" style={{ fontSize: 22 }}>Wo finde ich Meditationen?</div>
          <button onClick={onClose} className="press" style={{
            width: 30, height: 30, borderRadius: "50%",
            background: "rgba(235,226,214,0.06)", border: "none", color: "var(--sm-text-2)",
            display: "inline-flex", alignItems: "center", justifyContent: "center", cursor: "pointer",
          }}>
            <span style={{ width: 14, height: 14 }}>{CloseX}</span>
          </button>
        </div>

        <div style={{
          padding: "0 22px 14px",
          fontSize: 13, color: "var(--sm-text-2)", lineHeight: 1.55,
        }}>
          Eine kleine, kuratierte Auswahl. Kostenlos, frei zugänglich.
        </div>

        <div style={{ flex: 1, overflowY: "auto", padding: "0 18px 18px" }}>
          {/* Anleitung banners — two paths */}
          <div style={{ display: "flex", flexDirection: "column", gap: 10, marginBottom: 18 }}>
            <button onClick={onOpenHowTo} className="press" style={{
              width: "100%",
              display: "flex", alignItems: "center", gap: 14,
              padding: "14px 16px",
              background: "rgba(196,122,94,0.10)",
              border: "1px solid rgba(196,122,94,0.28)",
              borderRadius: 18,
              color: "var(--sm-text)",
              fontFamily: "inherit", textAlign: "left", cursor: "pointer",
            }}>
              <span style={{
                width: 36, height: 36, borderRadius: "50%",
                background: "var(--sm-accent-dim)", color: "var(--sm-accent-text)",
                display: "inline-flex", alignItems: "center", justifyContent: "center", flexShrink: 0,
              }}>
                <span style={{ width: 18, height: 18 }}>{ShareIcon}</span>
              </span>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 14, fontFamily: "var(--sm-font-display)" }}>
                  So importierst du aus dem Browser
                </div>
                <div style={{ fontSize: 11.5, color: "var(--sm-text-2)", marginTop: 3, lineHeight: 1.45 }}>
                  Long-Press → Teilen → Still Moment.
                </div>
              </div>
              <span style={{ width: 16, height: 16, color: "var(--sm-text-3)" }}>
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M9 6 L15 12 L9 18"/>
                </svg>
              </span>
            </button>

            <button onClick={onOpenHowToFiles} className="press" style={{
              width: "100%",
              display: "flex", alignItems: "center", gap: 14,
              padding: "14px 16px",
              background: "rgba(196,122,94,0.10)",
              border: "1px solid rgba(196,122,94,0.28)",
              borderRadius: 18,
              color: "var(--sm-text)",
              fontFamily: "inherit", textAlign: "left", cursor: "pointer",
            }}>
              <span style={{
                width: 36, height: 36, borderRadius: "50%",
                background: "var(--sm-accent-dim)", color: "var(--sm-accent-text)",
                display: "inline-flex", alignItems: "center", justifyContent: "center", flexShrink: 0,
              }}>
                <span style={{ width: 18, height: 18 }}>{FilesIcon}</span>
              </span>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 14, fontFamily: "var(--sm-font-display)" }}>
                  So importierst du aus deinen Dateien
                </div>
                <div style={{ fontSize: 11.5, color: "var(--sm-text-2)", marginTop: 3, lineHeight: 1.45 }}>
                  „+“ → Aus Dateien → Audio wählen.
                </div>
              </div>
              <span style={{ width: 16, height: 16, color: "var(--sm-text-3)" }}>
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M9 6 L15 12 L9 18"/>
                </svg>
              </span>
            </button>
          </div>

          {/* Quellen */}
          <div style={{
            padding: "0 4px 8px",
            display: "flex", alignItems: "baseline", justifyContent: "space-between",
          }}>
            <div className="h-section">Quellen · Deutsch</div>
            <div style={{ fontSize: 11, color: "var(--sm-text-3)" }}>{sources.length}</div>
          </div>

          <div className="card" style={{ background: "rgba(255,255,255,0.02)" }}>
            {sources.map((s, i) => (
              <a key={s.name} href="#" onClick={(e) => e.preventDefault()} className="press"
                style={{
                  display: "flex", alignItems: "center", gap: 12,
                  padding: "14px 16px",
                  borderTop: i === 0 ? "none" : "1px solid rgba(235,226,214,0.05)",
                  color: "var(--sm-text)", textDecoration: "none",
                }}>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: "flex", alignItems: "baseline", gap: 8, flexWrap: "wrap" }}>
                    <div style={{ fontSize: 15, fontFamily: "var(--sm-font-display)" }}>{s.name}</div>
                    {s.author && (
                      <div style={{ fontSize: 12, color: "var(--sm-text-2)" }}>· {s.author}</div>
                    )}
                  </div>
                  <div style={{ fontSize: 12, color: "var(--sm-text-2)", marginTop: 4, lineHeight: 1.45 }}>
                    {s.desc}
                  </div>
                  <div style={{ fontSize: 12, color: "var(--sm-text-3)", marginTop: 6 }}>
                    {s.host}
                  </div>
                </div>
                <span style={{
                  width: 22, height: 22, color: "var(--sm-accent-text)",
                  display: "inline-flex", alignItems: "center", justifyContent: "center",
                }}>
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M14 5 H19 V10"/>
                    <path d="M19 5 L11 13"/>
                    <path d="M18 14 V18 A2 2 0 0 1 16 20 H7 A2 2 0 0 1 5 18 V9 A2 2 0 0 1 7 7 H11"/>
                  </svg>
                </span>
              </a>
            ))}
          </div>

          <div style={{
            display: "flex", gap: 10, alignItems: "flex-start",
            padding: "16px 8px 0",
            color: "var(--sm-text-3)", fontSize: 11, lineHeight: 1.55,
          }}>
            <span style={{ width: 14, height: 14, marginTop: 2, flexShrink: 0 }}>
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round">
                <circle cx="12" cy="12" r="9"/>
                <path d="M12 11 V17"/>
                <circle cx="12" cy="7.6" r="0.6" fill="currentColor"/>
              </svg>
            </span>
            <span>Links öffnen im System-Browser. Keine Tracking-Daten verlassen die App.</span>
          </div>
        </div>
      </SheetShell>
    </PhI>
  );
}

window.SM_ImportFlow = {
  PlusActionSheet, PlusActionSheetB,
  ImportAsSheet, ImportAsSheetB,
  BreathingLoader,
  HowToImportSheet,
  GuideSheetWithHowTo,
};
