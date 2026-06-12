/* Still Moment — Trim-Editor
   Touch-robuste Bedienung der drei Punkte + präzises Zuschneiden an den Rändern.

   ENTKOPPLUNG (Touch):
     • Abspielposition (Sage) in eigener Spur oben + obere Hälfte der Wellenform.
     • Anfang/Ende (Kupfer) in der unteren Hälfte; immer nur EINE aktive Marke,
       die bei Überlappung den Touch gewinnt. Treffer rein geometrisch.

   PRÄZISION AN DEN RÄNDERN (langer Datei):
     • Zoom/Detail: Tippen auf Anfang/Ende rahmt die Marke in einem Fenster (ZS) →
       jede Sekunde bekommt viel mehr Platz. Window-Mapping in der ganzen Spur.
     • Minimap (Gesamtdatei) zeigt das Fenster, tippen = verschieben.
     • Schnell-Vorschläge rasten auf erkannte Intro-/Ausklang-Kanten ein.
     • ±1s für die exakte Sekunde. */

const { useState: useS, useRef: useR, useEffect: useE, useCallback: useC } = React;
const { StatusBar: SB } = window.SM;
const { useTweaks, TweaksPanel, TweakSection, TweakRadio } = window;

const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "darstellung": "Wellenform"
}/*EDITMODE-END*/;
const VARIANT = { "Wellenform": "wave", "Marker": "markers", "Slider": "slider" };

const TOTAL = 1145;            // 19:05
const N = 220;
const MINGAP = 25;             // kürzest hörbarer Bereich (s)
const GRAB = 22;               // px: so nah am Griff = direkter Griff
const SPLIT = 0.45;            // y-Grenze: oben Abspielposition, unten Marken

/* Zoom-Fensterbreite (s) — skaliert mit der Dateilänge, gedeckelt */
const ZS = Math.min(TOTAL, Math.max(120, Math.round(TOTAL * 0.18)));

/* Sage = Abspielposition, Kupfer = Marken */
const SAGE = "#8aa896";
const SAGE_HI = "#a7c2b1";

const WAVE = (() => {
  const a = []; let s = 987654321;
  const rnd = () => { s = (s * 1664525 + 1013904223) >>> 0; return s / 4294967296; };
  for (let i = 0; i < N; i++) {
    const sec = (i / N) * TOTAL;
    let amp;
    if (sec < 88) amp = 0.5 + 0.4 * Math.abs(Math.sin(i * 0.85)) + 0.12 * rnd();
    else if (sec > 1108) amp = 0.46 + 0.42 * rnd();
    else amp = rnd() < 0.2 ? 0.22 + 0.45 * rnd() : 0.05 + 0.07 * rnd();
    a.push(Math.min(1, amp));
  }
  return a;
})();

// Beim Import erkannte Kanten (Intro-Ende / Ausklang-Beginn)
const MARKERS = [90, 1105];

function fmt(sec) {
  sec = Math.max(0, Math.round(sec));
  const m = Math.floor(sec / 60), s = sec % 60;
  return m + ":" + String(s).padStart(2, "0");
}
const clamp = (v, lo, hi) => Math.max(lo, Math.min(hi, v));

/* Fenster um eine Marke rahmen (Marke ~25% vom nahen Rand) */
function frameWindow(mark, which) {
  if (TOTAL <= ZS) return [0, TOTAL];
  let lo, hi;
  if (which === "start") { lo = clamp(mark - ZS * 0.25, 0, TOTAL - ZS); hi = lo + ZS; }
  else { hi = clamp(mark + ZS * 0.25, ZS, TOTAL); lo = hi - ZS; }
  return [lo, hi];
}
function panWindow(center) {
  if (TOTAL <= ZS) return [0, TOTAL];
  const lo = clamp(center - ZS / 2, 0, TOTAL - ZS);
  return [lo, lo + ZS];
}

/* ---------- Playhead-/Vorschau-Engine ---------- */
function usePlayhead(initial = 0) {
  const [head, setHead] = useS(initial);
  const [playing, setPlaying] = useS(false);
  const [previewing, setPreviewing] = useS(false);
  const raf = useR(0);
  const stop = () => { cancelAnimationFrame(raf.current); raf.current = 0; };
  const begin = useC((from, ms) => {
    stop();
    const preview = !!ms;
    setPlaying(!preview); setPreviewing(preview); setHead(from);
    const t0 = performance.now();
    const loop = (now) => {
      const h = from + (now - t0) / 1000;
      if (h >= TOTAL || (ms && now - t0 >= ms)) { setHead(ms ? from : Math.min(h, TOTAL)); setPlaying(false); setPreviewing(false); raf.current = 0; return; }
      setHead(h); raf.current = requestAnimationFrame(loop);
    };
    raf.current = requestAnimationFrame(loop);
  }, []);
  const pause = useC(() => { stop(); setPlaying(false); setPreviewing(false); }, []);
  useE(() => stop, []);
  return { head, setHead, playing, previewing, begin, pause };
}

/* ---------- Icons ---------- */
const IcPlay = <svg viewBox="0 0 24 24" fill="currentColor"><path d="M8 5 V19 L19 12 Z"/></svg>;
const IcPause = <svg viewBox="0 0 24 24" fill="currentColor"><rect x="6" y="5" width="4" height="14" rx="1"/><rect x="14" y="5" width="4" height="14" rx="1"/></svg>;
const IcChevL = <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M15 6 L9 12 L15 18"/></svg>;
const IcChevR = <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M9 6 L15 12 L9 18"/></svg>;
const IcScissor = <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"><circle cx="6" cy="7" r="2.4"/><circle cx="6" cy="17" r="2.4"/><path d="M8 8.5 L20 16"/><path d="M8 15.5 L20 8"/></svg>;
const IcZoomOut = <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round"><circle cx="11" cy="11" r="6"/><path d="M8 11 H14"/><path d="M20 20 L16 16"/></svg>;

/* Zeit-Blase */
function Bubble({ value, color = "var(--sm-accent-glow)", text = "#2a1208" }) {
  return (
    <div style={{
      position: "absolute", top: -32, left: "50%", transform: "translateX(-50%)",
      background: color, color: text, fontFamily: "var(--sm-font-display)",
      fontSize: 15, fontWeight: 500, padding: "3px 9px", borderRadius: 8,
      whiteSpace: "nowrap", fontFeatureSettings: '"tnum"', boxShadow: "0 4px 12px rgba(0,0,0,0.4)",
      pointerEvents: "none",
    }}>{value}</div>
  );
}

/* ============================================================
   Minimap — Gesamtdatei mit Fensterrahmen, tippen verschiebt
   ============================================================ */
function MiniMap({ start, end, head, winLo, winHi, onPan }) {
  const ref = useR(null);
  const p = (s) => (s / TOTAL) * 100;
  const drag = useR(false);
  const at = (clientX) => { const r = ref.current.getBoundingClientRect(); return clamp((clientX - r.left) / r.width, 0, 1) * TOTAL; };
  useE(() => {
    const move = (e) => { if (drag.current) onPan(at(e.clientX)); };
    const up = () => { drag.current = false; };
    window.addEventListener("pointermove", move);
    window.addEventListener("pointerup", up);
    return () => { window.removeEventListener("pointermove", move); window.removeEventListener("pointerup", up); };
  }, [onPan]);
  return (
    <div ref={ref}
      onPointerDown={(e) => { e.preventDefault(); drag.current = true; onPan(at(e.clientX)); }}
      style={{ position: "relative", height: 26, borderRadius: 8, background: "rgba(235,226,214,0.05)", border: "1px solid var(--sm-card-line)", cursor: "pointer", overflow: "hidden", touchAction: "none" }}>
      <div style={{ position: "absolute", top: 0, bottom: 0, left: p(start) + "%", width: (p(end) - p(start)) + "%", background: "rgba(196,122,94,0.20)", pointerEvents: "none" }}/>
      <div style={{ position: "absolute", top: 2, bottom: 2, left: p(start) + "%", width: 2, marginLeft: -1, background: "var(--sm-accent-glow)", pointerEvents: "none" }}/>
      <div style={{ position: "absolute", top: 2, bottom: 2, left: p(end) + "%", width: 2, marginLeft: -1, background: "var(--sm-accent-glow)", pointerEvents: "none" }}/>
      {head != null && <div style={{ position: "absolute", top: 0, bottom: 0, left: p(head) + "%", width: 2, marginLeft: -1, background: SAGE_HI, pointerEvents: "none" }}/>}
      <div style={{ position: "absolute", top: 1, bottom: 1, left: p(winLo) + "%", width: (p(winHi) - p(winLo)) + "%", border: "1.5px solid " + SAGE_HI, borderRadius: 6, background: "rgba(138,168,150,0.12)", pointerEvents: "none" }}/>
    </div>
  );
}

/* ============================================================
   Trim-Spur — Window-Mapping (winLo..winHi statt 0..TOTAL)
   ============================================================ */
function TrimTrack({
  start, end, head, active, onChangeTrim, onSeek, onScrub, onScrubEnd, onMarker, onPickMark,
  winLo = 0, winHi = TOTAL, height = 104, interactive = true, variant = "wave",
}) {
  const wrapRef = useR(null);
  const drag = useR(null);
  const [dragK, setDragK] = useS(null);
  const live = useR({});
  live.current = { start, end, head, active, winLo, winHi };

  const PHLANE = interactive ? 34 : 0;
  const span = winHi - winLo;
  const pctW = (sec) => ((sec - winLo) / span) * 100;
  const clampPct = (sec) => clamp(pctW(sec), 0, 100);
  const inWin = (sec) => sec >= winLo - 0.5 && sec <= winHi + 0.5;

  const lspan = () => (live.current.winHi - live.current.winLo);
  const secAt = (lx, w, offset = 0) => clamp((lx + offset) / w, 0, 1) * lspan() + live.current.winLo;
  const pxOf = (sec, w) => ((sec - live.current.winLo) / lspan()) * w;
  const geom = (clientX) => { const r = wrapRef.current.getBoundingClientRect(); return { r, lx: clientX - r.left, w: r.width }; };

  useE(() => {
    if (!interactive) return;
    const move = (e) => {
      const d = drag.current; if (!d) return;
      const { r, w } = geom(e.clientX);
      const t = secAt(e.clientX - r.left, w, d.offset);
      const { start: st, end: en } = live.current;
      if (d.kind === "head") onSeek(t);
      else if (d.kind === "start") onChangeTrim(Math.min(t, en - MINGAP), en, "start");
      else onChangeTrim(st, Math.max(t, st + MINGAP), "end");
      onScrub && onScrub(t);
    };
    const up = () => { const d = drag.current; if (d) { const k = d.kind; drag.current = null; setDragK(null); onScrubEnd && onScrubEnd(k); } };
    window.addEventListener("pointermove", move);
    window.addEventListener("pointerup", up);
    window.addEventListener("pointercancel", up);
    return () => { window.removeEventListener("pointermove", move); window.removeEventListener("pointerup", up); window.removeEventListener("pointercancel", up); };
  }, [interactive, onChangeTrim, onSeek, onScrub, onScrubEnd]);

  const downHead = (e) => {
    e.preventDefault();
    const { lx, w } = geom(e.clientX);
    const hpx = pxOf(live.current.head, w);
    const offset = Math.abs(lx - hpx) <= GRAB ? hpx - lx : 0;
    drag.current = { kind: "head", offset };
    setDragK("head");
    const t = secAt(lx, w, offset);
    onSeek(t); onScrub && onScrub(t);
  };
  const downBody = (e) => {
    e.preventDefault();
    const { lx, w } = geom(e.clientX);
    const { start: st, end: en, active: act } = live.current;
    const spx = pxOf(st, w), epx = pxOf(en, w);
    const dS = Math.abs(lx - spx), dE = Math.abs(lx - epx);
    let kind, offset;
    if (dS <= GRAB && dE <= GRAB) { kind = act; offset = (act === "start" ? spx : epx) - lx; }
    else if (dS <= GRAB && dS <= dE) { kind = "start"; offset = spx - lx; }
    else if (dE <= GRAB) { kind = "end"; offset = epx - lx; }
    else { kind = act; offset = 0; }
    drag.current = { kind, offset };
    setDragK(kind);
    const t = secAt(lx, w, offset);
    if (kind === "start") onChangeTrim(Math.min(t, en - MINGAP), en, "start");
    else onChangeTrim(st, Math.max(t, st + MINGAP), "end");
    onScrub && onScrub(t);
  };
  const downTrack = (e) => {
    const zr = e.currentTarget.getBoundingClientRect();
    if ((e.clientY - zr.top) < zr.height * SPLIT) downHead(e); else downBody(e);
  };

  const headEl = head != null;
  const headVisible = headEl && inWin(head);
  const stepPct = ((TOTAL / N) / span) * 100;
  const barW = Math.max(0.18, stepPct * 0.62);

  /* Off-window-Indikator für eine Marke */
  const edgeChip = (k, v) => {
    const left = v < winLo;
    return (
      <button key={k + "-edge"} onClick={() => onPickMark && onPickMark(k)} onPointerDown={(e) => e.stopPropagation()}
        style={{
          position: "absolute", top: "50%", transform: "translateY(-50%)", [left ? "left" : "right"]: 4,
          display: "inline-flex", alignItems: "center", gap: 4, zIndex: 6, cursor: "pointer",
          background: "var(--sm-accent-dim)", border: "1px solid rgba(214,138,110,0.4)", borderRadius: 999, whiteSpace: "nowrap",
          color: "var(--sm-accent-text)", fontFamily: "var(--sm-font-ui)", fontSize: 12, padding: "4px 9px", fontFeatureSettings: '"tnum"',
        }}>
        {left ? "‹" : ""}{k === "start" ? "Anfang" : "Ende"} {fmt(v)}{left ? "" : "›"}
      </button>
    );
  };

  return (
    <div ref={wrapRef} style={{ position: "relative", width: "100%", touchAction: "none", userSelect: "none" }}>

      {/* Spur 1: Abspielposition (Sage) */}
      {interactive && (
        <div onPointerDown={downHead} style={{ position: "relative", height: PHLANE, cursor: "ew-resize" }}>
          <span style={{ position: "absolute", left: 0, top: 1, fontSize: 10, letterSpacing: "0.1em", textTransform: "uppercase", color: SAGE, opacity: 0.7, fontWeight: 600, pointerEvents: "none" }}>Abspielposition</span>
          <div style={{ position: "absolute", left: 0, right: 0, bottom: 2, height: 2, borderRadius: 2, background: "rgba(138,168,150,0.18)", pointerEvents: "none" }}/>
          {headVisible && (
            <div style={{ position: "absolute", left: clampPct(head) + "%", bottom: 0, transform: "translateX(-50%)", display: "flex", flexDirection: "column", alignItems: "center", pointerEvents: "none" }}>
              {dragK === "head" && <Bubble value={fmt(head)} color={SAGE_HI} text="#13251c"/>}
              <div style={{ width: 32, height: 20, borderRadius: 7, background: "linear-gradient(180deg," + SAGE_HI + "," + SAGE + ")", boxShadow: "0 2px 7px rgba(0,0,0,0.45), inset 0 0 0 1px rgba(255,255,255,0.2)", display: "flex", alignItems: "center", justifyContent: "center", gap: 3 }}>
                <span style={{ width: 2, height: 9, borderRadius: 2, background: "rgba(19,37,28,0.55)" }}/>
                <span style={{ width: 2, height: 9, borderRadius: 2, background: "rgba(19,37,28,0.55)" }}/>
              </div>
              <div style={{ width: 0, height: 0, marginTop: -1, borderLeft: "5px solid transparent", borderRight: "5px solid transparent", borderTop: "6px solid " + SAGE }}/>
            </div>
          )}
        </div>
      )}

      {/* Spur 2: Wellenform · oben Abspielposition / unten Marken */}
      <div onPointerDown={interactive ? downTrack : undefined} style={{ position: "relative", height, cursor: interactive ? "pointer" : "default" }}>

        {/* Region-Highlight (geklammert auf Fenster) */}
        {variant === "wave" && (
          <div style={{ position: "absolute", top: -4, bottom: -4, left: clampPct(start) + "%", width: (clampPct(end) - clampPct(start)) + "%", background: "rgba(196,122,94,0.12)", borderLeft: start >= winLo ? "1px solid rgba(214,138,110,0.35)" : "none", borderRight: end <= winHi ? "1px solid rgba(214,138,110,0.35)" : "none", borderRadius: 4, pointerEvents: "none" }}/>
        )}

        {variant === "wave" ? (
          <div style={{ position: "absolute", inset: 0, pointerEvents: "none" }}>
            {WAVE.map((amp, i) => {
              const sec = (i / N) * TOTAL;
              if (!inWin(sec)) return null;
              const inside = sec >= start && sec <= end;
              return <div key={i} style={{ position: "absolute", left: pctW(sec) + "%", top: "50%", transform: "translate(-50%,-50%)", width: barW + "%", height: Math.max(2, amp * height) + "px", borderRadius: 2, background: inside ? "var(--sm-accent)" : "rgba(168,154,140,0.18)" }}/>;
            })}
          </div>
        ) : (
          <div style={{ position: "absolute", left: 0, right: 0, top: "50%", transform: "translateY(-50%)", pointerEvents: "none" }}>
            <div style={{ position: "relative", height: 6, borderRadius: 999, background: "rgba(168,154,140,0.18)" }}>
              <div style={{ position: "absolute", top: 0, bottom: 0, left: clampPct(start) + "%", width: (clampPct(end) - clampPct(start)) + "%", borderRadius: 999, background: "var(--sm-accent)" }}/>
            </div>
            {variant === "markers" && MARKERS.filter(inWin).map((m, i) => (
              <button key={i} onPointerDown={(e) => e.stopPropagation()} onClick={() => onMarker && onMarker(m)} title={"Erkannte Kante · " + fmt(m)}
                style={{ position: "absolute", top: "50%", left: pctW(m) + "%", transform: "translate(-50%,-50%)", width: 22, height: 34, border: "none", background: "transparent", cursor: interactive ? "pointer" : "default", padding: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 2, zIndex: 5 }}>
                <span style={{ width: 2, height: 20, borderRadius: 2, background: "var(--sm-accent-text)", opacity: 0.75 }}/>
                <span style={{ width: 5, height: 5, borderRadius: "50%", background: "var(--sm-accent-text)" }}/>
              </button>
            ))}
          </div>
        )}

        {/* Halb/Halb-Hinweis */}
        {interactive && (
          <>
            <div style={{ position: "absolute", top: 0, left: 0, right: 0, height: (SPLIT * 100) + "%", background: "linear-gradient(180deg, rgba(138,168,150,0.10), rgba(138,168,150,0))", pointerEvents: "none", zIndex: 1 }}/>
            <div style={{ position: "absolute", top: (SPLIT * 100) + "%", left: 0, right: 0, height: 1, background: "rgba(235,226,214,0.08)", pointerEvents: "none", zIndex: 1 }}/>
          </>
        )}

        {/* Playhead-Linie */}
        {headVisible && (
          <div style={{ position: "absolute", top: -6, bottom: -6, left: clampPct(head) + "%", width: 2, marginLeft: -1, background: SAGE_HI, boxShadow: "0 0 8px rgba(138,168,150,0.7)", pointerEvents: "none", zIndex: 2 }}/>
        )}

        {/* Marken — sichtbar im Fenster, sonst Edge-Chip */}
        {[["start", start], ["end", end]].map(([k, v]) => {
          if (interactive && !inWin(v)) return edgeChip(k, v);
          if (!interactive && !inWin(v)) return null;
          const isAct = interactive && active === k;
          const showBubble = interactive && dragK === k;
          const knobShadow = isAct
            ? "0 2px 10px rgba(0,0,0,0.5), inset 0 0 0 1px rgba(255,255,255,0.28), 0 0 0 2px rgba(214,138,110,0.35)"
            : "0 2px 8px rgba(0,0,0,0.45), inset 0 0 0 1px rgba(255,255,255,0.16)";
          return (
            <div key={k} style={{ position: "absolute", top: -12, bottom: -12, left: pctW(v) + "%", transform: "translateX(-50%)", display: "flex", alignItems: "center", justifyContent: "center", pointerEvents: "none", zIndex: isAct ? 4 : 3 }}>
              {showBubble && <Bubble value={fmt(v)}/>}
              {variant === "wave" ? (
                <>
                  <div style={{ position: "absolute", top: 0, bottom: 0, left: "50%", transform: "translateX(-50%)", width: isAct ? 4 : 3, borderRadius: 3, background: "linear-gradient(180deg, var(--sm-accent-glow), var(--sm-accent-soft))", opacity: isAct ? 1 : 0.7, boxShadow: isAct ? "0 0 0 1px rgba(214,138,110,0.4)" : "none", transition: "width 0.12s ease" }}/>
                  <div style={{ position: "absolute", left: "50%", top: "74%", transform: "translate(-50%,-50%)", width: isAct ? 20 : 16, height: isAct ? 44 : 38, borderRadius: 8, background: "linear-gradient(180deg, var(--sm-accent-glow), var(--sm-accent-soft))", boxShadow: knobShadow, display: "flex", alignItems: "center", justifyContent: "center", gap: 3, transition: "width 0.12s ease, height 0.12s ease", animation: isAct && !dragK ? "trimHandlePulse 1.8s ease-out infinite" : "none" }}>
                    <span style={{ width: 2, height: 13, borderRadius: 2, background: "rgba(42,18,8,0.5)" }}/>
                    <span style={{ width: 2, height: 13, borderRadius: 2, background: "rgba(42,18,8,0.5)" }}/>
                  </div>
                </>
              ) : (
                <div style={{ width: isAct ? 9 : 7, height: 44, borderRadius: 5, background: "linear-gradient(180deg, var(--sm-accent-glow), var(--sm-accent-soft))", boxShadow: knobShadow, display: "flex", alignItems: "center", justifyContent: "center", transition: "width 0.12s ease", animation: isAct && !dragK ? "trimHandlePulse 1.8s ease-out infinite" : "none" }}>
                  <div style={{ width: 2, height: 16, borderRadius: 2, background: "rgba(42,18,8,0.5)" }}/>
                </div>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}

const metaLbl = { fontSize: 11, letterSpacing: "0.12em", textTransform: "uppercase", color: "var(--sm-text-3)", fontWeight: 500 };
const navBtn = (c) => ({ background: "none", border: "none", color: c, fontFamily: "var(--sm-font-ui)", fontSize: 15, padding: "6px 0", cursor: "pointer" });
const navTitle = { position: "absolute", left: "50%", top: "50%", transform: "translate(-50%,-50%)", fontFamily: "var(--sm-font-display)", fontSize: 17, color: "var(--sm-text)", whiteSpace: "nowrap" };

/* ============================================================
   Editor-Sheet
   ============================================================ */
function TrimSheet({ open, init, onClose, onDone, variant = "wave" }) {
  const [start, setStart] = useS(init.start);
  const [end, setEnd] = useS(init.end);
  const [active, setActive] = useS("start");
  const [win, setWin] = useS([0, TOTAL]);
  const { head, setHead, playing, previewing, begin, pause } = usePlayhead(init.start);
  const zoomed = (win[1] - win[0]) < TOTAL - 1;

  useE(() => { if (open) { setStart(init.start); setEnd(init.end); setActive("start"); setHead(init.start); setWin([0, TOTAL]); pause(); } }, [open]);

  const onChangeTrim = (s, e, which) => { setStart(s); setEnd(e); setActive(which); };
  const onSeek = (t) => { pause(); setHead(t); };

  const cur = active === "start" ? start : end;
  const setCur = (v) => active === "start" ? setStart(Math.min(v, end - MINGAP)) : setEnd(Math.max(v, start + MINGAP));

  // Marke wählen + auf die Marke heranzoomen
  const pick = (k, value) => {
    setActive(k); setHead(value); setWin(frameWindow(value, k));
  };

  const nudge = (d) => {
    const v = clamp(cur + d, 0, TOTAL); setCur(v); setHead(v); begin(v, 1400);
    if (zoomed) setWin(frameWindow(v, active));
  };
  const snapStart = () => { const v = MARKERS[0]; setStart(Math.min(v, end - MINGAP)); setActive("start"); setHead(v); begin(v, 1800); setWin(frameWindow(v, "start")); };
  const snapEnd = () => { const v = MARKERS[1]; setEnd(Math.max(v, start + MINGAP)); setActive("end"); setHead(v); begin(v, 1800); setWin(frameWindow(v, "end")); };

  const onScrubEnd = (kind) => {
    if (kind === "head") return;
    const point = kind === "start" ? start : end;
    setHead(point); begin(point, 2000);
    if (zoomed) setWin(frameWindow(point, kind));
  };

  return (
    <div style={{
      position: "absolute", inset: 0, zIndex: 20,
      transform: open ? "translateY(0)" : "translateY(100%)",
      transition: "transform 0.4s cubic-bezier(0.32,0.72,0,1)",
      background: "radial-gradient(ellipse 90% 70% at 50% 20%, #3a201a 0%, #2a1610 40%, #190c08 75%, #110705 100%)",
      display: "flex", flexDirection: "column",
    }}>
      <SB/>
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "10px 16px 10px", height: 44, position: "relative" }}>
        <button onClick={() => { pause(); onClose(); }} className="press" style={{ ...navBtn("var(--sm-text-2)"), display: "inline-flex", alignItems: "center", paddingLeft: 0 }}>
          <span style={{ width: 22, height: 22 }}>{IcChevL}</span>
        </button>
        <div style={navTitle}>Zuschneiden</div>
        <button onClick={() => { pause(); onDone({ start: Math.round(start), end: Math.round(end) }); }} className="press" style={{ ...navBtn("var(--sm-accent-text)"), fontWeight: 500 }}>Fertig</button>
      </div>

      <div style={{ padding: "6px 24px 14px", display: "flex", flexDirection: "column", flex: 1 }}>
        <div style={{ textAlign: "center" }}>
          <div style={{ fontFamily: "var(--sm-font-display)", fontSize: 20, color: "var(--sm-text)" }}>Evening Wind Down</div>
          <div style={{ fontSize: 12.5, color: "var(--sm-text-2)", marginTop: 2 }}>Tara Goldstein · 19:05</div>
        </div>

        <div style={{ textAlign: "center", marginTop: 14 }}>
          <div style={metaLbl}>{active === "start" ? "Anfang der Wiedergabe" : "Ende der Wiedergabe"}</div>
          <div style={{ fontFamily: "var(--sm-font-display)", fontSize: 46, color: "var(--sm-accent-text)", lineHeight: 1, marginTop: 4, fontFeatureSettings: '"tnum"' }}>{fmt(cur)}</div>
          <div style={{ fontSize: 12.5, color: "var(--sm-text-2)", marginTop: 6 }}>Hörbar: {fmt(start)} – {fmt(end)} · {fmt(end - start)}</div>
        </div>

        {/* Minimap nur im Zoom */}
        {zoomed && (
          <div style={{ marginTop: 14 }}>
            <MiniMap start={start} end={end} head={head} winLo={win[0]} winHi={win[1]} onPan={(c) => setWin(panWindow(c))}/>
          </div>
        )}

        <div style={{ marginTop: 14 }}>
          <TrimTrack start={start} end={end} active={active}
            onChangeTrim={onChangeTrim} onSeek={onSeek} variant={variant}
            head={head} onMarker={(m) => { setCur(m); setHead(m); begin(m, 1400); if (zoomed) setWin(frameWindow(m, active)); }}
            onPickMark={(k) => pick(k, k === "start" ? start : end)}
            winLo={win[0]} winHi={win[1]}
            onScrub={() => {}} onScrubEnd={onScrubEnd} height={104}/>
          <div style={{ display: "flex", justifyContent: "space-between", marginTop: 10, fontSize: 11, color: "var(--sm-text-3)", fontFeatureSettings: '"tnum"' }}>
            <span>{fmt(win[0])}</span>
            <span style={{ color: (playing || previewing) ? SAGE_HI : "var(--sm-text-3)" }}>{fmt(head ?? 0)}</span>
            <span>{fmt(win[1])}</span>
          </div>
        </div>

        {/* Marken wählen — Tippen zoomt auf die Marke */}
        <div style={{ display: "flex", gap: 10, marginTop: 14 }}>
          <ReadoutCard label="Anfang" value={fmt(start)} active={active === "start"} zoom onClick={() => pick("start", start)}/>
          <ReadoutCard label="Ende" value={fmt(end)} active={active === "end"} zoom onClick={() => pick("end", end)}/>
        </div>

        {/* Zoom-Status + Schnell-Vorschläge */}
        <div style={{ display: "flex", flexWrap: "wrap", alignItems: "center", justifyContent: "center", gap: 8, marginTop: 14 }}>
          {zoomed && (
            <button onClick={() => setWin([0, TOTAL])} className="press" style={chipStyle(false)}>
              <span style={{ width: 14, height: 14, display: "inline-flex" }}>{IcZoomOut}</span> Ganze Datei
            </button>
          )}
          <button onClick={snapStart} className="press" style={chipStyle(true)}>Intro überspringen · {fmt(MARKERS[0])}</button>
          <button onClick={snapEnd} className="press" style={chipStyle(true)}>Ausklang kürzen · {fmt(MARKERS[1])}</button>
        </div>

        <div style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: 16, marginTop: 16 }}>
          <button onClick={() => nudge(-1)} className="press" style={nudgeBtn}>−1s</button>
          <button onClick={() => playing ? pause() : begin(head)} className="press" style={{
            width: 62, height: 62, borderRadius: "50%", border: "none", cursor: "pointer",
            background: "linear-gradient(180deg, var(--sm-accent-glow), var(--sm-accent-soft))", color: "#2a1208",
            boxShadow: "0 12px 30px -8px rgba(196,122,94,0.6), inset 0 0 0 1px rgba(214,138,110,0.3)",
            display: "inline-flex", alignItems: "center", justifyContent: "center",
          }}>
            <span style={{ width: 27, height: 27, marginLeft: playing ? 0 : 3 }}>{playing ? IcPause : IcPlay}</span>
          </button>
          <button onClick={() => nudge(1)} className="press" style={nudgeBtn}>+1s</button>
        </div>
        <div style={{ textAlign: "center", marginTop: 10, fontSize: 11.5, color: "var(--sm-text-3)", lineHeight: 1.5 }}>
          {zoomed ? "Detailansicht — fein ziehen, ±1s für die Sekunde" : "Anfang/Ende tippen = heranzoomen · oben ziehen = Abspielposition"}
        </div>

        <div style={{ flex: 1 }}/>
        <button onClick={() => { setStart(0); setEnd(TOTAL); setActive("start"); setHead(0); setWin([0, TOTAL]); pause(); }} className="press" style={{
          alignSelf: "center", background: "none", border: "none", color: "var(--sm-text-2)",
          fontFamily: "var(--sm-font-ui)", fontSize: 13, cursor: "pointer", padding: "6px 0 2px",
        }}>Ganze Datei verwenden</button>
      </div>
    </div>
  );
}

function chipStyle(smart) {
  return {
    display: "inline-flex", alignItems: "center", gap: 6, padding: "7px 12px", borderRadius: 999,
    border: "1px solid " + (smart ? "rgba(214,138,110,0.35)" : "var(--sm-card-line)"),
    background: smart ? "var(--sm-accent-dim)" : "rgba(235,226,214,0.05)",
    color: smart ? "var(--sm-accent-text)" : "var(--sm-text)",
    fontFamily: "var(--sm-font-ui)", fontSize: 12.5, cursor: "pointer", fontFeatureSettings: '"tnum"',
  };
}

function ReadoutCard({ label, value, active, zoom, onClick }) {
  return (
    <button onClick={onClick} className="press" style={{
      flex: 1, textAlign: "left", background: active ? "var(--sm-accent-dim)" : "rgba(235,226,214,0.04)",
      border: "1px solid " + (active ? "rgba(214,138,110,0.4)" : "var(--sm-card-line)"),
      borderRadius: 14, padding: "9px 14px", cursor: "pointer", fontFamily: "var(--sm-font-ui)", position: "relative",
    }}>
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
        <div style={metaLbl}>{label}</div>
        {zoom && <span style={{ width: 13, height: 13, color: active ? "var(--sm-accent-text)" : "var(--sm-text-3)", display: "inline-flex" }}>{IcZoomOut}</span>}
      </div>
      <div style={{ fontFamily: "var(--sm-font-display)", fontSize: 25, color: active ? "var(--sm-accent-text)" : "var(--sm-text)", marginTop: 1, fontFeatureSettings: '"tnum"' }}>{value}</div>
    </button>
  );
}
const nudgeBtn = { minWidth: 58, height: 46, borderRadius: 999, border: "1px solid var(--sm-card-line)", background: "rgba(235,226,214,0.05)", color: "var(--sm-text)", fontFamily: "var(--sm-font-ui)", fontSize: 15, cursor: "pointer", fontFeatureSettings: '"tnum"' };

/* ============================================================
   Edit-Formular
   ============================================================ */
function App() {
  const [t, setTweak] = useTweaks(TWEAK_DEFAULTS);
  const variant = VARIANT[t.darstellung] || "wave";
  const [trim, setTrim] = useS(null);
  const [sheet, setSheet] = useS(false);
  const isTrimmed = trim != null;
  const init = trim ?? { start: 0, end: TOTAL };

  return (
    <>
    <div className="phone bg-vignette" data-screen-label="Meditation bearbeiten">
      <SB/>
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "10px 18px 12px", height: 44, position: "relative" }}>
        <button className="press" style={navBtn("var(--sm-accent-text)")}>Abbrechen</button>
        <div style={navTitle}>Meditation bearbeiten</div>
        <button className="press" style={{ ...navBtn("var(--sm-accent-text)"), fontWeight: 500 }}>Speichern</button>
      </div>

      <div style={{ padding: "8px 18px", display: "flex", flexDirection: "column", gap: 14 }}>
        <div className="card" style={{ padding: "13px 16px" }}>
          <div style={metaLbl}>Lehrer:in</div>
          <div style={{ fontFamily: "var(--sm-font-display)", fontSize: 18, color: "var(--sm-text)", marginTop: 4 }}>Tara Goldstein</div>
        </div>
        <div className="card" style={{ padding: "13px 16px" }}>
          <div style={metaLbl}>Name</div>
          <div style={{ fontFamily: "var(--sm-font-display)", fontSize: 18, color: "var(--sm-text)", marginTop: 4 }}>Evening Wind Down</div>
        </div>

        <div style={{ display: "flex", alignItems: "center", gap: 8, padding: "2px 4px", fontSize: 11.5, color: "var(--sm-text-3)" }}>
          <span>evening-wind-down.mp3 · 19:05</span>
        </div>

        <button onClick={() => setSheet(true)} className="card press" style={{
          textAlign: "left", border: "1px solid var(--sm-card-line)", cursor: "pointer",
          padding: "14px 16px", fontFamily: "var(--sm-font-ui)", background: "var(--sm-card)",
        }}>
          <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
            <div style={metaLbl}>Wiedergabe-Bereich</div>
            <span style={{ width: 18, height: 18, color: "var(--sm-text-3)" }}>{IcChevR}</span>
          </div>
          {isTrimmed ? (
            <>
              <div style={{ marginTop: 12 }}>
                <TrimTrack start={trim.start} end={trim.end} active={null} onChangeTrim={() => {}} onSeek={() => {}} head={null} interactive={false} variant={variant} height={44}/>
              </div>
              <div style={{ display: "flex", alignItems: "baseline", justifyContent: "space-between", marginTop: 12 }}>
                <div style={{ fontFamily: "var(--sm-font-display)", fontSize: 22, color: "var(--sm-accent-text)", fontFeatureSettings: '"tnum"' }}>{fmt(trim.start)} – {fmt(trim.end)}</div>
                <div style={{ fontSize: 12.5, color: "var(--sm-text-2)", fontFeatureSettings: '"tnum"' }}>{fmt(trim.end - trim.start)} hörbar</div>
              </div>
            </>
          ) : (
            <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginTop: 10 }}>
              <div style={{ fontFamily: "var(--sm-font-display)", fontSize: 19, color: "var(--sm-text)" }}>Ganze Datei · 19:05</div>
              <div style={{ display: "inline-flex", alignItems: "center", gap: 6, color: "var(--sm-accent-text)", fontSize: 13.5 }}>
                <span style={{ width: 15, height: 15 }}>{IcScissor}</span> Bereich wählen
              </div>
            </div>
          )}
        </button>

        <div style={{ fontSize: 12, color: "var(--sm-text-3)", lineHeight: 1.5, padding: "0 4px" }}>
          Überspringe Einleitung oder Schlussworte — die Wiedergabe läuft nur zwischen diesen Punkten. Die Datei selbst bleibt unverändert.
        </div>

        {isTrimmed && (
          <button onClick={() => setTrim(null)} className="press" style={{ alignSelf: "flex-start", background: "none", border: "none", color: "var(--sm-text-2)", fontFamily: "var(--sm-font-ui)", fontSize: 13, cursor: "pointer", padding: "0 4px" }}>
            Zuschnitt entfernen
          </button>
        )}
      </div>

      <TrimSheet open={sheet} init={init} variant={variant}
        onClose={() => setSheet(false)}
        onDone={(v) => { setTrim(v.start <= 1 && v.end >= TOTAL - 1 ? null : v); setSheet(false); }}/>
    </div>

    <TweaksPanel>
      <TweakSection label="Darstellung der Spur"/>
      <TweakRadio label="Stil" value={t.darstellung}
        options={["Wellenform", "Marker", "Slider"]}
        onChange={(v) => setTweak("darstellung", v)}/>
    </TweaksPanel>
    </>
  );
}

window.SM_App = App;
