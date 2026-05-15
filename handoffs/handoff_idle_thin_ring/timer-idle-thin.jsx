/* Timer Idle — Thin Ring Variant
   Aligns the duration-selector ring with the running timer's visual language:
   - 1px base ring (sm-accent-soft, 35% opacity)
   - 1.5px progress arc (sm-accent-glow, 60% opacity, rounded cap)
   - small 5px light bead instead of a large knob
   - soft breath scale + glow halo, same as running timer
   - keeps interaction model from H2-Final (drag bead to pick minutes)
*/

const { useRef: uR_TT, useState: uS_TT, useEffect: uE_TT } = React;
const { StatusBar: SB_TT, TabBar: TB_TT, Phone: Ph_TT, Icons: Ic_TT } = window.SM;

/* Continuous breath 0..1..0 over `period` seconds — mirror of running timer */
function useBreathTT(period = 8) {
  const [t, setT] = uS_TT(0);
  uE_TT(() => {
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

function ThinRing({ minutes, setMinutes, max = 60, size = 262 }) {
  const r = 110, cx = size/2, cy = size/2;
  const ref = uR_TT(null), drag = uR_TT(false);
  const breath = useBreathTT(8);
  const t = minutes / max;
  const arcLen = 2 * Math.PI * r;
  const dashOn = t * arcLen;
  const knobA = t*2*Math.PI - Math.PI/2;
  const knobX = cx + Math.cos(knobA)*r;
  const knobY = cy + Math.sin(knobA)*r;

  const handle = (e) => {
    if (!ref.current) return;
    const tt = e.touches ? e.touches[0] : e;
    const rect = ref.current.getBoundingClientRect();
    const x = tt.clientX - rect.left - cx;
    const y = tt.clientY - rect.top - cy;
    let a = Math.atan2(y, x) + Math.PI/2;
    if (a < 0) a += 2*Math.PI;
    setMinutes(Math.max(1, Math.round((a/(2*Math.PI))*max)));
  };

  return (
    <div ref={ref}
      style={{ width: size, height: size, position: "relative", touchAction: "none", margin: "0 auto" }}
      onMouseDown={(e)=>{drag.current=true; handle(e);}}
      onMouseMove={(e)=>drag.current && handle(e)}
      onMouseUp={()=>drag.current=false}
      onMouseLeave={()=>drag.current=false}
      onTouchStart={(e)=>{drag.current=true; handle(e);}}
      onTouchMove={(e)=>drag.current && handle(e)}
      onTouchEnd={()=>drag.current=false}>
      <svg width={size} height={size} style={{
        transform: `scale(${0.98 + breath * 0.03})`,
        transition: "transform 100ms linear",
        filter: `drop-shadow(0 0 ${8 + breath * 8}px var(--sm-accent-dim))`,
        display: "block",
      }}>
        {/* base ring — exactly like running timer */}
        <circle cx={cx} cy={cy} r={r} fill="none"
          stroke="var(--sm-accent-soft)" strokeOpacity="0.35" strokeWidth="1"/>
        {/* progress arc — exactly like running timer */}
        <circle cx={cx} cy={cy} r={r} fill="none"
          stroke="var(--sm-accent-glow)" strokeOpacity="0.6" strokeWidth="1.5"
          strokeLinecap="round"
          strokeDasharray={`${dashOn} ${arcLen}`}
          transform={`rotate(-90 ${cx} ${cy})`}/>
        {/* small travelling bead — same size as running timer */}
        <circle cx={knobX} cy={knobY} r="5" fill="var(--sm-accent-glow)"
          style={{ filter: "drop-shadow(0 0 8px var(--sm-accent-glow))" }}/>
      </svg>

      <div style={{
        position: "absolute", inset: 0,
        display: "flex", flexDirection: "column",
        alignItems: "center", justifyContent: "center",
        pointerEvents: "none",
      }}>
        <div style={{
          fontFamily: "var(--sm-font-display)", fontSize: 76, lineHeight: 1,
          color: "var(--sm-text)", fontWeight: 300, letterSpacing: "-0.02em",
          fontVariantNumeric: "tabular-nums",
        }}>{minutes}</div>
        <div style={{
          fontSize: 11, letterSpacing: "0.28em", color: "var(--sm-text-2)",
          marginTop: 6, textTransform: "uppercase",
        }}>Minuten</div>
      </div>
    </div>
  );
}

/* Setting row — matches the iOS app's current style:
   label left, value + chevron right, hairline dividers between rows */
function SettingRowTT({ label, value, on, onClick }) {
  const dim = on === false;
  return (
    <button onClick={onClick} className="press"
      style={{
        all: "unset", cursor: "pointer",
        display: "flex", alignItems: "center", justifyContent: "space-between",
        width: "100%", padding: "16px 24px",
        opacity: dim ? 0.5 : 1,
        transition: "opacity 0.2s",
      }}>
      <span style={{
        fontFamily: "var(--sm-font-display)", fontSize: 17, fontWeight: 400,
        color: "var(--sm-text)", letterSpacing: "-0.005em",
      }}>{label}</span>
      <span style={{
        display: "inline-flex", alignItems: "center", gap: 8,
        fontFamily: "var(--sm-font-ui)", fontSize: 15,
        color: "var(--sm-accent-text)",
      }}>
        {value}
        <svg viewBox="0 0 24 24" width="11" height="11" fill="none"
          stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"
          style={{ opacity: 0.7 }}>
          <path d="M9 6 L15 12 L9 18"/>
        </svg>
      </span>
    </button>
  );
}

function SettingDividerTT() {
  return (
    <div style={{
      height: 1, margin: "0 24px",
      background: "rgba(235,226,214,0.07)",
    }}/>
  );
}

function TimerIdleThin({ minutes, setMinutes, dense, onStart, onOpenConfig, activeTab, setActiveTab }) {
  const rows = [
    { key: "prep",     label: "Vorbereitung",
      value: dense.prepOn ? dense.prepDur : "Aus", on: dense.prepOn },
    { key: "gong",     label: "Gong",
      value: dense.gong, on: true },
    { key: "interval", label: "Intervall",
      value: dense.intervalOn ? dense.interval : "Aus", on: dense.intervalOn },
    { key: "ambient",  label: "Hintergrund",
      value: dense.ambientOn ? dense.ambient : "Stille", on: dense.ambientOn },
  ];
  return (
    <Ph_TT label="Timer Idle — Dünner Ring (Running-Sprache)">
      <SB_TT/>
      {/* gentle accent glow behind the ring, same as running timer */}
      <div style={{
        position: "absolute", inset: 0,
        background: "radial-gradient(ellipse 80% 60% at 50% 38%, var(--sm-accent-dim) 0%, transparent 70%)",
        pointerEvents: "none",
        opacity: 0.55,
      }}/>
      <div className="screen-content" style={{
        position: "relative",
        display: "flex", flexDirection: "column",
      }}>
        <div style={{ position: "relative", zIndex: 1, flex: 1,
          display: "flex", flexDirection: "column" }}>
          <div style={{ textAlign: "center", padding: "10px 32px 0" }}>
            <div className="h-display" style={{ fontSize: 22, fontWeight: 400 }}>Wie viel Zeit schenkst du dir?</div>
          </div>
          <div style={{ marginTop: 22 }}>
            <ThinRing minutes={minutes} setMinutes={setMinutes} size={262}/>
          </div>

          {/* settings list — rows with chevrons (matches iOS implementation) */}
          <div style={{ marginTop: 28 }}>
            <SettingDividerTT/>
            {rows.map((r, i) => (
              <React.Fragment key={r.key}>
                <SettingRowTT {...r} onClick={() => onOpenConfig?.(r.key)}/>
                {i < rows.length - 1 && <SettingDividerTT/>}
              </React.Fragment>
            ))}
            <SettingDividerTT/>
          </div>

          <div style={{ textAlign: "center", marginTop: "auto", paddingTop: 28, paddingBottom: 8 }}>
            <button className="btn-primary press" onClick={onStart}>
              <span style={{ width: 18, height: 18, display: "inline-flex" }}>{Ic_TT.play}</span>
              Beginnen
            </button>
          </div>
        </div>
      </div>
      <TB_TT active={activeTab} onChange={setActiveTab}/>
    </Ph_TT>
  );
}

/* Mini side-by-side comparison: idle vs running, with the same ring */
function ThinRingPreview({ minutes = 10, max = 60, progress = 0.2, label = "Idle", size = 200 }) {
  const r = 84, cx = size/2, cy = size/2;
  const arcLen = 2 * Math.PI * r;
  const t = label === "Idle" ? minutes / max : progress;
  const dashOn = t * arcLen;
  const knobA = t*2*Math.PI - Math.PI/2;
  const knobX = cx + Math.cos(knobA)*r;
  const knobY = cy + Math.sin(knobA)*r;
  return (
    <div style={{ width: size, height: size, position: "relative", margin: "0 auto" }}>
      <svg width={size} height={size}
        style={{ filter: `drop-shadow(0 0 10px var(--sm-accent-dim))` }}>
        <circle cx={cx} cy={cy} r={r} fill="none"
          stroke="var(--sm-accent-soft)" strokeOpacity="0.35" strokeWidth="1"/>
        <circle cx={cx} cy={cy} r={r} fill="none"
          stroke="var(--sm-accent-glow)" strokeOpacity="0.6" strokeWidth="1.5"
          strokeLinecap="round"
          strokeDasharray={`${dashOn} ${arcLen}`}
          transform={`rotate(-90 ${cx} ${cy})`}/>
        <circle cx={knobX} cy={knobY} r="5" fill="var(--sm-accent-glow)"
          style={{ filter: "drop-shadow(0 0 8px var(--sm-accent-glow))" }}/>
      </svg>
      <div style={{ position: "absolute", inset: 0, display: "flex",
        flexDirection: "column", alignItems: "center", justifyContent: "center",
        pointerEvents: "none" }}>
        <div style={{
          fontFamily: "var(--sm-font-display)", fontSize: label === "Idle" ? 56 : 32,
          lineHeight: 1, color: "var(--sm-text)", fontWeight: 300, letterSpacing: "-0.02em",
          fontVariantNumeric: "tabular-nums",
        }}>{label === "Idle" ? minutes : "08:00"}</div>
        <div style={{
          fontSize: 10, letterSpacing: "0.28em", color: "var(--sm-text-2)",
          marginTop: 6, textTransform: "uppercase",
        }}>{label === "Idle" ? "Minuten" : "verbleibend"}</div>
      </div>
    </div>
  );
}

function RingCompare() {
  return (
    <Ph_TT label="Ring-Vergleich">
      <SB_TT/>
      <div className="screen-content" style={{ padding: "60px 24px 0" }}>
        <div style={{ textAlign: "center", marginBottom: 28 }}>
          <div className="h-display" style={{ fontSize: 18, fontWeight: 400 }}>Gleiche Ring-Sprache</div>
          <div style={{ fontSize: 11, color: "var(--sm-text-2)", marginTop: 6,
            letterSpacing: "0.02em", textWrap: "balance" }}>
            Idle und laufender Timer teilen sich Strichstärke, Bogen und Lichtperle.
          </div>
        </div>

        <div style={{ display: "flex", flexDirection: "column", gap: 24 }}>
          <div>
            <div style={{ fontSize: 10, letterSpacing: "0.2em", textTransform: "uppercase",
              color: "var(--sm-text-3)", textAlign: "center", marginBottom: 8 }}>Idle — Dauer wählen</div>
            <ThinRingPreview minutes={10} label="Idle"/>
          </div>
          <div>
            <div style={{ fontSize: 10, letterSpacing: "0.2em", textTransform: "uppercase",
              color: "var(--sm-text-3)", textAlign: "center", marginBottom: 8 }}>Laufend — Restzeit</div>
            <ThinRingPreview progress={0.2} label="Running"/>
          </div>
        </div>
      </div>
    </Ph_TT>
  );
}

window.SM_TimerIdleThin = { TimerIdleThin, RingCompare };
