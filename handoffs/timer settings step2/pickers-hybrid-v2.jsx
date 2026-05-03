/* Step 2 — Hybrid-Variante 6: Atemkreis + Tap-Kokon
   Ziel: Geschwindigkeit (Drag im Kreis) + Präzision (−/+ Buttons).

   Aufbau:
   - Atemkreis-Dial in der Mitte, ziehbar wie Variante 1
   - Drag = grobe/schnelle Wahl ("ich will ungefähr 20 Min")
   - −/+ Buttons unter dem Kreis = Feintuning auf die Minute
   - Wert in der Mitte; Ring zeigt gleichzeitig Position und Fortschritt
*/

const { useState: uS_HV2, useRef: uR_HV2, useEffect: uE_HV2 } = React;
const clamp_HV2 = (v, lo, hi) => Math.max(lo, Math.min(hi, v));

function BreathDialPlusV2({ value, onChange, max = 60 }) {
  const SIZE = 220;
  const R_OUT = 100;
  const R_IN  = 84;
  const ref = uR_HV2(null);
  const dragging = uR_HV2(false);

  const angleFor = (v) => (v / max) * 360 - 90;
  const valueFromAngle = (deg) => {
    let a = (deg + 90) % 360;
    if (a < 0) a += 360;
    const v = Math.round((a / 360) * max);
    return clamp_HV2(v === 0 ? 1 : v, 1, max);
  };
  const updateFromEvent = (e) => {
    if (!ref.current) return;
    const rect = ref.current.getBoundingClientRect();
    const cx = rect.left + rect.width / 2;
    const cy = rect.top + rect.height / 2;
    const p = e.touches ? e.touches[0] : e;
    const dx = p.clientX - cx;
    const dy = p.clientY - cy;
    const deg = Math.atan2(dy, dx) * (180 / Math.PI);
    const nv = valueFromAngle(deg);
    if (nv !== value) onChange?.(nv);
  };
  const onDown = (e) => { dragging.current = true; updateFromEvent(e); e.preventDefault(); };
  const onMove = (e) => { if (dragging.current) updateFromEvent(e); };
  const onUp   = () => { dragging.current = false; };

  uE_HV2(() => {
    window.addEventListener("mousemove", onMove);
    window.addEventListener("mouseup", onUp);
    window.addEventListener("touchmove", onMove, { passive: false });
    window.addEventListener("touchend", onUp);
    return () => {
      window.removeEventListener("mousemove", onMove);
      window.removeEventListener("mouseup", onUp);
      window.removeEventListener("touchmove", onMove);
      window.removeEventListener("touchend", onUp);
    };
  });

  // −/+ mit Long-Press-Beschleunigung
  const holdTimer = uR_HV2(null);
  const holdInt = uR_HV2(null);
  const bump = (delta) => onChange?.(clamp_HV2(value + delta, 1, max));
  const startHold = (delta) => {
    bump(delta);
    holdTimer.current = setTimeout(() => {
      holdInt.current = setInterval(() => bump(delta), 80);
    }, 320);
  };
  const endHold = () => {
    if (holdTimer.current) clearTimeout(holdTimer.current);
    if (holdInt.current) clearInterval(holdInt.current);
    holdTimer.current = null; holdInt.current = null;
  };

  const ang = angleFor(value);
  const rad = (ang * Math.PI) / 180;
  const dropX = SIZE / 2 + Math.cos(rad) * ((R_OUT + R_IN) / 2);
  const dropY = SIZE / 2 + Math.sin(rad) * ((R_OUT + R_IN) / 2);

  // V2: Tick-Marken entfernt — der Kreis trägt seine Bedeutung selbst.

  const arcPath = (() => {
    const startA = -90;
    const endA = ang;
    const r = (R_OUT + R_IN) / 2;
    const sx = SIZE / 2 + Math.cos((startA * Math.PI) / 180) * r;
    const sy = SIZE / 2 + Math.sin((startA * Math.PI) / 180) * r;
    const ex = SIZE / 2 + Math.cos((endA * Math.PI) / 180) * r;
    const ey = SIZE / 2 + Math.sin((endA * Math.PI) / 180) * r;
    const sweep = ((endA - startA + 360) % 360) > 180 ? 1 : 0;
    return `M ${sx} ${sy} A ${r} ${r} 0 ${sweep} 1 ${ex} ${ey}`;
  })();

  return (
    <div style={{ height: 280, position: "relative", userSelect: "none" }}>
      {/* Dial — kompakter als die Solo-Variante, damit unten Platz für Buttons ist */}
      <div ref={ref}
        onMouseDown={onDown} onTouchStart={onDown}
        style={{
          position: "absolute", left: "50%", top: 0, transform: "translateX(-50%)",
          width: SIZE, height: SIZE, cursor: "grab", touchAction: "none",
        }}>
        <svg width={SIZE} height={SIZE} style={{ position: "absolute", inset: 0 }}>
          <defs>
            <radialGradient id="bdp-glow" cx="50%" cy="50%" r="50%">
              <stop offset="0%"  stopColor="rgba(214,138,110,0.18)"/>
              <stop offset="60%" stopColor="rgba(214,138,110,0.04)"/>
              <stop offset="100%" stopColor="rgba(214,138,110,0)"/>
            </radialGradient>
            <linearGradient id="bdp-arc" x1="0" y1="0" x2="1" y2="1">
              <stop offset="0%" stopColor="#d99a7e"/>
              <stop offset="100%" stopColor="#c47a5e"/>
            </linearGradient>
          </defs>
          <circle cx={SIZE/2} cy={SIZE/2} r={R_OUT + 22} fill="url(#bdp-glow)"/>
          <circle cx={SIZE/2} cy={SIZE/2} r={(R_OUT + R_IN)/2}
                  fill="none" stroke="rgba(235,226,214,0.07)" strokeWidth={R_OUT - R_IN}/>
          <path d={arcPath} stroke="url(#bdp-arc)" strokeWidth={R_OUT - R_IN}
                strokeLinecap="round" fill="none" opacity={0.85}/>
          {/* Drag-Tropfen — größer + sanfter Pulse-Halo, damit klar wird: anfassbar */}
          <circle cx={dropX} cy={dropY} r={20} fill="rgba(217,154,126,0.18)">
            <animate attributeName="r" values="18;26;18" dur="2.6s" repeatCount="indefinite"/>
            <animate attributeName="opacity" values="0.35;0.05;0.35" dur="2.6s" repeatCount="indefinite"/>
          </circle>
          <circle cx={dropX} cy={dropY} r={14} fill="#0f0604" stroke="#d99a7e" strokeWidth={1.8}/>
          <circle cx={dropX} cy={dropY} r={6.5} fill="#d99a7e"/>
        </svg>
        {/* Zentrale Zahl */}
        <div style={{
          position: "absolute", inset: 0, display: "flex", flexDirection: "column",
          alignItems: "center", justifyContent: "center", pointerEvents: "none",
        }}>
          <div style={{
            fontFamily: "var(--sm-font-display)", fontWeight: 300,
            fontSize: 76, lineHeight: 1, color: "var(--sm-text)",
            letterSpacing: "-0.03em",
          }}>{value}</div>
          <div style={{
            marginTop: 4, fontSize: 9.5, letterSpacing: "0.26em", textTransform: "uppercase",
            color: "var(--sm-text-3)",
          }}>Minuten</div>
        </div>
      </div>

      {/* −/+ Buttons radial vom Dial-Zentrum nach außen geschoben (Variante B+).
          Achse: Dial-Mittelpunkt → Button-Mittelpunkt. Symmetrisch unten links/rechts.
          Dial sitzt im äußeren Container zentriert (left:50%, top:0, width=SIZE),
          also liegt die Dial-Mitte im äußeren Container bei (50%, SIZE/2).
          Wir verankern die Buttons mit left:50% und translaten um den
          radialen Offset. */}
      {(() => {
        const BTN = 44;
        // Tick-Rand: R_OUT + 14 = 114. Verdoppelter Abstand zum Rand:
        // Button-Mittelpunkt-Radius vom Dial-Zentrum.
        const RADIUS = 168;
        const ANGLE = 45;             // Grad — 7- und 5-Uhr-Position
        const dx = Math.cos((ANGLE * Math.PI) / 180) * RADIUS;
        const dy = Math.sin((ANGLE * Math.PI) / 180) * RADIUS;
        const dialCY = SIZE / 2;      // y der Dial-Mitte im äußeren Container
        const baseBtn = {
          position: "absolute",
          width: BTN, height: BTN, borderRadius: "50%",
          background: "rgba(235,226,214,0.04)",
          border: "1px solid rgba(235,226,214,0.10)",
          color: "var(--sm-text)", fontSize: 20, lineHeight: 1, cursor: "pointer",
          fontFamily: "var(--sm-font-display)", fontWeight: 300,
          transition: "opacity 0.2s",
          display: "flex", alignItems: "center", justifyContent: "center",
        };
        return (
          <React.Fragment>
            <button
              onMouseDown={() => startHold(-1)} onMouseUp={endHold} onMouseLeave={endHold}
              onTouchStart={(e) => { e.preventDefault(); startHold(-1); }} onTouchEnd={endHold}
              aria-label="Eine Minute weniger" disabled={value <= 1}
              style={{
                ...baseBtn,
                left: `calc(50% - ${dx}px - ${BTN / 2}px)`,
                top: dialCY + dy - BTN / 2,
                opacity: value <= 1 ? 0.3 : 1,
              }}>−</button>
            <button
              onMouseDown={() => startHold(1)} onMouseUp={endHold} onMouseLeave={endHold}
              onTouchStart={(e) => { e.preventDefault(); startHold(1); }} onTouchEnd={endHold}
              aria-label="Eine Minute mehr" disabled={value >= max}
              style={{
                ...baseBtn,
                left: `calc(50% + ${dx}px - ${BTN / 2}px)`,
                top: dialCY + dy - BTN / 2,
                opacity: value >= max ? 0.3 : 1,
              }}>+</button>
          </React.Fragment>
        );
      })()}
    </div>
  );
}

window.SM_PickersHybridV2 = { BreathDialPlusV2 };
