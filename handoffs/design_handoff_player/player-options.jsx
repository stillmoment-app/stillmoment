/* Still Moment — Player-Screen Optionen
   Steuerung reduziert auf das Minimum: nur Pause.
   Kein ±10s, kein Slider, kein "Neu starten", kein "+1 Min".
*/

const TRACK = { artist: "Christine Braehler", title: "Herzenskraft aufbauen", elapsed: "8:13", remaining: "8:32", progress: 0.49 };

/* ============================================================
   Shared chrome
   ============================================================ */

function StatusBar({ tone = "light" }) {
  const c = tone === "light" ? "#ebe2d6" : "#1a0d09";
  return (
    <div style={{
      position: "absolute", top: 0, left: 0, right: 0, height: 54,
      padding: "18px 32px 0", display: "flex", alignItems: "center",
      justifyContent: "space-between",
      fontFamily: '-apple-system, "SF Pro Text", system-ui, sans-serif',
      fontWeight: 600, fontSize: 17, color: c, zIndex: 5,
    }}>
      <span>19:44</span>
      <div style={{ display: "flex", gap: 6, alignItems: "center" }}>
        <svg width="18" height="11" viewBox="0 0 18 11" fill="none">
          <rect x="0" y="6" width="3" height="5" rx="1" fill={c}/>
          <rect x="5" y="3" width="3" height="8" rx="1" fill={c}/>
          <rect x="10" y="0" width="3" height="11" rx="1" fill={c} opacity="0.4"/>
          <rect x="15" y="0" width="3" height="11" rx="1" fill={c} opacity="0.4"/>
        </svg>
        <svg width="16" height="12" viewBox="0 0 16 12" fill="none">
          <path d="M8 11.5L1 4.5C5 0.5 11 0.5 15 4.5L8 11.5Z" stroke={c} strokeWidth="1.5" fill="none"/>
        </svg>
        <div style={{ display: "inline-flex", alignItems: "center", gap: 3 }}>
          <span style={{ fontSize: 11, fontWeight: 700 }}>22</span>
          <div style={{
            width: 24, height: 12, borderRadius: 3,
            border: `1.2px solid ${c}`, padding: 1.5, opacity: 0.85,
          }}>
            <div style={{ width: "22%", height: "100%", background: "#ffd60a", borderRadius: 1 }}/>
          </div>
        </div>
      </div>
    </div>
  );
}

function CloseBtn({ tone = "light" }) {
  const stroke = tone === "light" ? "#ebe2d6" : "#1a0d09";
  const bg = tone === "light" ? "rgba(235,226,214,0.08)" : "rgba(26,13,9,0.06)";
  const border = tone === "light" ? "rgba(235,226,214,0.10)" : "rgba(26,13,9,0.10)";
  return (
    <button style={{
      position: "absolute", top: 64, left: 24, zIndex: 6,
      width: 44, height: 44, borderRadius: "50%",
      background: bg, border: `1px solid ${border}`,
      display: "inline-flex", alignItems: "center", justifyContent: "center",
      cursor: "pointer",
    }}>
      <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
        <path d="M1 1L13 13M13 1L1 13" stroke={stroke} strokeWidth="1.5" strokeLinecap="round"/>
      </svg>
    </button>
  );
}

function PauseGlyph({ size = 26, color = "#1a0d09" }) {
  return (
    <svg width={size} height={size} viewBox="0 0 26 26" fill="none">
      <rect x="6" y="4" width="4.5" height="18" rx="1.5" fill={color}/>
      <rect x="15.5" y="4" width="4.5" height="18" rx="1.5" fill={color}/>
    </svg>
  );
}

function PhoneShell({ children, bg, tone = "light", label, sub }) {
  return (
    <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 14 }}>
      <div style={{
        width: 393, height: 852, position: "relative", overflow: "hidden",
        borderRadius: 48, background: bg, isolation: "isolate",
      }}>
        <StatusBar tone={tone}/>
        <CloseBtn tone={tone}/>
        {children}
      </div>
      <div style={{ textAlign: "center", maxWidth: 393 }}>
        <div style={{
          fontFamily: "var(--sm-font-display)", fontSize: 19, color: "#ebe2d6",
          letterSpacing: "-0.01em",
        }}>{label}</div>
        <div style={{
          marginTop: 4, fontSize: 12, color: "rgba(168,154,140,0.7)",
          fontFamily: "var(--sm-font-ui)", lineHeight: 1.5,
        }}>{sub}</div>
      </div>
    </div>
  );
}

/* ============================================================
   0 — Status Quo (Referenz)
   ============================================================ */

function PlayerNow() {
  const bg = "linear-gradient(180deg, #2a1610 0%, #3a221c 50%, #4a2a20 100%)";
  return (
    <PhoneShell bg={bg} label="0 · Status Quo" sub="Wie es jetzt aussieht — funktional, fast wie Apple Music. Slider, Restzeit, ±10s, Pause.">
      <div style={{ position: "absolute", inset: "330px 0 0 0", display: "flex", flexDirection: "column", alignItems: "center", padding: "0 36px" }}>
        <div style={{ fontSize: 16, color: "#d99a7e", marginBottom: 8 }}>{TRACK.artist}</div>
        <div style={{ fontFamily: "var(--sm-font-display)", fontWeight: 500, fontSize: 28, color: "#ebe2d6", textAlign: "center" }}>{TRACK.title}</div>

        <div style={{ width: "100%", marginTop: 110 }}>
          <div style={{ position: "relative", height: 4, borderRadius: 2, background: "rgba(235,226,214,0.12)", overflow: "visible" }}>
            <div style={{ position: "absolute", inset: 0, width: `${TRACK.progress*100}%`, background: "#c47a5e", borderRadius: 2 }}/>
            <div style={{ position: "absolute", left: `${TRACK.progress*100}%`, top: "50%", transform: "translate(-50%,-50%)", width: 14, height: 14, borderRadius: "50%", background: "#fff" }}/>
          </div>
          <div style={{ display: "flex", justifyContent: "space-between", marginTop: 10, fontSize: 12, color: "rgba(235,226,214,0.55)" }}>
            <span>{TRACK.elapsed}</span><span>{TRACK.remaining}</span>
          </div>
        </div>

        <div style={{ display: "flex", alignItems: "center", gap: 40, marginTop: 38 }}>
          <button style={iconBtnNow}>
            <svg width="22" height="22" viewBox="0 0 22 22" fill="none">
              <path d="M11 4.5V2L15 5L11 8V5.5C7.13 5.5 4 8.63 4 12.5C4 16.37 7.13 19.5 11 19.5C14.87 19.5 18 16.37 18 12.5"
                    stroke="#d99a7e" strokeWidth="1.5" strokeLinecap="round" fill="none" transform="scale(-1,1) translate(-22,0)"/>
              <text x="11" y="15.5" textAnchor="middle" fontSize="6.5" fontWeight="500" fill="#d99a7e">10</text>
            </svg>
          </button>
          <button style={mainBtnNow}><PauseGlyph/></button>
          <button style={iconBtnNow}>
            <svg width="22" height="22" viewBox="0 0 22 22" fill="none">
              <path d="M11 4.5V2L15 5L11 8V5.5C7.13 5.5 4 8.63 4 12.5C4 16.37 7.13 19.5 11 19.5C14.87 19.5 18 16.37 18 12.5"
                    stroke="#d99a7e" strokeWidth="1.5" strokeLinecap="round" fill="none"/>
              <text x="11" y="15.5" textAnchor="middle" fontSize="6.5" fontWeight="500" fill="#d99a7e">10</text>
            </svg>
          </button>
        </div>
      </div>
    </PhoneShell>
  );
}
const iconBtnNow = {
  width: 56, height: 56, borderRadius: "50%",
  background: "transparent", border: "1.5px solid rgba(217,154,126,0.55)",
  cursor: "pointer", display: "inline-flex", alignItems: "center", justifyContent: "center",
};
const mainBtnNow = {
  width: 80, height: 80, borderRadius: "50%",
  background: "linear-gradient(180deg,#d68a6e,#b06a4f)",
  border: "none", cursor: "pointer",
  display: "inline-flex", alignItems: "center", justifyContent: "center",
  boxShadow: "0 12px 30px -10px rgba(196,122,94,0.5)",
};

/* ============================================================
   A — Reduktion
   Idle: nur Titel + leiser Puls. Tap zeigt für 4s die Pause.
   ============================================================ */

function PlayerA_Idle() {
  const bg = "radial-gradient(ellipse 90% 70% at 50% 30%, #3a201a 0%, #2a1610 38%, #190c08 72%, #110705 100%)";
  return (
    <PhoneShell bg={bg} tone="light"
      label="A · Reduktion — Idle"
      sub="Standardansicht während die Meditation läuft. Kein Slider, keine ±10s, keine Zeit. Nur ein leise pulsierender Punkt als Lebenszeichen.">
      <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", padding: "0 40px", textAlign: "center" }}>
        <div style={{
          width: 8, height: 8, borderRadius: "50%",
          background: "#d99a7e",
          boxShadow: "0 0 24px 4px rgba(217,154,126,0.4)",
          animation: "pl-pulse 5.5s ease-in-out infinite",
          marginBottom: 64,
        }}/>
        <div style={{ fontSize: 11, letterSpacing: "0.32em", textTransform: "uppercase", color: "rgba(168,154,140,0.55)", marginBottom: 18 }}>
          Christine Braehler
        </div>
        <div style={{
          fontFamily: "var(--sm-font-display)", fontWeight: 300,
          fontSize: 34, lineHeight: 1.25, color: "#ebe2d6",
          letterSpacing: "-0.01em",
        }}>
          Herzenskraft<br/>aufbauen
        </div>
        <div style={{ marginTop: 28, fontSize: 12, color: "rgba(168,154,140,0.45)", fontStyle: "italic" }}>
          tippe für Steuerung
        </div>
      </div>
      <style>{`@keyframes pl-pulse{0%,100%{opacity:.35;transform:scale(1)}50%{opacity:1;transform:scale(1.6)}}`}</style>
    </PhoneShell>
  );
}

function PlayerA_Reveal() {
  const bg = "radial-gradient(ellipse 90% 70% at 50% 30%, #3a201a 0%, #2a1610 38%, #190c08 72%, #110705 100%)";
  return (
    <PhoneShell bg={bg} tone="light"
      label="A · Reduktion — Tap"
      sub="Tap aufs Display zeigt für 4s die Pause. Sonst nichts.">
      <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", padding: "0 40px", textAlign: "center" }}>

        <div style={{ fontSize: 11, letterSpacing: "0.32em", textTransform: "uppercase", color: "rgba(168,154,140,0.55)", marginBottom: 14 }}>
          Christine Braehler
        </div>
        <div style={{
          fontFamily: "var(--sm-font-display)", fontWeight: 300,
          fontSize: 30, lineHeight: 1.25, color: "rgba(235,226,214,0.85)",
          letterSpacing: "-0.01em",
        }}>
          Herzenskraft aufbauen
        </div>

        <div style={{ marginTop: 28, fontSize: 11, letterSpacing: "0.22em", color: "rgba(168,154,140,0.55)", fontVariantNumeric: "tabular-nums" }}>
          NOCH {TRACK.remaining} MIN
        </div>

        <div style={{ marginTop: 64, display: "flex", alignItems: "center", justifyContent: "center" }}>
          <button style={mainBtnA}><PauseGlyph color="#d99a7e"/></button>
        </div>
      </div>
    </PhoneShell>
  );
}

const mainBtnA = {
  width: 76, height: 76, borderRadius: "50%",
  background: "rgba(15,8,5,0.55)",
  border: "1px solid rgba(217,154,126,0.45)",
  backdropFilter: "blur(8px)", WebkitBackdropFilter: "blur(8px)",
  cursor: "pointer",
  display: "inline-flex", alignItems: "center", justifyContent: "center",
};

/* ============================================================
   B — Atemkreis
   Pause-Button mittig, Atemvisualisierung. Restzeit als Bogen. Sonst nichts.
   ============================================================ */

function PlayerB() {
  const bg = "radial-gradient(ellipse 90% 70% at 50% 40%, #3a201a 0%, #2a1610 38%, #170b07 80%, #0d0604 100%)";
  return (
    <PhoneShell bg={bg} tone="light"
      label="B · Atemkreis"
      sub="Großer, langsam atmender Kreis (~16 s). Pause sitzt mittig. Restzeit als feiner Bogen außen rum. Sonst nichts.">

      <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center" }}>
        <div style={{ fontSize: 11, letterSpacing: "0.3em", textTransform: "uppercase", color: "rgba(168,154,140,0.55)" }}>
          Christine Braehler
        </div>
        <div style={{
          fontFamily: "var(--sm-font-display)", fontWeight: 400,
          fontSize: 22, lineHeight: 1.2, color: "rgba(235,226,214,0.85)",
          marginTop: 8, marginBottom: 56,
        }}>
          Herzenskraft aufbauen
        </div>

        <div style={{ position: "relative", width: 280, height: 280 }}>
          <svg width="280" height="280" style={{ position: "absolute", inset: 0 }}>
            <circle cx="140" cy="140" r="130" fill="none" stroke="rgba(235,226,214,0.07)" strokeWidth="1"/>
            <circle cx="140" cy="140" r="130" fill="none" stroke="#c47a5e" strokeWidth="1.2"
                    strokeDasharray={`${2*Math.PI*130*TRACK.progress} ${2*Math.PI*130}`}
                    transform="rotate(-90 140 140)" strokeLinecap="round" opacity="0.7"/>
          </svg>

          <div style={{
            position: "absolute", inset: 30,
            borderRadius: "50%",
            background: "radial-gradient(circle at 50% 45%, rgba(217,154,126,0.35), rgba(196,122,94,0.12) 60%, rgba(196,122,94,0) 80%)",
            border: "1px solid rgba(217,154,126,0.25)",
            animation: "pl-breathe 16s ease-in-out infinite",
            display: "flex", alignItems: "center", justifyContent: "center",
          }}>
            <button style={{
              width: 80, height: 80, borderRadius: "50%",
              background: "rgba(15,8,5,0.55)",
              border: "1px solid rgba(217,154,126,0.35)",
              backdropFilter: "blur(8px)",
              cursor: "pointer",
              display: "inline-flex", alignItems: "center", justifyContent: "center",
            }}>
              <PauseGlyph color="#d99a7e"/>
            </button>
          </div>
        </div>

        <div style={{ marginTop: 36, fontSize: 12, letterSpacing: "0.18em", color: "rgba(168,154,140,0.55)", fontVariantNumeric: "tabular-nums" }}>
          NOCH {TRACK.remaining} MIN
        </div>
      </div>

      <style>{`@keyframes pl-breathe{0%,100%{transform:scale(.86);opacity:.7}50%{transform:scale(1.04);opacity:1}}`}</style>
    </PhoneShell>
  );
}

/* ============================================================
   PRE-ROLL — Vorbereitungszeit (0–60s) vor Start der Meditation
   Drei Varianten. Beim Aufrufen des Players startet sofort der Countdown,
   danach automatischer Übergang in den Atemkreis (PlayerB).
   ============================================================ */

const PREP = { total: 15, remaining: 9, progress: 9/15 }; // 9s von 15s übrig

/* --- P1 — Countdown-Zahl gross, Atemkreis bereits angedeutet --- */
function PlayerB_PrepCountdown() {
  const bg = "radial-gradient(ellipse 90% 70% at 50% 40%, #3a201a 0%, #2a1610 38%, #170b07 80%, #0d0604 100%)";
  return (
    <PhoneShell bg={bg} tone="light"
      label="P1 · Countdown-Zahl"
      sub="Vorbereitung als grosse Zahl mittig im (noch nicht aktiven) Atemkreis. Klar, ruhig, eindeutig.">
      <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center" }}>
        <div style={{ fontSize: 11, letterSpacing: "0.3em", textTransform: "uppercase", color: "rgba(168,154,140,0.55)" }}>
          Christine Braehler
        </div>
        <div style={{ fontFamily: "var(--sm-font-display)", fontWeight: 400, fontSize: 22, lineHeight: 1.2, color: "rgba(235,226,214,0.85)", marginTop: 8, marginBottom: 56 }}>
          Herzenskraft aufbauen
        </div>

        <div style={{ position: "relative", width: 280, height: 280 }}>
          <svg width="280" height="280" style={{ position: "absolute", inset: 0 }}>
            <circle cx="140" cy="140" r="130" fill="none" stroke="rgba(235,226,214,0.07)" strokeWidth="1"/>
            <circle cx="140" cy="140" r="130" fill="none" stroke="#c47a5e" strokeWidth="1.2"
                    strokeDasharray={`${2*Math.PI*130*PREP.progress} ${2*Math.PI*130}`}
                    transform="rotate(-90 140 140)" strokeLinecap="round" opacity="0.55"/>
          </svg>
          <div style={{
            position: "absolute", inset: 30, borderRadius: "50%",
            background: "radial-gradient(circle at 50% 45%, rgba(217,154,126,0.20), rgba(196,122,94,0.06) 60%, rgba(196,122,94,0) 80%)",
            border: "1px solid rgba(217,154,126,0.18)",
            display: "flex", alignItems: "center", justifyContent: "center", flexDirection: "column",
          }}>
            <div style={{ fontFamily: "var(--sm-font-display)", fontWeight: 300, fontSize: 92, lineHeight: 1, color: "rgba(235,226,214,0.92)", fontVariantNumeric: "tabular-nums" }}>
              {PREP.remaining}
            </div>
            <div style={{ marginTop: 8, fontSize: 10, letterSpacing: "0.28em", textTransform: "uppercase", color: "rgba(168,154,140,0.55)" }}>
              Vorbereitung
            </div>
          </div>
        </div>

        <div style={{ marginTop: 36, fontSize: 12, letterSpacing: "0.18em", color: "rgba(168,154,140,0.45)", fontVariantNumeric: "tabular-nums" }}>
          GLEICH GEHT'S LOS
        </div>
      </div>
    </PhoneShell>
  );
}

/* --- P2 — Atem-Anleitung statt Zahl --- */
function PlayerB_PrepBreath() {
  const bg = "radial-gradient(ellipse 90% 70% at 50% 40%, #3a201a 0%, #2a1610 38%, #170b07 80%, #0d0604 100%)";
  return (
    <PhoneShell bg={bg} tone="light"
      label="P2 · Atem-Anleitung"
      sub="Vorbereitung als Atem-Übung. Kreis pulsiert bereits (4s ein, 4s aus); 'einatmen / ausatmen' wechselt mit dem Kreis. Zahl klein darunter.">
      <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center" }}>
        <div style={{ fontSize: 11, letterSpacing: "0.3em", textTransform: "uppercase", color: "rgba(168,154,140,0.55)" }}>
          Christine Braehler
        </div>
        <div style={{ fontFamily: "var(--sm-font-display)", fontWeight: 400, fontSize: 22, lineHeight: 1.2, color: "rgba(235,226,214,0.85)", marginTop: 8, marginBottom: 56 }}>
          Herzenskraft aufbauen
        </div>

        <div style={{ position: "relative", width: 280, height: 280 }}>
          <svg width="280" height="280" style={{ position: "absolute", inset: 0 }}>
            <circle cx="140" cy="140" r="130" fill="none" stroke="rgba(235,226,214,0.07)" strokeWidth="1"/>
          </svg>
          <div style={{
            position: "absolute", inset: 30, borderRadius: "50%",
            background: "radial-gradient(circle at 50% 45%, rgba(217,154,126,0.30), rgba(196,122,94,0.10) 60%, rgba(196,122,94,0) 80%)",
            border: "1px solid rgba(217,154,126,0.22)",
            animation: "pl-prep-breath 8s ease-in-out infinite",
            display: "flex", alignItems: "center", justifyContent: "center",
          }}>
            <div style={{ fontFamily: "var(--sm-font-display)", fontStyle: "italic", fontWeight: 300, fontSize: 26, color: "rgba(235,226,214,0.85)", letterSpacing: "0.02em" }}>
              einatmen
            </div>
          </div>
        </div>

        <div style={{ marginTop: 36, display: "flex", flexDirection: "column", alignItems: "center", gap: 6 }}>
          <div style={{ fontSize: 11, letterSpacing: "0.22em", color: "rgba(168,154,140,0.55)", fontVariantNumeric: "tabular-nums" }}>
            ANKOMMEN · NOCH 0:09
          </div>
        </div>
      </div>
      <style>{`@keyframes pl-prep-breath{0%,100%{transform:scale(.84);opacity:.65}50%{transform:scale(1.06);opacity:1}}`}</style>
    </PhoneShell>
  );
}

/* --- P3 — Stille / nur Bogen --- */
function PlayerB_PrepHush() {
  const bg = "radial-gradient(ellipse 90% 70% at 50% 40%, #3a201a 0%, #2a1610 38%, #170b07 80%, #0d0604 100%)";
  return (
    <PhoneShell bg={bg} tone="light"
      label="P3 · Stille"
      sub="Vorbereitung fast unsichtbar. Nur ein dünner Bogen, der sich leise leerläuft. Ein einziges Wort. Maximaler Respekt vor dem Moment.">
      <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center" }}>
        <div style={{ fontSize: 11, letterSpacing: "0.3em", textTransform: "uppercase", color: "rgba(168,154,140,0.55)" }}>
          Christine Braehler
        </div>
        <div style={{ fontFamily: "var(--sm-font-display)", fontWeight: 400, fontSize: 22, lineHeight: 1.2, color: "rgba(235,226,214,0.85)", marginTop: 8, marginBottom: 80 }}>
          Herzenskraft aufbauen
        </div>

        <div style={{ position: "relative", width: 200, height: 200 }}>
          <svg width="200" height="200" style={{ position: "absolute", inset: 0 }}>
            <circle cx="100" cy="100" r="92" fill="none" stroke="rgba(235,226,214,0.06)" strokeWidth="1"/>
            <circle cx="100" cy="100" r="92" fill="none" stroke="#c47a5e" strokeWidth="1"
                    strokeDasharray={`${2*Math.PI*92*(1-PREP.progress)} ${2*Math.PI*92}`}
                    transform="rotate(-90 100 100)" strokeLinecap="round" opacity="0.45"/>
          </svg>
          <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center" }}>
            <div style={{ fontFamily: "var(--sm-font-display)", fontStyle: "italic", fontWeight: 300, fontSize: 22, color: "rgba(235,226,214,0.7)" }}>
              ankommen
            </div>
          </div>
        </div>
      </div>
    </PhoneShell>
  );
}

/* ============================================================
   Mount
   ============================================================ */

function App() {
  return (
    <DesignCanvas
      title="Player-Screen · Optionen"
      subtitle="Steuerung reduziert auf das Notwendige: nur Pause. Beim Öffnen startet sofort die Vorbereitung — danach automatisch der Atemkreis."
    >
      <DCSection id="ref" title="Referenz">
        <DCArtboard id="now"      label="0 · Status Quo"           width={420} height={920}><PlayerNow/></DCArtboard>
      </DCSection>
      <DCSection id="a" title="A · Reduktion">
        <DCArtboard id="a-idle"   label="A · Idle"                 width={420} height={920}><PlayerA_Idle/></DCArtboard>
        <DCArtboard id="a-tap"    label="A · Tap-Reveal"           width={420} height={920}><PlayerA_Reveal/></DCArtboard>
      </DCSection>
      <DCSection id="b" title="B · Atemkreis (Hauptphase)">
        <DCArtboard id="b-main"   label="B · Atemkreis · läuft"    width={420} height={920}><PlayerB/></DCArtboard>
      </DCSection>
      <DCSection id="prep" title="Vorbereitungszeit · vor dem Start">
        <DCArtboard id="prep-1"   label="P1 · Countdown-Zahl"      width={420} height={920}><PlayerB_PrepCountdown/></DCArtboard>
        <DCArtboard id="prep-2"   label="P2 · Atem-Anleitung"      width={420} height={920}><PlayerB_PrepBreath/></DCArtboard>
        <DCArtboard id="prep-3"   label="P3 · Stille"              width={420} height={920}><PlayerB_PrepHush/></DCArtboard>
      </DCSection>
    </DesignCanvas>
  );
}

ReactDOM.createRoot(document.getElementById("root")).render(<App/>);
