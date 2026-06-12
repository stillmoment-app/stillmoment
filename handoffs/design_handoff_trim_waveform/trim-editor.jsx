/* B als vollständiger Flow:
   Edit-Formular → „Wiedergabe-Bereich" tippen → Vollbild-Editor (Sheet)
   → „Fertig" schreibt Start/Ende zurück. „Ganze Datei" setzt zurück.
   Verbesserungen ggü. Canvas-Version:
     • Zeit-Blase direkt am Griff (folgt beim Ziehen)
     • Aktiver Punkt pulsiert dezent
     • Live-Vorschau beim Loslassen / Nudgen */

const { useState: useS, useRef: useR, useEffect: useE, useCallback: useC } = React;
const { StatusBar: SB } = window.SM;

const TOTAL = 1145;            // 19:05
const N = 220;

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

function fmt(sec) {
  sec = Math.max(0, Math.round(sec));
  const m = Math.floor(sec / 60), s = sec % 60;
  return m + ":" + String(s).padStart(2, "0");
}
const clamp = (v, lo, hi) => Math.max(lo, Math.min(hi, v));

/* ---------- Playhead-/Vorschau-Engine ---------- */
function usePlayhead(initial = 0) {
  const [head, setHead] = useS(initial);
  const [playing, setPlaying] = useS(false);     // durchgehende Wiedergabe (steuert das ▶/⏸-Icon)
  const [previewing, setPreviewing] = useS(false); // kurze Vorschau (Nudge/Drag) — lässt den Button ruhig
  const raf = useR(0);
  const stop = () => { cancelAnimationFrame(raf.current); raf.current = 0; };
  // ms gesetzt → kurze Vorschau (previewing); ohne ms → durchgehend (playing)
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
const IcSound = <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round"><path d="M4 9 H7 L11 5 V19 L7 15 H4 Z"/><path d="M15 9 C16.5 10.5 16.5 13.5 15 15"/><path d="M17.5 7 C20 9.5 20 14.5 17.5 17" opacity="0.6"/></svg>;
const IcScissor = <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"><circle cx="6" cy="7" r="2.4"/><circle cx="6" cy="17" r="2.4"/><path d="M8 8.5 L20 16"/><path d="M8 15.5 L20 8"/></svg>;

/* ---------- Trim-Spur: Wellenform mit Zeit-Blase + Puls ---------- */
function TrimTrack({ start, end, onChange, head, active, onScrub, onScrubEnd, height = 104, interactive = true }) {
  const trackRef = useR(null);
  const drag = useR(null);
  const [dragK, setDragK] = useS(null);
  const live = useR({ start, end });
  live.current = { start, end };

  const xToSec = (clientX) => {
    const r = trackRef.current.getBoundingClientRect();
    const x = clamp(clientX - r.left, 0, r.width);
    return (x / r.width) * TOTAL;
  };

  useE(() => {
    if (!interactive) return;
    const move = (e) => {
      if (!drag.current) return;
      const t = xToSec(e.clientX);
      const { start: st, end: en } = live.current;
      if (drag.current === "start") onChange(Math.min(t, en - 25), en, "start");
      else onChange(st, Math.max(t, st + 25), "end");
      onScrub && onScrub(t);
    };
    const up = () => { if (drag.current) { drag.current = null; setDragK(null); onScrubEnd && onScrubEnd(); } };
    window.addEventListener("pointermove", move);
    window.addEventListener("pointerup", up);
    return () => { window.removeEventListener("pointermove", move); window.removeEventListener("pointerup", up); };
  }, [interactive, onChange, onScrub, onScrubEnd]);

  const pct = (sec) => (sec / TOTAL) * 100;

  return (
    <div ref={trackRef} style={{ position: "relative", width: "100%", height, touchAction: "none", userSelect: "none" }}>
      <div style={{
        position: "absolute", top: -4, bottom: -4, left: pct(start) + "%", width: (pct(end) - pct(start)) + "%",
        background: "rgba(196,122,94,0.12)", borderLeft: "1px solid rgba(214,138,110,0.35)", borderRight: "1px solid rgba(214,138,110,0.35)",
        borderRadius: 4, pointerEvents: "none",
      }}/>
      <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", gap: 1, padding: "0 1px" }}>
        {WAVE.map((amp, i) => {
          const sec = (i / N) * TOTAL;
          const inside = sec >= start && sec <= end;
          return <div key={i} style={{ flex: 1, height: Math.max(2, amp * height) + "px", borderRadius: 2, background: inside ? "var(--sm-accent)" : "rgba(168,154,140,0.18)", transition: "background 0.12s ease" }}/>;
        })}
      </div>
      {head != null && (
        <div style={{ position: "absolute", top: -6, bottom: -6, left: pct(head) + "%", pointerEvents: "none" }}>
          <div style={{ width: 2, height: "100%", marginLeft: -1, background: "var(--sm-accent-glow)", boxShadow: "0 0 8px rgba(214,138,110,0.8)" }}/>
        </div>
      )}
      {interactive && [["start", start], ["end", end]].map(([k, v]) => {
        const isActive = active === k;
        const showBubble = dragK === k || (isActive && !dragK);
        return (
          <div key={k}
            onPointerDown={(e) => { e.preventDefault(); drag.current = k; setDragK(k); onScrub && onScrub(v); }}
            style={{ position: "absolute", top: -12, bottom: -12, left: pct(v) + "%", width: 30, marginLeft: -15, cursor: "ew-resize", display: "flex", alignItems: "center", justifyContent: "center", zIndex: isActive ? 4 : 3 }}>
            {/* Zeit-Blase */}
            {showBubble && (
              <div style={{
                position: "absolute", top: -30, left: "50%",
                transform: "translateX(-50%)",
                background: "var(--sm-accent-glow)", color: "#2a1208",
                fontFamily: "var(--sm-font-display)", fontSize: 15, fontWeight: 500,
                padding: "3px 9px", borderRadius: 8, whiteSpace: "nowrap", fontFeatureSettings: '"tnum"',
                boxShadow: "0 4px 12px rgba(0,0,0,0.4)",
              }}>{fmt(v)}</div>
            )}
            <div style={{
              width: 7, height: "100%", borderRadius: 5,
              background: "linear-gradient(180deg, var(--sm-accent-glow), var(--sm-accent-soft))",
              boxShadow: "0 2px 8px rgba(0,0,0,0.45), inset 0 0 0 1px rgba(255,255,255,0.18)",
              display: "flex", alignItems: "center", justifyContent: "center",
              animation: isActive && !dragK ? "trimHandlePulse 1.8s ease-out infinite" : "none",
            }}>
              <div style={{ width: 2, height: 16, borderRadius: 2, background: "rgba(42,18,8,0.5)" }}/>
            </div>
          </div>
        );
      })}
    </div>
  );
}

const metaLbl = { fontSize: 11, letterSpacing: "0.12em", textTransform: "uppercase", color: "var(--sm-text-3)", fontWeight: 500 };
const navBtn = (c) => ({ background: "none", border: "none", color: c, fontFamily: "var(--sm-font-ui)", fontSize: 15, padding: "6px 0", cursor: "pointer" });
const navTitle = { position: "absolute", left: "50%", top: "50%", transform: "translate(-50%,-50%)", fontFamily: "var(--sm-font-display)", fontSize: 17, color: "var(--sm-text)", whiteSpace: "nowrap" };

/* ============================================================
   Editor-Sheet (B)
   ============================================================ */
function TrimSheet({ open, init, onClose, onDone }) {
  const [start, setStart] = useS(init.start);
  const [end, setEnd] = useS(init.end);
  const [active, setActive] = useS("start");
  const { head, setHead, playing, previewing, begin, pause } = usePlayhead(init.start);

  // Beim Öffnen Werte neu aus init übernehmen
  useE(() => { if (open) { setStart(init.start); setEnd(init.end); setActive("start"); setHead(init.start); } }, [open]);

  const onChange = (s, e, which) => { setStart(s); setEnd(e); setActive(which); };
  const cur = active === "start" ? start : end;
  const setCur = (v) => active === "start" ? setStart(Math.min(v, end - 25)) : setEnd(Math.max(v, start + 25));
  const nudge = (d) => { const v = clamp(cur + d, 0, TOTAL); setCur(v); setHead(v); begin(v, 1500); };

  return (
    <div style={{
      position: "absolute", inset: 0, zIndex: 20,
      transform: open ? "translateY(0)" : "translateY(100%)",
      transition: "transform 0.4s cubic-bezier(0.32,0.72,0,1)",
      background: "radial-gradient(ellipse 90% 70% at 50% 20%, #3a201a 0%, #2a1610 40%, #190c08 75%, #110705 100%)",
      display: "flex", flexDirection: "column",
    }}>
      <SB/>
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "10px 16px 12px", height: 44, position: "relative" }}>
        <button onClick={() => { pause(); onClose(); }} className="press" style={{ ...navBtn("var(--sm-text-2)"), display: "inline-flex", alignItems: "center", paddingLeft: 0 }}>
          <span style={{ width: 22, height: 22 }}>{IcChevL}</span>
        </button>
        <div style={navTitle}>Zuschneiden</div>
        <button onClick={() => { pause(); onDone({ start: Math.round(start), end: Math.round(end) }); }} className="press" style={{ ...navBtn("var(--sm-accent-text)"), fontWeight: 500 }}>Fertig</button>
      </div>

      <div style={{ padding: "10px 24px", display: "flex", flexDirection: "column", flex: 1 }}>
        <div style={{ textAlign: "center" }}>
          <div style={{ fontFamily: "var(--sm-font-display)", fontSize: 22, color: "var(--sm-text)" }}>Evening Wind Down</div>
          <div style={{ fontSize: 13, color: "var(--sm-text-2)", marginTop: 4 }}>Tara Goldstein · 19:05</div>
        </div>

        <div style={{ textAlign: "center", marginTop: 26 }}>
          <div style={metaLbl}>{active === "start" ? "Beginnt bei" : "Endet bei"}</div>
          <div style={{ fontFamily: "var(--sm-font-display)", fontSize: 60, color: "var(--sm-accent-text)", lineHeight: 1, marginTop: 6, fontFeatureSettings: '"tnum"' }}>{fmt(cur)}</div>
          <div style={{ fontSize: 13, color: "var(--sm-text-2)", marginTop: 8 }}>Hörbar: {fmt(start)} – {fmt(end)} · {fmt(end - start)}</div>
        </div>

        <div style={{ marginTop: 30 }}>
          <TrimTrack start={start} end={end} active={active} onChange={onChange}
            head={head}
            onScrub={(t) => setHead(t)} onScrubEnd={() => begin(cur, 2600)} height={108}/>
          <div style={{ display: "flex", justifyContent: "space-between", marginTop: 12, fontSize: 11, color: "var(--sm-text-3)", fontFeatureSettings: '"tnum"' }}>
            <span>0:00</span><span style={{ color: (playing || previewing) ? "var(--sm-accent-text)" : "var(--sm-text-3)" }}>{fmt(head ?? 0)}</span><span>19:05</span>
          </div>
        </div>

        <div style={{ display: "flex", gap: 10, marginTop: 24 }}>
          <ReadoutCard label="Anfang" value={fmt(start)} active={active === "start"} onClick={() => { setActive("start"); setHead(start); }}/>
          <ReadoutCard label="Ende" value={fmt(end)} active={active === "end"} onClick={() => { setActive("end"); setHead(end); }}/>
        </div>

        <div style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: 16, marginTop: 24 }}>
          <button onClick={() => nudge(-1)} className="press" style={nudgeBtn}>−1s</button>
          <button onClick={() => playing ? pause() : begin(cur)} className="press" style={{
            width: 66, height: 66, borderRadius: "50%", border: "none", cursor: "pointer",
            background: "linear-gradient(180deg, var(--sm-accent-glow), var(--sm-accent-soft))", color: "#2a1208",
            boxShadow: "0 12px 30px -8px rgba(196,122,94,0.6), inset 0 0 0 1px rgba(214,138,110,0.3)",
            display: "inline-flex", alignItems: "center", justifyContent: "center",
          }}>
            <span style={{ width: 28, height: 28, marginLeft: playing ? 0 : 3 }}>{playing ? IcPause : IcPlay}</span>
          </button>
          <button onClick={() => nudge(1)} className="press" style={nudgeBtn}>+1s</button>
        </div>
        <div style={{ textAlign: "center", marginTop: 12, fontSize: 12, color: "var(--sm-text-3)" }}>Ab dem markierten Punkt vorhören</div>

        <div style={{ flex: 1 }}/>
        <button onClick={() => { setStart(0); setEnd(TOTAL); setActive("start"); setHead(0); }} className="press" style={{
          alignSelf: "center", background: "none", border: "none", color: "var(--sm-text-2)",
          fontFamily: "var(--sm-font-ui)", fontSize: 13, cursor: "pointer", padding: "8px 0 4px",
        }}>Ganze Datei verwenden</button>
      </div>
    </div>
  );
}
function ReadoutCard({ label, value, active, onClick }) {
  return (
    <button onClick={onClick} className="press" style={{
      flex: 1, textAlign: "left", background: active ? "var(--sm-accent-dim)" : "rgba(235,226,214,0.04)",
      border: "1px solid " + (active ? "rgba(214,138,110,0.4)" : "var(--sm-card-line)"),
      borderRadius: 14, padding: "10px 14px", cursor: "pointer", fontFamily: "var(--sm-font-ui)",
    }}>
      <div style={metaLbl}>{label}</div>
      <div style={{ fontFamily: "var(--sm-font-display)", fontSize: 26, color: active ? "var(--sm-accent-text)" : "var(--sm-text)", marginTop: 2, fontFeatureSettings: '"tnum"' }}>{value}</div>
    </button>
  );
}
const nudgeBtn = { minWidth: 58, height: 46, borderRadius: 999, border: "1px solid var(--sm-card-line)", background: "rgba(235,226,214,0.05)", color: "var(--sm-text)", fontFamily: "var(--sm-font-ui)", fontSize: 15, cursor: "pointer", fontFeatureSettings: '"tnum"' };

/* ============================================================
   Edit-Formular
   ============================================================ */
function App() {
  const [trim, setTrim] = useS(null);     // {start,end} oder null = ganze Datei
  const [sheet, setSheet] = useS(false);
  const isTrimmed = trim != null;
  const init = trim ?? { start: 0, end: TOTAL };

  return (
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

        {/* Wiedergabe-Bereich — öffnet Editor */}
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
                <TrimTrack start={trim.start} end={trim.end} active={null} onChange={() => {}} head={null} interactive={false} height={44}/>
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

      <TrimSheet open={sheet} init={init}
        onClose={() => setSheet(false)}
        onDone={(v) => { setTrim(v.start <= 1 && v.end >= TOTAL - 1 ? null : v); setSheet(false); }}/>
    </div>
  );
}

window.SM_App = App;
