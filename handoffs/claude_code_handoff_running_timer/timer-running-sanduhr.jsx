/* Still Moment — Running Timer · Sanduhr-Vessel (final)
   Prinzip: Stille. Es bewegt sich nur der Pegel, sehr langsam.
   Keine Atembewegung — die App taktet den Atem nicht, sie begleitet.

   Richtung: Pegel FÜLLT sich von unten nach oben über die Sitzungsdauer.
   Metapher: Meditation füllt dich auf, sie verbraucht dich nicht.
   (Erste Version war absteigend — sah aus wie eine sich leerende Batterie,
    falsche Botschaft für eine Praxis, die Energie geben soll.)

   Vokabular:
   - Glas-Capsule, 110×360
   - warmer Verlauf von oben (Honig) nach unten (Kupfer), wachsend
   - dünner Meniskus-Glanz an der steigenden Flüssigkeitskante
   - schmaler Glas-Reflex links
   - Restzeit groß daneben, „verbleibend" als Eyebrow (praktische Info,
     erzählt eine andere Geschichte als das Visual — und das ist okay:
     Glas = Metapher, Zahl = Information)

   Tokens aus styles.css. Keine harten Farbwerte hier.
*/

const { useState: uS_SV, useEffect: uE_SV } = React;
const { StatusBar: SB_SV, Phone: Ph_SV } = window.SM;

function fmtSV(sec) {
  const m = Math.floor(sec / 60);
  const s = sec % 60;
  return `${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}`;
}

function CloseBtnSV({ onClick }) {
  return (
    <button className="icon-btn press" onClick={onClick} aria-label="Schließen"
      style={{ position: "absolute", top: 64, left: 18, zIndex: 4 }}>
      <svg viewBox="0 0 24 24" width="14" height="14" fill="none"
        stroke="currentColor" strokeWidth="1.6" strokeLinecap="round">
        <path d="M6 6 L18 18"/><path d="M18 6 L6 18"/>
      </svg>
    </button>
  );
}

/* Tick once per second (live demo). In Production: stable timer source. */
function useTickSV(active = true) {
  const [n, setN] = uS_SV(0);
  uE_SV(() => {
    if (!active) return;
    const id = setInterval(() => setN(v => v + 1), 1000);
    return () => clearInterval(id);
  }, [active]);
  return n;
}

/* Vessel — pure geometry, no breath.
   progress 0..1 controls FILL LEVEL (not drain): leeres Glas → volles Glas.
   Metapher: du füllst dich auf, nicht: du läufst leer. */
function Vessel({ progress }) {
  const w = 110, h = 360;
  const fillH = h * progress;          // wächst von 0 nach h
  const top = h - fillH;                // Oberkante der Flüssigkeit
  return (
    <div style={{
      width: w + 2, height: h + 2, position: "relative",
      borderRadius: 28,
      border: "1px solid rgba(235,226,214,0.10)",
      overflow: "hidden",
      background: "linear-gradient(180deg, rgba(58,32,26,0.4), rgba(26,13,9,0.6))",
      boxShadow: "inset 0 0 30px rgba(0,0,0,0.4)",
    }}>
      <svg width={w} height={h} style={{ display: "block" }}>
        <defs>
          {/* Gradient ist auf das Glas referenziert (nicht auf die Flüssigkeit).
             So zeigt der wachsende Pegel zuerst die tiefen, gegen Ende auch die
             hellen Töne — die Wärme "kommt nach oben". */}
          <linearGradient id="sv-fluid" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%"   stopColor="rgba(232,178,148,0.85)"/>
            <stop offset="40%"  stopColor="rgba(214,138,110,0.85)"/>
            <stop offset="100%" stopColor="rgba(176,106,79,0.95)"/>
          </linearGradient>
        </defs>
        {/* fluid — wächst von unten nach oben */}
        {fillH > 0 && (
          <rect x="0" y={top} width={w} height={fillH} fill="url(#sv-fluid)"/>
        )}
        {/* meniscus highlight — sitzt auf der wandernden Oberkante */}
        {fillH > 2 && (
          <ellipse cx={w / 2} cy={top + 1.5} rx={w * 0.42} ry="1.5"
            fill="rgba(255,230,210,0.55)"/>
        )}
      </svg>
      {/* glass side reflex */}
      <div style={{
        position: "absolute", top: 8, left: 12, bottom: 8, width: 6,
        borderRadius: 6,
        background: "linear-gradient(180deg, rgba(255,255,255,0.18), transparent)",
        pointerEvents: "none",
      }}/>
    </div>
  );
}

function RunningSanduhr({ duration = 600, elapsed = 124, onClose }) {
  // Live demo: progress increases over time if `live` (we always step from elapsed)
  const t = useTickSV(true);
  const live = Math.min(elapsed + t, duration);
  const remaining = duration - live;
  const progress = live / duration;

  return (
    <Ph_SV label="Running · Sanduhr">
      <SB_SV/>
      <CloseBtnSV onClick={onClose}/>

      <div style={{
        position: "absolute", inset: 0, display: "flex",
        alignItems: "center", justifyContent: "center", gap: 36,
      }}>
        <Vessel progress={progress}/>

        <div style={{ display: "flex", flexDirection: "column", alignItems: "flex-start" }}>
          <div style={{
            fontSize: 11, letterSpacing: "0.22em", textTransform: "uppercase",
            color: "var(--sm-text-3)", marginBottom: 6,
          }}>verbleibend</div>
          <div style={{
            fontFamily: "var(--sm-font-display)", fontWeight: 300,
            fontSize: 64, lineHeight: 1, letterSpacing: "-0.02em",
            fontVariantNumeric: "tabular-nums",
            color: "var(--sm-text)",
          }}>{fmtSV(remaining)}</div>
          <div style={{
            marginTop: 18, fontSize: 13, color: "var(--sm-text-2)",
            fontFamily: "var(--sm-font-display)", fontStyle: "italic",
          }}>von {Math.round(duration / 60)} Minuten</div>
        </div>
      </div>
    </Ph_SV>
  );
}

/* Static variant (for handover frames at specific progress points, no ticking) */
function RunningSanduhrStatic({ duration = 600, elapsed = 0 }) {
  const remaining = duration - elapsed;
  const progress = elapsed / duration;
  return (
    <Ph_SV label="Running · Sanduhr (still)">
      <SB_SV/>
      <CloseBtnSV/>
      <div style={{
        position: "absolute", inset: 0, display: "flex",
        alignItems: "center", justifyContent: "center", gap: 36,
      }}>
        <Vessel progress={progress}/>
        <div style={{ display: "flex", flexDirection: "column", alignItems: "flex-start" }}>
          <div style={{
            fontSize: 11, letterSpacing: "0.22em", textTransform: "uppercase",
            color: "var(--sm-text-3)", marginBottom: 6,
          }}>verbleibend</div>
          <div style={{
            fontFamily: "var(--sm-font-display)", fontWeight: 300,
            fontSize: 64, lineHeight: 1, letterSpacing: "-0.02em",
            fontVariantNumeric: "tabular-nums",
            color: "var(--sm-text)",
          }}>{fmtSV(remaining)}</div>
          <div style={{
            marginTop: 18, fontSize: 13, color: "var(--sm-text-2)",
            fontFamily: "var(--sm-font-display)", fontStyle: "italic",
          }}>von {Math.round(duration / 60)} Minuten</div>
        </div>
      </div>
    </Ph_SV>
  );
}

window.SM_Sanduhr = { RunningSanduhr, RunningSanduhrStatic, Vessel };
