/* Library — Suchfunktion (final, kanonisch)
   Platzierung: Suchfeld oben unter dem Titel (browse-first iOS-HIG-Pattern).
   Funktioniert iOS-übergreifend ohne Versions-Branching.

   Scope: Titel + Sprecher.
   Scope-Bar: Alle / Sprecher / Sitzungen.
   Treffer: flache Liste mit Lehrer in Subtitle, Match in Akzentfarbe hervorgehoben.
   Empty: schlichter Text "Nichts gefunden".
   Historie: letzte Suchen als Liste, sichtbar wenn fokussiert & Feld leer. */

const { StatusBar: SBs, TabBar: TBs, Phone: PHs, Icons: ICs } = window.SM;

/* --- Mock data --- */
const TRACKS_S = [
  { title: "Body Scan Meditation Coursera",  author: "Elisabeth Slator",      dur: "16:45" },
  { title: "Awareness of Breath and Body",   author: "Elisabeth Slator",      dur: "13:02" },
  { title: "Tor zur Achtsamkeit",            author: "Geführte Meditationen", dur: "10:42" },
  { title: "Präsent, verbunden, beschützt",  author: "Geführte Meditationen", dur: "15:08" },
  { title: "Exploring Thoughts Meditation",  author: "Elisabeth Slator",      dur: "19:03" },
  { title: "R.A.I.N.",                       author: "Elisabeth Slator",      dur: "15:10" },
  { title: "Awareness of Breath Guided",     author: "Elisabeth Slator",      dur: "11:35" },
];

const HISTORY_S = ["Breath", "Slator", "Achtsamkeit", "R.A.I.N."];

/* --- Filtering --- */
function filterScopeS(q, scope) {
  if (!q) return TRACKS_S;
  const s = q.toLowerCase();
  if (scope === "speakers") return TRACKS_S.filter(t => t.author.toLowerCase().includes(s));
  if (scope === "sessions") return TRACKS_S.filter(t => t.title.toLowerCase().includes(s));
  return TRACKS_S.filter(t => t.title.toLowerCase().includes(s) || t.author.toLowerCase().includes(s));
}

function HighlightS({ text, q }) {
  if (!q) return <>{text}</>;
  const i = text.toLowerCase().indexOf(q.toLowerCase());
  if (i === -1) return <>{text}</>;
  return (
    <>
      {text.slice(0, i)}
      <span style={{
        color: "var(--sm-accent-text)",
        background: "rgba(196,122,94,0.14)",
        borderRadius: 3,
        padding: "0 1px",
      }}>{text.slice(i, i + q.length)}</span>
      {text.slice(i + q.length)}
    </>
  );
}

/* --- Atoms --- */
function PlayBadgeS({ size = 36 }) {
  return (
    <div style={{
      width: size, height: size, borderRadius: "50%",
      background: "linear-gradient(180deg, #d68a6e, #b06a4f)",
      display: "inline-flex", alignItems: "center", justifyContent: "center",
      flexShrink: 0, boxShadow: "0 4px 12px rgba(196,122,94,0.4)",
    }}>
      <svg viewBox="0 0 24 24" width={size * 0.45} height={size * 0.45} fill="#2a1208" style={{ marginLeft: 2 }}>
        <path d="M8 5 V19 L19 12 Z"/>
      </svg>
    </div>
  );
}

const SearchIconS = (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round">
    <circle cx="11" cy="11" r="6"/>
    <path d="M15.5 15.5 L20 20"/>
  </svg>
);

const InfoIconS = (
  <span style={{
    width: 18, height: 18, display: "inline-flex",
    alignItems: "center", justifyContent: "center",
    border: "1.4px solid currentColor", borderRadius: "50%",
    fontSize: 11, fontStyle: "italic", fontFamily: "var(--sm-font-display)",
    lineHeight: 1,
  }}>i</span>
);

function CaretS() {
  return (
    <span style={{
      display: "inline-block", width: 1.5, height: "1em",
      background: "var(--sm-accent)", marginLeft: 1,
      verticalAlign: "-0.12em",
      animation: "smCaret 1.05s steps(2,start) infinite",
    }}/>
  );
}

function TrackRowS({ t, q }) {
  return (
    <button className="press" style={{
      width: "100%", display: "flex", alignItems: "center", gap: 12,
      padding: "13px 16px",
      background: "transparent", border: "none",
      color: "var(--sm-text)", fontFamily: "inherit",
      cursor: "pointer", textAlign: "left",
    }}>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 15, fontFamily: "var(--sm-font-display)" }}>
          <HighlightS text={t.title} q={q}/>
        </div>
        <div style={{ fontSize: 12, color: "var(--sm-text-2)", marginTop: 2 }}>
          <HighlightS text={t.author} q={q}/> · {t.dur}
        </div>
      </div>
      <PlayBadgeS/>
    </button>
  );
}

function EmptyResultS({ q }) {
  return (
    <div style={{
      padding: "56px 24px 24px",
      display: "flex", flexDirection: "column", alignItems: "center", textAlign: "center",
    }}>
      <div style={{
        width: 56, height: 56, borderRadius: "50%",
        background: "rgba(235,226,214,0.04)",
        border: "1px solid rgba(235,226,214,0.06)",
        display: "flex", alignItems: "center", justifyContent: "center",
        color: "var(--sm-text-3)",
        marginBottom: 18,
      }}>
        <span style={{ width: 22, height: 22, display: "inline-flex" }}>{SearchIconS}</span>
      </div>
      <div style={{ fontSize: 17, fontFamily: "var(--sm-font-display)", color: "var(--sm-text)" }}>
        Nichts gefunden
      </div>
      <div style={{ fontSize: 13, color: "var(--sm-text-3)", marginTop: 6 }}>
        Keine Treffer für „{q}"
      </div>
    </div>
  );
}

/* Inject caret keyframes */
if (typeof document !== "undefined" && !document.getElementById("sm-search-styles")) {
  const s = document.createElement("style");
  s.id = "sm-search-styles";
  s.textContent = `@keyframes smCaret { 0%, 100% { opacity: 1; } 50% { opacity: 0; } }`;
  document.head.appendChild(s);
}

/* --- Scope-Bar (Alle / Sprecher / Sitzungen) --- */
function ScopeBarS({ scope = "all" }) {
  const options = [
    { id: "all",      label: "Alle" },
    { id: "speakers", label: "Sprecher" },
    { id: "sessions", label: "Sitzungen" },
  ];
  return (
    <div style={{
      display: "flex", gap: 4, padding: 4,
      borderRadius: 999,
      background: "rgba(235,226,214,0.05)",
      border: "1px solid rgba(235,226,214,0.06)",
    }}>
      {options.map(o => {
        const on = scope === o.id;
        return (
          <button key={o.id} className="press" style={{
            flex: 1,
            padding: "7px 12px",
            borderRadius: 999,
            background: on ? "var(--sm-accent-dim)" : "transparent",
            color: on ? "var(--sm-accent-text)" : "var(--sm-text-2)",
            border: "none",
            fontFamily: "inherit", fontSize: 13,
            cursor: "pointer",
            fontWeight: on ? 500 : 400,
            whiteSpace: "nowrap",
          }}>{o.label}</button>
        );
      })}
    </div>
  );
}

/* --- Header (Titel + Plus + Info) --- */
function HeaderS() {
  return (
    <div style={{
      display: "flex", alignItems: "center", justifyContent: "space-between",
      padding: "8px 20px 8px", gap: 12,
    }}>
      <div className="h-display" style={{ fontSize: 22 }}>Geführte Meditationen</div>
      <div style={{ display: "inline-flex", gap: 8 }}>
        <button className="icon-btn press" aria-label="Hinzufügen">
          <span style={{ width: 18, height: 18 }}>{ICs.plus}</span>
        </button>
        <button className="icon-btn press" aria-label="Info">{InfoIconS}</button>
      </div>
    </div>
  );
}

/* --- Suchfeld --- */
function SearchBarS({ q, focused = false }) {
  return (
    <div style={{ padding: "4px 20px 14px" }}>
      <div style={{
        display: "flex", alignItems: "center", gap: 10,
        padding: "10px 14px",
        background: "rgba(235,226,214,0.05)",
        border: "1px solid " + (focused ? "rgba(196,122,94,0.4)" : "rgba(235,226,214,0.06)"),
        borderRadius: 14,
        color: q || focused ? "var(--sm-text)" : "var(--sm-text-3)",
        fontSize: 15,
        boxShadow: focused ? "0 0 0 3px rgba(196,122,94,0.10)" : "none",
      }}>
        <span style={{ width: 16, height: 16, display: "inline-flex", color: "var(--sm-text-3)" }}>{SearchIconS}</span>
        <div style={{ flex: 1, minWidth: 0 }}>
          {q || "Nach Titel oder Sprecher suchen"}{focused && <CaretS/>}
        </div>
        {q && (
          <div style={{
            width: 18, height: 18, borderRadius: "50%",
            background: "rgba(235,226,214,0.12)",
            display: "inline-flex", alignItems: "center", justifyContent: "center",
            color: "var(--sm-text-2)",
          }}>
            <svg viewBox="0 0 24 24" width={10} height={10} fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round">
              <path d="M6 6 L18 18 M18 6 L6 18"/>
            </svg>
          </div>
        )}
      </div>
    </div>
  );
}

/* --- Treffer-Liste (flach, Sprecher im Subtitle) --- */
function ResultsListS({ q }) {
  const filtered = filterScopeS(q, "all");
  return (
    <div style={{ padding: "0 18px 110px" }}>
      <div style={{
        fontSize: 11, letterSpacing: "0.08em", textTransform: "uppercase",
        color: "var(--sm-text-3)", padding: "0 6px 10px",
      }}>
        {filtered.length} Treffer
      </div>
      <div className="card">
        {filtered.map((t, i) => (
          <div key={t.title} style={{ borderTop: i === 0 ? "none" : "1px solid rgba(235,226,214,0.04)" }}>
            <TrackRowS t={t} q={q}/>
          </div>
        ))}
      </div>
    </div>
  );
}

/* --- Historie (Liste) --- */
function HistoryListS() {
  return (
    <div style={{ padding: "8px 24px 110px" }}>
      <div style={{
        fontSize: 11, letterSpacing: "0.08em", textTransform: "uppercase",
        color: "var(--sm-text-3)", padding: "0 0 12px",
        display: "flex", alignItems: "center", justifyContent: "space-between",
      }}>
        <span>Zuletzt gesucht</span>
        <button className="press" style={{
          background: "transparent", border: "none",
          color: "var(--sm-accent-text)", fontFamily: "inherit", fontSize: 11,
          letterSpacing: "0.04em", textTransform: "none", cursor: "pointer", padding: 0,
        }}>Leeren</button>
      </div>
      <div style={{ display: "flex", flexDirection: "column", gap: 2 }}>
        {HISTORY_S.map(h => (
          <button key={h} className="press" style={{
            display: "flex", alignItems: "center", gap: 12,
            padding: "12px 4px",
            background: "transparent", border: "none",
            color: "var(--sm-text)", fontFamily: "inherit", fontSize: 15,
            textAlign: "left", cursor: "pointer",
            borderBottom: "1px solid rgba(235,226,214,0.04)",
          }}>
            <svg viewBox="0 0 24 24" width={15} height={15} fill="none" stroke="var(--sm-text-3)" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round">
              <circle cx="12" cy="12" r="8"/>
              <path d="M12 8 V12 L15 14"/>
            </svg>
            <div style={{ flex: 1 }}>{h}</div>
            <svg viewBox="0 0 24 24" width={12} height={12} fill="none" stroke="var(--sm-text-3)" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round">
              <path d="M17 7 L7 17 M9 7 H17 V15"/>
            </svg>
          </button>
        ))}
      </div>
    </div>
  );
}

/* =================================================================
   Library — Suche (kanonische Variante)
   States:
     - idle    → Standard-Bibliothek, Suchfeld inaktiv unter Titel
     - history → fokussiert, leeres Feld → Historie als Liste
     - results → mit Eingabe → flache Trefferliste (gefiltert nach Scope)
     - empty   → mit Eingabe, keine Treffer → "Nichts gefunden"
   ================================================================= */

function LibrarySearch({ state = "idle", q = "", activeTab, setActiveTab, label }) {
  const groups = TRACKS_S.reduce((a, t) => {
    (a[t.author] = a[t.author] || []).push(t);
    return a;
  }, {});
  const focused = state !== "idle";

  return (
    <PHs label={label || "Library — Suche"}>
      <SBs/>
      <div className="screen-content scrollable">
        <HeaderS/>
        <SearchBarS q={q} focused={focused}/>
        {state === "idle" && (
          <div style={{ padding: "0 18px 110px" }}>
            {Object.entries(groups).map(([author, items]) => (
              <div key={author} style={{ marginBottom: 18 }}>
                <div style={{
                  fontSize: 16, fontFamily: "var(--sm-font-display)",
                  color: "var(--sm-text)", padding: "0 6px 8px",
                }}>{author}</div>
                <div className="card">
                  {items.map((t, i) => (
                    <div key={t.title} style={{ borderTop: i === 0 ? "none" : "1px solid rgba(235,226,214,0.04)" }}>
                      <TrackRowS t={t} q=""/>
                    </div>
                  ))}
                </div>
              </div>
            ))}
          </div>
        )}
        {state === "history" && <HistoryListS/>}
        {state === "results" && <ResultsListS q={q}/>}
        {state === "empty" && <EmptyResultS q={q}/>}
      </div>
      <TBs active={activeTab} onChange={setActiveTab}/>
    </PHs>
  );
}

window.SM_LibrarySearch = { LibrarySearch };
