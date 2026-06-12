/* Still Moment — Waveform Player · „Tonkopf"

   Feste Mittellinie = das Jetzt. Die echte (hier synthetische) Waveform
   scrollt daran vorbei. Vergangenes links in Kupfer, Kommendes rechts blass.
   Drag-Scrub: Welle greifen → pausiert, ziehen spult, loslassen → läuft weiter.
   Dunkles Mahagoni-Theme (styles.css). Zentrale Restzeit unten, Play/Pause.
*/

const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "demoSpeed": 3,
  "totalMinutes": 26,
  "windowSec": 60,
  "progressStyle": "mini",
  "edgeFade": true,
  "showBreathHint": true,
  "showDragHint": true
}/*EDITMODE-END*/;

const SHELL_W = 393;
const SHELL_H = 852;

const TRACK = { artist: "Jon Salzberg", title: "Present Moment Awareness" };

/* ============================================================
   Synthetic waveform — guided-meditation profile
   Dense speech at the open + close, quiet stretches in the middle
   with the occasional spoken cue. Values 0..1, ~4 buckets / second.
   In the app: AudioContext.decodeAudioData → peak per bucket, cached.
   ============================================================ */
const BUCKETS_PER_SEC = 4;

function buildWave(totalSec) {
  const n = Math.round(totalSec * BUCKETS_PER_SEC);
  const a = new Float32Array(n);
  let s = 1234567;
  const rnd = () => { s = (s * 1664525 + 1013904223) >>> 0; return s / 4294967296; };
  // a few spoken "cue" islands scattered through the quiet middle
  const cues = [];
  for (let t = 120; t < totalSec - 120; t += 70 + rnd() * 80) {
    cues.push({ at: t, len: 6 + rnd() * 14 });
  }
  for (let i = 0; i < n; i++) {
    const sec = i / BUCKETS_PER_SEC;
    const tNorm = sec / totalSec;
    let env; // overall loudness envelope
    if (sec < 70) {
      // intro speech — full, syllabic
      env = 0.55 + 0.35 * Math.abs(Math.sin(i * 0.55)) + 0.12 * rnd();
    } else if (sec > totalSec - 70) {
      // closing words
      env = 0.5 + 0.34 * Math.abs(Math.sin(i * 0.5)) + 0.12 * rnd();
    } else {
      // quiet meditation — low breath floor
      env = 0.06 + 0.06 * rnd();
      const breath = 0.04 * (0.5 + 0.5 * Math.sin(sec * 0.7)); // slow breathing ripple
      env += breath;
      for (const c of cues) {
        const d = sec - c.at;
        if (d > 0 && d < c.len) {
          const k = Math.sin((d / c.len) * Math.PI); // swell in/out
          env += k * (0.4 + 0.32 * Math.abs(Math.sin(i * 0.6)) + 0.1 * rnd());
        }
      }
    }
    // gentle global fade at the very ends
    const tails = Math.min(1, sec / 4) * Math.min(1, (totalSec - sec) / 6);
    a[i] = Math.max(0.015, Math.min(1, env * tails));
  }
  return a;
}

function sampleWave(wave, sec) {
  const i = Math.round(sec * BUCKETS_PER_SEC);
  if (i < 0 || i >= wave.length) return -1; // out of bounds
  return wave[i];
}

function fmt(sec) {
  sec = Math.max(0, Math.floor(sec));
  const m = Math.floor(sec / 60), s = sec % 60;
  return m + ":" + String(s).padStart(2, "0");
}

/* read theme colors from CSS once */
function useThemeColors() {
  return React.useMemo(() => {
    const cs = getComputedStyle(document.documentElement);
    const v = (k, fb) => (cs.getPropertyValue(k).trim() || fb);
    return {
      accent: v("--sm-accent", "#c47a5e"),
      accentGlow: v("--sm-accent-glow", "#d68a6e"),
      accentSoft: v("--sm-accent-soft", "#b06a4f"),
      text: v("--sm-text", "#ebe2d6"),
      text3: v("--sm-text-3", "#6f6358"),
    };
  }, []);
}

/* ============================================================
   Phone chrome
   ============================================================ */
function StatusBar() {
  return (
    <div data-no-scrub style={{
      position: "absolute", top: 0, left: 0, right: 0, height: 54,
      padding: "18px 30px 0", display: "flex", alignItems: "center",
      justifyContent: "space-between",
      fontFamily: '-apple-system, "SF Pro Text", system-ui, sans-serif',
      fontWeight: 600, fontSize: 15, color: "var(--sm-text)", zIndex: 20
    }}>
      <span>9:41</span>
      <div style={{ display: "flex", gap: 6, alignItems: "center", opacity: 0.92 }}>
        <svg width="17" height="11" viewBox="0 0 17 11"><g fill="var(--sm-text)">
          <rect x="0" y="7" width="3" height="4" rx="1"/><rect x="4.5" y="5" width="3" height="6" rx="1"/>
          <rect x="9" y="2.5" width="3" height="8.5" rx="1"/><rect x="13.5" y="0" width="3" height="11" rx="1"/>
        </g></svg>
        <svg width="16" height="11" viewBox="0 0 18 11"><path d="M9 11.5L1 3.5C5 -0.5 13 -0.5 17 3.5L9 11.5Z" stroke="var(--sm-text)" strokeWidth="1.4" fill="none"/></svg>
        <div style={{ width: 24, height: 12, borderRadius: 3, border: "1.4px solid var(--sm-text)", padding: 1.5 }}>
          <div style={{ width: "82%", height: "100%", background: "var(--sm-text)", borderRadius: 1 }}/>
        </div>
      </div>
    </div>
  );
}

function CloseBtn({ onClick }) {
  return (
    <button data-no-scrub onClick={onClick} onPointerDown={(e) => e.stopPropagation()}
      aria-label="Schließen" style={{
        position: "absolute", top: 60, left: 20, zIndex: 22,
        width: 40, height: 40, borderRadius: "50%",
        border: "1px solid rgba(235,226,214,0.08)", background: "rgba(235,226,214,0.05)",
        display: "inline-flex", alignItems: "center", justifyContent: "center",
        cursor: "pointer", color: "var(--sm-text)", padding: 0
      }}>
      <svg width="16" height="16" viewBox="0 0 18 18" fill="none">
        <path d="M3 3L15 15M15 3L3 15" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round"/>
      </svg>
    </button>
  );
}

function PlayPause({ playing, onToggle }) {
  return (
    <button onClick={(e) => { e.stopPropagation(); onToggle(); }}
      onPointerDown={(e) => e.stopPropagation()}
      aria-label={playing ? "Pause" : "Weiter"}
      style={{
        width: 74, height: 74, borderRadius: "50%",
        background: "linear-gradient(180deg, var(--sm-accent-glow), var(--sm-accent-soft))",
        border: "none", color: "#2a1208", cursor: "pointer", padding: 0,
        display: "inline-flex", alignItems: "center", justifyContent: "center",
        boxShadow: "0 16px 38px -12px rgba(196,122,94,0.6), inset 0 0 0 1px rgba(214,138,110,0.35)",
        transition: "transform 0.16s ease"
      }}
      onMouseDown={(e) => e.currentTarget.style.transform = "scale(0.95)"}
      onMouseUp={(e) => e.currentTarget.style.transform = "scale(1)"}
      onMouseLeave={(e) => e.currentTarget.style.transform = "scale(1)"}>
      {playing ? (
        <svg width="26" height="26" viewBox="0 0 26 26"><g fill="#2a1208">
          <rect x="6.5" y="5" width="4.2" height="16" rx="1.4"/><rect x="15.3" y="5" width="4.2" height="16" rx="1.4"/>
        </g></svg>
      ) : (
        <svg width="26" height="26" viewBox="0 0 26 26"><path d="M8 4.5 L21 13 L8 21.5 Z" fill="#2a1208" strokeLinejoin="round"/></svg>
      )}
    </button>
  );
}

/* ============================================================
   Tonkopf waveform window — canvas, scrolls past a fixed center
   ============================================================ */
function WaveWindow({ wave, totalSec, now, windowSec, colors, edgeFade, dragging }) {
  const canvasRef = React.useRef(null);
  const sizeRef = React.useRef({ w: SHELL_W, h: 188, dpr: 1 });

  React.useEffect(() => {
    const cv = canvasRef.current;
    if (!cv) return;
    const dpr = Math.min(window.devicePixelRatio || 1, 2.5);
    const w = cv.clientWidth, h = cv.clientHeight;
    cv.width = Math.round(w * dpr);
    cv.height = Math.round(h * dpr);
    sizeRef.current = { w, h, dpr };
  });

  React.useEffect(() => {
    const cv = canvasRef.current;
    if (!cv) return;
    const { w, h, dpr } = sizeRef.current;
    const ctx = cv.getContext("2d");
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    ctx.clearRect(0, 0, w, h);

    const cx = w / 2;
    const cy = h / 2;
    const pxPerSec = w / windowSec;
    const barStep = 3.2;          // px between bar centers
    const barW = 2.0;
    const maxHalf = h * 0.40;

    const nBars = Math.ceil(w / barStep) + 2;
    for (let k = 0; k < nBars; k++) {
      const x = k * barStep;
      const sec = now + (x - cx) / pxPerSec;
      const amp = sampleWave(wave, sec);
      if (amp < 0) continue; // out of track

      const half = Math.max(0.8, amp * maxHalf);
      const past = sec <= now;

      // horizontal edge fade
      let alpha = 1;
      if (edgeFade) {
        const edge = 56;
        const dl = x, dr = w - x;
        const e = Math.min(dl, dr);
        if (e < edge) alpha = Math.max(0, e / edge);
      }

      if (past) {
        ctx.fillStyle = colors.accent;
        ctx.globalAlpha = alpha * (0.55 + 0.45 * amp);
      } else {
        ctx.fillStyle = colors.text;
        ctx.globalAlpha = alpha * 0.16;
      }
      const rx = x - barW / 2;
      const ry = cy - half;
      const rh = half * 2;
      // rounded bar
      const r = barW / 2;
      ctx.beginPath();
      ctx.moveTo(rx, ry + r);
      ctx.arcTo(rx, ry, rx + r, ry, r);
      ctx.arcTo(rx + barW, ry, rx + barW, ry + r, r);
      ctx.lineTo(rx + barW, ry + rh - r);
      ctx.arcTo(rx + barW, ry + rh, rx + barW - r, ry + rh, r);
      ctx.arcTo(rx, ry + rh, rx, ry + rh - r, r);
      ctx.closePath();
      ctx.fill();
    }
    ctx.globalAlpha = 1;

    // soft center baseline tick fading outwards (very subtle)
    // playhead glow line
    ctx.save();
    ctx.shadowColor = colors.accentGlow;
    ctx.shadowBlur = 12;
    ctx.fillStyle = colors.accentGlow;
    ctx.fillRect(cx - 1, 6, 2, h - 12);
    ctx.restore();
  }, [wave, now, windowSec, colors, edgeFade, totalSec]);

  return (
    <canvas ref={canvasRef} style={{
      display: "block", width: "100%", height: 188,
      cursor: dragging ? "grabbing" : "grab", touchAction: "none"
    }}/>
  );
}

/* full-track mini overview (also draggable) */
function MiniOverview({ wave, totalSec, now, colors }) {
  const ref = React.useRef(null);
  const W = 321, H = 30;
  React.useEffect(() => {
    const cv = ref.current; if (!cv) return;
    const dpr = Math.min(window.devicePixelRatio || 1, 2.5);
    cv.width = W * dpr; cv.height = H * dpr;
    const ctx = cv.getContext("2d");
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    ctx.clearRect(0, 0, W, H);
    const cy = H / 2, maxHalf = H * 0.46;
    const playX = (now / totalSec) * W;
    const step = 2;
    for (let x = 0; x < W; x += step) {
      const sec = (x / W) * totalSec;
      const amp = sampleWave(wave, sec);
      if (amp < 0) continue;
      const half = Math.max(0.6, amp * maxHalf);
      ctx.fillStyle = x <= playX ? colors.accent : colors.text;
      ctx.globalAlpha = x <= playX ? 0.85 : 0.14;
      ctx.fillRect(x, cy - half, 1.2, half * 2);
    }
    ctx.globalAlpha = 1;
    // marker
    ctx.fillStyle = colors.accentGlow;
    ctx.fillRect(playX - 0.75, 0, 1.5, H);
    ctx.beginPath();
    ctx.arc(playX, 0, 2.4, 0, Math.PI * 2);
    ctx.fill();
  }, [wave, now, totalSec, colors]);
  return <canvas ref={ref} style={{ display: "block", width: W, height: H, touchAction: "none" }}/>;
}

/* ============================================================
   Player composition
   ============================================================ */
function WaveformPlayer({ tweaks }) {
  const { demoSpeed, totalMinutes, windowSec, progressStyle, edgeFade,
          showBreathHint, showDragHint } = tweaks;
  const colors = useThemeColors();
  const totalSec = totalMinutes * 60;

  const wave = React.useMemo(() => buildWave(totalSec), [totalSec]);

  const [now, setNow] = React.useState(() => Math.round(0.22 * totalSec));
  const [playing, setPlaying] = React.useState(true);
  const [completed, setCompleted] = React.useState(false);
  const [dragging, setDragging] = React.useState(false);

  // clamp when total changes
  React.useEffect(() => { setNow((n) => Math.min(n, totalSec)); }, [totalSec]);

  // playback ticker
  React.useEffect(() => {
    if (!playing || completed || dragging) return;
    let raf, last = performance.now();
    const loop = (t) => {
      const dt = (t - last) / 1000; last = t;
      setNow((n) => {
        const nx = n + dt * demoSpeed;
        if (nx >= totalSec) { setCompleted(true); setPlaying(false); return totalSec; }
        return nx;
      });
      raf = requestAnimationFrame(loop);
    };
    raf = requestAnimationFrame(loop);
    return () => cancelAnimationFrame(raf);
  }, [playing, completed, dragging, demoSpeed, totalSec]);

  // ----- drag-scrub on the wave window -----
  const dragRef = React.useRef(null);
  const wrapRef = React.useRef(null);

  const beginDrag = (clientX, pxPerSec) => {
    dragRef.current = { startX: clientX, startNow: now, pxPerSec, wasPlaying: playing && !completed };
    setDragging(true);
    setPlaying(false);
  };
  const moveDrag = (clientX) => {
    const d = dragRef.current; if (!d) return;
    const dx = clientX - d.startX;
    let nx = d.startNow - dx / d.pxPerSec;
    nx = Math.max(0, Math.min(totalSec, nx));
    setNow(nx);
    if (nx < totalSec) setCompleted(false);
  };
  const endDrag = () => {
    const d = dragRef.current; if (!d) return;
    const resume = d.wasPlaying && now < totalSec;
    dragRef.current = null;
    setDragging(false);
    if (resume) setPlaying(true);
  };

  const onWavePointerDown = (e) => {
    if (e.target.closest("button") || e.target.closest("[data-no-scrub]")) return;
    const rect = wrapRef.current.getBoundingClientRect();
    const pxPerSec = rect.width / windowSec;
    e.currentTarget.setPointerCapture?.(e.pointerId);
    beginDrag(e.clientX, pxPerSec);
  };
  const onWavePointerMove = (e) => { if (dragRef.current) moveDrag(e.clientX); };
  const onWavePointerUp = (e) => {
    if (!dragRef.current) return;
    try { e.currentTarget.releasePointerCapture?.(e.pointerId); } catch (_) {}
    endDrag();
  };

  // mini-overview scrub (absolute seek)
  const miniRef = React.useRef(null);
  const onMiniDown = (e) => {
    e.stopPropagation();
    const seek = (clientX) => {
      const r = miniRef.current.getBoundingClientRect();
      const p = Math.max(0, Math.min(1, (clientX - r.left) / r.width));
      setNow(p * totalSec); setCompleted(p >= 1 ? true : false);
    };
    dragRef.current = { mini: true, wasPlaying: playing && !completed };
    setDragging(true); setPlaying(false);
    seek(e.clientX);
    e.currentTarget.setPointerCapture?.(e.pointerId);
    miniRef.current._seek = seek;
  };
  const onMiniMove = (e) => { if (dragRef.current?.mini) miniRef.current._seek(e.clientX); };
  const onMiniUp = (e) => {
    if (!dragRef.current?.mini) return;
    const resume = dragRef.current.wasPlaying && now < totalSec;
    dragRef.current = null; setDragging(false);
    try { e.currentTarget.releasePointerCapture?.(e.pointerId); } catch (_) {}
    if (resume) setPlaying(true);
  };

  const remaining = totalSec - now;
  const progress = now / totalSec;

  const reset = () => { setNow(Math.round(0.22 * totalSec)); setPlaying(true); setCompleted(false); };

  return (
    <div style={{
      width: SHELL_W, height: SHELL_H, position: "relative", overflow: "hidden",
      borderRadius: 48,
      background: "radial-gradient(ellipse 90% 70% at 50% 28%, #3a201a 0%, #2a1610 38%, #190c08 72%, #110705 100%)",
      fontFamily: "var(--sm-font-ui)", color: "var(--sm-text)", isolation: "isolate",
      boxShadow: "0 40px 90px -30px rgba(0,0,0,0.7), 0 0 0 1px rgba(0,0,0,0.05)",
      userSelect: "none", WebkitUserSelect: "none"
    }}>
      <StatusBar/>
      <CloseBtn onClick={reset}/>

      {/* Title */}
      <div style={{
        position: "absolute", top: 132, left: 0, right: 0, padding: "0 36px",
        textAlign: "center", zIndex: 12
      }}>
        <div style={{
          fontFamily: "var(--sm-font-display)", fontStyle: "italic", fontWeight: 400,
          fontSize: 18, lineHeight: 1.2, color: "var(--sm-accent-text)", marginBottom: 10
        }}>{TRACK.artist}</div>
        <div style={{
          fontFamily: "var(--sm-font-display)", fontWeight: 400, fontSize: 33,
          lineHeight: 1.14, color: "var(--sm-text)", letterSpacing: "-0.015em",
          textWrap: "balance"
        }}>{TRACK.title}</div>
      </div>

      {/* Wave window — vertically centered band */}
      <div ref={wrapRef}
        onPointerDown={onWavePointerDown}
        onPointerMove={onWavePointerMove}
        onPointerUp={onWavePointerUp}
        onPointerCancel={onWavePointerUp}
        style={{
          position: "absolute", left: 0, right: 0, top: 366,
          zIndex: 8, touchAction: "none"
        }}>
        <WaveWindow wave={wave} totalSec={totalSec} now={now} windowSec={windowSec}
          colors={colors} edgeFade={edgeFade} dragging={dragging}/>

        {/* center "now" marker — triangle + pulse dot above the band */}
        <div style={{
          position: "absolute", left: "50%", top: -2, transform: "translateX(-50%)",
          width: 0, height: 0, borderLeft: "5px solid transparent", borderRight: "5px solid transparent",
          borderTop: "6px solid var(--sm-accent-glow)", zIndex: 9, pointerEvents: "none"
        }}/>
        <div style={{
          position: "absolute", left: "50%", bottom: -3, transform: "translateX(-50%)",
          width: 7, height: 7, borderRadius: "50%", background: "var(--sm-accent-glow)",
          zIndex: 9, pointerEvents: "none",
          animation: (!dragging && playing) ? "nowPulse 1.8s ease-out infinite" : "none"
        }}/>

        {/* drag hint */}
        {showDragHint && !dragging && (
          <div style={{
            position: "absolute", left: 0, right: 0, bottom: -30, textAlign: "center",
            fontSize: 10.5, letterSpacing: "0.16em", textTransform: "uppercase",
            color: "var(--sm-text-3)", pointerEvents: "none",
            display: "flex", alignItems: "center", justifyContent: "center", gap: 8
          }}>
            <svg width="34" height="8" viewBox="0 0 34 8" fill="none">
              <path d="M6 4 H28 M6 4 L9 1.5 M6 4 L9 6.5 M28 4 L25 1.5 M28 4 L25 6.5"
                stroke="var(--sm-text-3)" strokeWidth="1" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
            ziehen zum spulen
          </div>
        )}
      </div>

      {/* breath hint at the very start */}
      {showBreathHint && !dragging && progress < 0.04 && (
        <div style={{
          position: "absolute", left: 0, right: 0, top: 300, textAlign: "center",
          fontFamily: "var(--sm-font-display)", fontStyle: "italic", fontSize: 15,
          color: "var(--sm-accent-text)", opacity: 0.72, zIndex: 12, pointerEvents: "none"
        }}>atme tief ein …</div>
      )}

      {/* Central remaining time */}
      <div style={{
        position: "absolute", left: 0, right: 0, top: 600, textAlign: "center", zIndex: 12
      }}>
        {dragging ? (
          <div style={{
            fontFamily: "var(--sm-font-display)", fontWeight: 400, fontSize: 30,
            color: "var(--sm-text)", fontVariantNumeric: "tabular-nums", lineHeight: 1
          }}>
            {fmt(now)} <span style={{ color: "var(--sm-text-3)", fontSize: 18 }}>/ {fmt(totalSec)}</span>
          </div>
        ) : (
          <div style={{
            fontSize: 12.5, letterSpacing: "0.22em", textTransform: "uppercase",
            color: "var(--sm-text-3)", fontVariantNumeric: "tabular-nums"
          }}>
            {completed ? "Beendet" : !playing ? "Pausiert" : <>Noch <span style={{ color: "var(--sm-accent-text)" }}>{fmt(remaining)}</span></>}
          </div>
        )}
      </div>

      {/* Progress indicator (Tweak) */}
      {progressStyle === "mini" && (
        <div ref={miniRef} data-no-scrub
          onPointerDown={onMiniDown} onPointerMove={onMiniMove}
          onPointerUp={onMiniUp} onPointerCancel={onMiniUp}
          style={{
            position: "absolute", left: "50%", top: 650, transform: "translateX(-50%)",
            zIndex: 12, cursor: "pointer", touchAction: "none", padding: "6px 0"
          }}>
          <MiniOverview wave={wave} totalSec={totalSec} now={now} colors={colors}/>
        </div>
      )}
      {progressStyle === "bar" && (
        <div data-no-scrub style={{
          position: "absolute", left: 36, right: 36, top: 666, zIndex: 12,
          height: 3, borderRadius: 3, background: "rgba(235,226,214,0.10)", overflow: "hidden"
        }}>
          <div style={{
            width: `${progress * 100}%`, height: "100%", borderRadius: 3,
            background: "var(--sm-accent)"
          }}/>
        </div>
      )}

      {/* Play / Pause */}
      <div style={{
        position: "absolute", left: "50%", bottom: 76, transform: "translateX(-50%)", zIndex: 15
      }}>
        <PlayPause playing={playing && !completed} onToggle={() => {
          if (completed) { reset(); return; }
          setPlaying((p) => !p);
        }}/>
      </div>
    </div>
  );
}

/* ============================================================
   Mount + Tweaks
   ============================================================ */
function App() {
  const [t, setTweak] = useTweaks(TWEAK_DEFAULTS);
  return (
    <div style={{
      minHeight: "100vh", width: "100%", display: "flex",
      alignItems: "center", justifyContent: "center", padding: 40, position: "relative"
    }}>
      <div style={{
        position: "fixed", inset: 0,
        background: "radial-gradient(ellipse at 50% 40%, #1c100b 0%, #0a0604 72%)",
        pointerEvents: "none", zIndex: 0
      }}/>
      <div style={{ position: "relative", zIndex: 1 }}>
        <WaveformPlayer tweaks={t}/>
        <div style={{
          marginTop: 22, textAlign: "center", color: "#9c8f80", fontSize: 11,
          letterSpacing: "0.22em", textTransform: "uppercase"
        }}>Waveform Player · Tonkopf · Prototyp</div>
        <div style={{
          marginTop: 7, textAlign: "center", color: "#6b5f55", fontSize: 11,
          fontFamily: "var(--sm-font-display)", fontStyle: "italic"
        }}>Welle greifen und ziehen zum Spulen</div>
      </div>

      <TweaksPanel title="Tweaks">
        <TweakSection label="Wiedergabe">
          <TweakSlider label="Demo-Tempo" value={t.demoSpeed} min={1} max={30} step={1} unit="×"
            onChange={(v) => setTweak("demoSpeed", v)}/>
          <TweakSlider label="Gesamtlänge" value={t.totalMinutes} min={10} max={40} step={1} unit=" min"
            onChange={(v) => setTweak("totalMinutes", v)}/>
        </TweakSection>
        <TweakSection label="Fenster">
          <TweakSlider label="Sichtbar (gesamt)" value={t.windowSec} min={20} max={120} step={5} unit=" s"
            onChange={(v) => setTweak("windowSec", v)}/>
          <TweakToggle label="Kanten ausblenden" value={t.edgeFade}
            onChange={(v) => setTweak("edgeFade", v)}/>
        </TweakSection>
        <TweakSection label="Fortschritt">
          <TweakRadio label="Stil" options={["mini", "bar", "keiner"]}
            value={t.progressStyle} onChange={(v) => setTweak("progressStyle", v)}/>
        </TweakSection>
        <TweakSection label="Hinweise">
          <TweakToggle label="Spul-Hinweis" value={t.showDragHint}
            onChange={(v) => setTweak("showDragHint", v)}/>
          <TweakToggle label="Atem-Hinweis (Start)" value={t.showBreathHint}
            onChange={(v) => setTweak("showBreathHint", v)}/>
        </TweakSection>
      </TweaksPanel>
    </div>
  );
}

ReactDOM.createRoot(document.getElementById("root")).render(<App/>);
