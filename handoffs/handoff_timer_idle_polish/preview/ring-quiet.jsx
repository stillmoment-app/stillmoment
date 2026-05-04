/* Ring-Quiet — minimal Atemkreis, ohne externe Buttons.
   Optionales `compact` für Variante C (Hero); sonst Standardgröße.
   −/+ können optional als kleine Glyphen direkt links/rechts der Zahl gerendert werden.
*/

const { useRef: uR_RQ, useEffect: uE_RQ } = React;
const clamp_RQ = (v, lo, hi) => Math.max(lo, Math.min(hi, v));

function RingQuiet({ value, onChange, max = 60, size = 240, showInlineSteppers = false }) {
  const SIZE = size;
  const R_OUT = Math.round(SIZE * 0.42);
  const R_IN  = R_OUT - 16;
  const ref = uR_RQ(null);
  const dragging = uR_RQ(false);

  const angleFor = (v) => (v / max) * 360 - 90;
  const valueFromAngle = (deg) => {
    let a = (deg + 90) % 360;
    if (a < 0) a += 360;
    const v = Math.round((a / 360) * max);
    return clamp_RQ(v === 0 ? 1 : v, 1, max);
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

  uE_RQ(() => {
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

  const ang = angleFor(value);
  const rad = (ang * Math.PI) / 180;
  const trackR = (R_OUT + R_IN) / 2;
  const dropX = SIZE / 2 + Math.cos(rad) * trackR;
  const dropY = SIZE / 2 + Math.sin(rad) * trackR;
  const arcPath = (() => {
    const startA = -90;
    const endA = ang;
    const sx = SIZE / 2 + Math.cos((startA * Math.PI) / 180) * trackR;
    const sy = SIZE / 2 + Math.sin((startA * Math.PI) / 180) * trackR;
    const ex = SIZE / 2 + Math.cos((endA * Math.PI) / 180) * trackR;
    const ey = SIZE / 2 + Math.sin((endA * Math.PI) / 180) * trackR;
    const sweep = ((endA - startA + 360) % 360) > 180 ? 1 : 0;
    return `M ${sx} ${sy} A ${trackR} ${trackR} 0 ${sweep} 1 ${ex} ${ey}`;
  })();

  const stepperBase = {
    width: 28, height: 28, borderRadius: "50%",
    background: "transparent",
    border: "1px solid rgba(235,226,214,0.12)",
    color: "var(--sm-text-2)", fontSize: 16, lineHeight: 1, cursor: "pointer",
    fontFamily: "var(--sm-font-display)", fontWeight: 300,
    display: "flex", alignItems: "center", justifyContent: "center",
    padding: 0,
  };

  return (
    <div style={{ width: SIZE, height: SIZE, margin: "0 auto", position: "relative", userSelect: "none" }}>
      <div ref={ref}
        onMouseDown={onDown} onTouchStart={onDown}
        style={{ position: "absolute", inset: 0, cursor: "grab", touchAction: "none" }}>
        <svg width={SIZE} height={SIZE} style={{ position: "absolute", inset: 0 }}>
          <defs>
            <radialGradient id={`rq-glow-${SIZE}`} cx="50%" cy="50%" r="50%">
              <stop offset="0%"  stopColor="rgba(214,138,110,0.14)"/>
              <stop offset="60%" stopColor="rgba(214,138,110,0.03)"/>
              <stop offset="100%" stopColor="rgba(214,138,110,0)"/>
            </radialGradient>
            <linearGradient id={`rq-arc-${SIZE}`} x1="0" y1="0" x2="1" y2="1">
              <stop offset="0%" stopColor="#d99a7e"/>
              <stop offset="100%" stopColor="#c47a5e"/>
            </linearGradient>
          </defs>
          <circle cx={SIZE/2} cy={SIZE/2} r={R_OUT + 18} fill={`url(#rq-glow-${SIZE})`}/>
          <circle cx={SIZE/2} cy={SIZE/2} r={trackR}
                  fill="none" stroke="rgba(235,226,214,0.06)" strokeWidth={R_OUT - R_IN}/>
          <path d={arcPath} stroke={`url(#rq-arc-${SIZE})`} strokeWidth={R_OUT - R_IN}
                strokeLinecap="round" fill="none" opacity={0.9}/>
          <circle cx={dropX} cy={dropY} r={9} fill="#0f0604" stroke="#d99a7e" strokeWidth={1.5}/>
          <circle cx={dropX} cy={dropY} r={4} fill="#d99a7e"/>
        </svg>
      </div>
      <div style={{
        position: "absolute", inset: 0, display: "flex", flexDirection: "column",
        alignItems: "center", justifyContent: "center", pointerEvents: "none",
      }}>
        <div style={{ display: "flex", alignItems: "baseline", gap: 14, pointerEvents: "auto" }}>
          {showInlineSteppers && (
            <button
              onClick={(e) => { e.stopPropagation(); onChange?.(clamp_RQ(value - 1, 1, max)); }}
              aria-label="Eine Minute weniger"
              style={{ ...stepperBase, opacity: value <= 1 ? 0.3 : 0.8 }}
              disabled={value <= 1}>−</button>
          )}
          <div style={{
            fontFamily: "var(--sm-font-display)", fontWeight: 300,
            fontSize: Math.round(SIZE * 0.32), lineHeight: 1, color: "var(--sm-text)",
            letterSpacing: "-0.03em",
          }}>{value}</div>
          {showInlineSteppers && (
            <button
              onClick={(e) => { e.stopPropagation(); onChange?.(clamp_RQ(value + 1, 1, max)); }}
              aria-label="Eine Minute mehr"
              style={{ ...stepperBase, opacity: value >= max ? 0.3 : 0.8 }}
              disabled={value >= max}>+</button>
          )}
        </div>
        <div style={{
          marginTop: 6, fontSize: 9.5, letterSpacing: "0.28em", textTransform: "uppercase",
          color: "var(--sm-text-3)",
        }}>Minuten</div>
      </div>
    </div>
  );
}

window.SM_RingQuiet = { RingQuiet };
