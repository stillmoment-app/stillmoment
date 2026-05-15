/* Still Moment — Pre-Roll + Running Timer (final)
   Pre-Roll = A. Atemkreis (still ankommen, Kreis atmet, Sekunden im Inneren)
   Running  = F. Atmender Ring (Lichtperle wandert 1× rum, zarter Bogen, Restzeit groß)

   App-Konventionen:
   - Tokens aus styles.css (var(--sm-accent...), var(--sm-text...), var(--sm-r-*))
   - Newsreader für Display-Zahlen, Geist für UI
   - .eyebrow / .icon-btn / .press wiederverwendet
   - .bg-vignette via Phone (Kupfer-Glow von unten) bleibt
   - kein hardcodiertes Kupfer mehr — alles über Akzent-Tokens
*/

const { useState: uS_TR, useEffect: uE_TR } = React;
const { StatusBar: SB_TR, Phone: Ph_TR } = window.SM;

/* ---------- Helpers ---------- */
function fmtTime(sec) {
  const m = Math.floor(sec / 60);
  const s = sec % 60;
  return `${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}`;
}

function CloseBtn({ onClick }) {
  return (
    <button className="icon-btn press" onClick={onClick} aria-label="Schließen"
      style={{ position: "absolute", top: 56, left: 18, zIndex: 4 }}>
      <svg viewBox="0 0 24 24" width="14" height="14" fill="none"
        stroke="currentColor" strokeWidth="1.6" strokeLinecap="round">
        <path d="M6 6 L18 18"/><path d="M18 6 L6 18"/>
      </svg>
    </button>
  );
}

/* Tick once per second */
function useTick(active = true) {
  const [n, setN] = uS_TR(0);
  uE_TR(() => {
    if (!active) return;
    const id = setInterval(() => setN(v => v + 1), 1000);
    return () => clearInterval(id);
  }, [active]);
  return n;
}

/* Continuous breath 0..1..0 over `period` seconds */
function useBreath(period = 6) {
  const [t, setT] = uS_TR(0);
  uE_TR(() => {
    let raf, start = performance.now();
    const loop = (now) => {
      const dt = ((now - start) / 1000) % period;
      setT(dt / period);
      raf = requestAnimationFrame(loop);
    };
    raf = requestAnimationFrame(loop);
    return () => cancelAnimationFrame(raf);
  }, [period]);
  return 0.5 - 0.5 * Math.cos(t * Math.PI * 2);
}

/* ============================================================
   PrepRoll — A. Atemkreis
   Kreis atmet, Sekunden im Zentrum, einziger Anker oben "Komme an"
   ============================================================ */
function PrepRollFinal({ seconds = 15, onSkip }) {
  const t = useTick(true);
  const remaining = Math.max(0, seconds - t);
  const breath = useBreath(6);
  const scale = 0.96 + breath * 0.08;

  return (
    <Ph_TR label="Pre-Roll · Atemkreis">
      <SB_TR/>
      <CloseBtn onClick={onSkip}/>

      {/* zarter Akzent-Glow im oberen Drittel */}
      <div style={{
        position: "absolute", inset: 0,
        background: "radial-gradient(ellipse 80% 60% at 50% 45%, var(--sm-accent-dim) 0%, transparent 70%)",
        pointerEvents: "none",
      }}/>

      <div className="screen-content no-tabbar" style={{
        position: "absolute", inset: 0, padding: "0 32px",
        display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center",
      }}>
        <div style={{
          position: "relative", width: 280, height: 280,
          display: "flex", alignItems: "center", justifyContent: "center",
        }}>
          {/* outer halo */}
          <div style={{
            position: "absolute", inset: -20, borderRadius: "50%",
            background: "radial-gradient(circle, var(--sm-accent-dim), transparent 65%)",
            transform: `scale(${1 + breath * 0.06})`,
          }}/>
          {/* breath circle — token-driven */}
          <div style={{
            width: 240, height: 240, borderRadius: "50%",
            border: "1px solid var(--sm-accent-soft)",
            transform: `scale(${scale})`,
            transition: "transform 100ms linear",
            boxShadow: `inset 0 0 40px var(--sm-accent-dim)`,
            opacity: 0.85,
          }}/>
          {/* center text */}
          <div style={{ position: "absolute", textAlign: "center" }}>
            <div className="eyebrow" style={{ fontSize: 11, marginBottom: 14 }}>Komme an</div>
            <div style={{
              fontFamily: "var(--sm-font-display)", fontSize: 84, lineHeight: 1,
              color: "var(--sm-text)", fontWeight: 300, letterSpacing: "-0.02em",
              fontVariantNumeric: "tabular-nums",
            }}>{remaining}</div>
          </div>
        </div>

        <div style={{
          position: "absolute", bottom: 84, left: 0, right: 0, textAlign: "center",
          fontFamily: "var(--sm-font-display)", fontStyle: "italic", fontSize: 17,
          color: "var(--sm-text-2)", letterSpacing: "0.01em",
        }}>Schön, dass du da bist.</div>
      </div>
    </Ph_TR>
  );
}

/* ============================================================
   Running — F. Atmender Ring
   Ring atmet leicht, Lichtperle wandert 1× rum, zarter Bogen
   zwischen 12 Uhr und Perle, Restzeit + "verbleibend" mittig
   ============================================================ */
function RunningTimerFinal({ duration = 600, elapsed = 124, onClose }) {
  const breath = useBreath(8);
  const remaining = Math.max(0, duration - elapsed);
  const progress = elapsed / duration;
  const r = 110;
  const angle = progress * 2 * Math.PI - Math.PI / 2;
  const knobX = 140 + Math.cos(angle) * r;
  const knobY = 140 + Math.sin(angle) * r;
  const arcLen = 2 * Math.PI * r;

  return (
    <Ph_TR label="Running · Atmender Ring">
      <SB_TR/>
      <CloseBtn onClick={onClose}/>

      <div style={{
        position: "absolute", inset: 0,
        background: "radial-gradient(ellipse 80% 60% at 50% 45%, var(--sm-accent-dim) 0%, transparent 70%)",
        pointerEvents: "none",
        opacity: 0.7,
      }}/>

      <div className="screen-content no-tabbar" style={{
        position: "absolute", inset: 0, padding: "0 32px",
        display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center",
      }}>
        <div style={{ position: "relative", width: 280, height: 280 }}>
          <svg width="280" height="280" style={{
            transform: `scale(${0.97 + breath * 0.04})`,
            transition: "transform 100ms linear",
            filter: `drop-shadow(0 0 ${10 + breath * 10}px var(--sm-accent-dim))`,
          }}>
            {/* base ring */}
            <circle cx="140" cy="140" r={r} fill="none"
              stroke="var(--sm-accent-soft)" strokeOpacity="0.35" strokeWidth="1"/>
            {/* progress arc 12 → perle */}
            <circle cx="140" cy="140" r={r} fill="none"
              stroke="var(--sm-accent-glow)" strokeOpacity="0.6" strokeWidth="1.5"
              strokeLinecap="round"
              strokeDasharray={`${progress * arcLen} ${arcLen}`}
              transform="rotate(-90 140 140)"/>
            {/* travelling light */}
            <circle cx={knobX} cy={knobY} r="5" fill="var(--sm-accent-glow)"
              style={{ filter: "drop-shadow(0 0 8px var(--sm-accent-glow))" }}/>
          </svg>

          <div style={{
            position: "absolute", inset: 0,
            display: "flex", flexDirection: "column",
            alignItems: "center", justifyContent: "center",
            transform: "translateY(-7px)",
          }}>
            <div style={{
              fontFamily: "var(--sm-font-display)", fontSize: 64, lineHeight: 1,
              color: "var(--sm-text)", fontWeight: 300, letterSpacing: "-0.01em",
              fontVariantNumeric: "tabular-nums",
            }}>{fmtTime(remaining)}</div>
            <div className="h-section" style={{ marginTop: 14, fontSize: 10 }}>
              verbleibend
            </div>
          </div>
        </div>
      </div>
    </Ph_TR>
  );
}

window.SM_PrepRunning = { PrepRollFinal, RunningTimerFinal };
