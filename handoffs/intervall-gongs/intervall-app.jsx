/* intervall-app.jsx — Timer "Intervall-Gongs" (Wiederkehrende Gongs), gehobene
   Neufassung im Muster des Start-&-Ende-Screens.
   - Master-Schalter (Intervall-Gongs an/aus)
   - Intervall-Stepper (Preset-Leiter)
   - Modus: Regelmäßig / Nach Start / Vor Ende (Bedeutung passt sich an)
   - Klang als Karten-Picker (Vorhören, Mini-Wellenform, Häkchen) — wie Start & Ende
   - Lautstärke als Slider
   Nur Nacht-Theme (wie die App-Screenshots). */

const { useState: uS, useRef: uR, useEffect: uE } = React;
const A = window.GongAudio;

/* ---- Klänge: identisch zu Start & Ende (4 Töne + Vibration) ---- */
const TONES = [
  { id: "Klarer Anschlag",audio: "Klarer Anschlag",desc: "Trocken, präzise, kurz" },
  { id: "Tempelglocke",   audio: "Tempelglocke",   desc: "Tiefe, lang ausklingende Bronze" },
  { id: "Klassisch",      audio: "Klassisch",      desc: "Heller Glockenanschlag, ausgewogen" },
  { id: "Tiefe Resonanz", audio: "Tiefe Resonanz", desc: "Sehr tief, sphärisch, langer Nachhall" },
  { id: "Vibration",      audio: null,             desc: "Sanfter Impuls — kein Ton" },
];

/* Intervall-Preset-Leiter (Minuten) */
const STEPS = [1, 2, 3, 5, 10, 15, 20, 30, 45, 60];

/* ---- Icons ---- */
const I = {
  back: <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><path d="M15 5 L8 12 L15 19"/></svg>,
  check: <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round"><path d="M4 12.5 L9.5 18 L20 6"/></svg>,
  play: <svg width="15" height="15" viewBox="0 0 24 24" fill="currentColor"><path d="M7 5 L19 12 L7 19 Z"/></svg>,
  haptic: <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M12 4 V20"/><path d="M7 8 V16"/><path d="M17 8 V16"/><path d="M3 11 V13"/><path d="M21 11 V13"/></svg>,
  repeat: <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round"><path d="M4 8 A8 8 0 0 1 18 4.5 L20 6.5"/><path d="M20 16 A8 8 0 0 1 6 19.5 L4 17.5"/><path d="M20 3 V6.5 H16.5"/><path d="M4 21 V17.5 H7.5"/></svg>,
  minus: <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round"><path d="M5 12 H19"/></svg>,
  plus: <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round"><path d="M12 5 V19"/><path d="M5 12 H19"/></svg>,
  volLow: <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor"><path d="M4 9 H8 L13 5 V19 L8 15 H4 Z"/></svg>,
  volHigh: <svg width="22" height="22" viewBox="0 0 24 24" fill="none"><path d="M3 9 H7 L12 5 V19 L7 15 H3 Z" fill="currentColor"/><path d="M16 8.5 A5 5 0 0 1 16 15.5" stroke="currentColor" strokeWidth="1.8" fill="none" strokeLinecap="round"/><path d="M18.5 6 A8.5 8.5 0 0 1 18.5 18" stroke="currentColor" strokeWidth="1.8" fill="none" strokeLinecap="round"/></svg>,
  timer: <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="13" r="8"/><path d="M12 13 V8.5"/><path d="M9 2.5 H15"/></svg>,
  gear: <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><line x1="4" y1="7" x2="20" y2="7"/><line x1="4" y1="17" x2="20" y2="17"/><circle cx="9" cy="7" r="2.4" fill="var(--bg-bot)"/><circle cx="15" cy="17" r="2.4" fill="var(--bg-bot)"/></svg>,
  wave: <svg width="22" height="22" viewBox="0 0 24 24" fill="currentColor"><rect x="2" y="9" width="2.6" height="6" rx="1.3"/><rect x="6.5" y="5" width="2.6" height="14" rx="1.3"/><rect x="11" y="2" width="2.6" height="20" rx="1.3"/><rect x="15.5" y="6" width="2.6" height="12" rx="1.3"/><rect x="20" y="9" width="2.6" height="6" rx="1.3"/></svg>,
};

const StatusBar = () => (
  <div className="statusbar">
    <span>9:41</span>
    <span className="icons">
      <svg width="18" height="12" viewBox="0 0 18 12" fill="currentColor"><rect x="0" y="7" width="3" height="5" rx="1"/><rect x="5" y="4.5" width="3" height="7.5" rx="1"/><rect x="10" y="2" width="3" height="10" rx="1"/><rect x="15" y="0" width="3" height="12" rx="1" opacity="0.35"/></svg>
      <svg width="17" height="12" viewBox="0 0 17 12" fill="currentColor"><path d="M8.5 2.5c2.3 0 4.4.9 6 2.4l-1.4 1.5A6.6 6.6 0 0 0 8.5 4.6 6.6 6.6 0 0 0 3.9 6.4L2.5 4.9A8.6 8.6 0 0 1 8.5 2.5Z"/><path d="M8.5 6.6c1.2 0 2.3.5 3.1 1.3L8.5 11.3 5.4 7.9A4.4 4.4 0 0 1 8.5 6.6Z"/></svg>
      <svg width="26" height="12" viewBox="0 0 26 12" fill="none"><rect x="1" y="1" width="21" height="10" rx="3" stroke="currentColor" strokeOpacity="0.4"/><rect x="3" y="3" width="16" height="6" rx="1.5" fill="currentColor"/><rect x="23.5" y="4" width="1.5" height="4" rx="0.75" fill="currentColor" fillOpacity="0.4"/></svg>
    </span>
  </div>
);

/* Meaningful decay envelope per gong — identisch zu Start & Ende. */
const WAVE = {
  "Tempelglocke":   [0.35, 0.9, 1.0, 0.85, 0.78, 0.68, 0.6, 0.5, 0.42, 0.34, 0.26],
  "Klassisch":      [0.3, 0.95, 0.8, 0.65, 0.55, 0.45, 0.4, 0.32, 0.28, 0.22, 0.18],
  "Tiefe Resonanz": [0.45, 0.7, 0.9, 1.0, 0.92, 0.86, 0.8, 0.72, 0.64, 0.54, 0.44],
  "Klarer Anschlag":[0.25, 1.0, 0.7, 0.45, 0.3, 0.2, 0.14, 0.1, 0.08, 0.06, 0.05],
};
function ToneWave({ id }) {
  const env = WAVE[id] || WAVE["Klassisch"];
  return (
    <span className="tone-wave">
      {env.map((v, i) => <i key={i} style={{ height: 4 + Math.round(v * 16) }} />)}
    </span>
  );
}

const MODES = [
  { id: "regelmaessig", label: "Regelmäßig" },
  { id: "nachstart",    label: "Nach Start" },
  { id: "vorende",      label: "Vor Ende" },
];

function minLabel(m) { return m === 1 ? "1 Minute" : `${m} Minuten`; }

function modeHelp(mode, min) {
  const m = <em>{minLabel(min)}</em>;
  if (mode === "nachstart") return <>Ein einzelner Gong, {m} <em>nach Beginn</em> der Sitzung.</>;
  if (mode === "vorende")   return <>Ein einzelner Gong, {m} <em>vor dem Ende</em> der Sitzung.</>;
  return <>Ein Gong ertönt alle {m} während der gesamten Sitzung.</>;
}

function App() {
  const TD = window.TWEAK_DEFAULTS;
  const [t, setTweak] = window.useTweaks(TD);

  const [on, setOn] = uS(true);                 // Master: Intervall-Gongs an/aus
  const [stepIdx, setStepIdx] = uS(3);          // -> 5 Min.
  const [mode, setMode] = uS("regelmaessig");
  const [tone, setTone] = uS("Tempelglocke");
  const [vol, setVol] = uS(64);

  const [ringing, setRinging] = uS(null);
  const min = STEPS[stepIdx];
  const level = Math.max(0.04, vol / 100);

  function preview(tn) {
    A.stopAll();
    const T = TONES.find((x) => x.id === tn);
    if (!T) return;
    if (!T.audio) {
      if (navigator.vibrate) navigator.vibrate([20, 40, 20]);
      setRinging(tn);
      setTimeout(() => setRinging((r) => (r === tn ? null : r)), 520);
      return;
    }
    A.playGong(T.audio, level);
    setRinging(tn);
    setTimeout(() => setRinging((r) => (r === tn ? null : r)), 900);
  }
  function selectTone(tn) { setTone(tn); preview(tn); }

  uE(() => () => { A.stopAll(); }, []);

  const accent = t.accent;
  const showDesc = t.descriptions === true;

  const Tab = ({ label, icon, active }) => (
    <button className={`tab ${active ? "on" : ""}`}>
      <span className="ti">{icon}</span>
      <span>{label}</span>
    </button>
  );

  return (
    <div className="phone" id="phone" style={{ "--accent": accent, "--accent-soft": accent }}>
      <div className="screen">
        <StatusBar />

        <div className="nav">
          <button className="nav-back press">{I.back}<span>Zurück</span></button>
          <div className="nav-title">Intervall-Gongs</div>
          <span />
        </div>

        <div className="content">
          {/* Master toggle */}
          <div className="master-card">
            <span className="master-ico">{I.repeat}</span>
            <span className="master-main">
              <span className="master-title" style={{ display: "block" }}>Intervall-Gongs</span>
              <span className="master-sub" style={{ display: "block" }}>
                {on ? "Wiederkehrende Gongs während der Sitzung" : "Aus — keine Gongs während der Sitzung"}
              </span>
            </span>
            <button className={`switch ${on ? "on" : ""}`} onClick={() => setOn(!on)} aria-label="Intervall-Gongs an/aus" />
          </div>

          {on && (
            <React.Fragment>
              {/* Intervall */}
              <div className="eyebrow" style={{ marginTop: 20 }}>Intervall</div>
              <div className="step-card">
                <span className="step-label">Intervall</span>
                <span className="step-control">
                  <button
                    className="step-btn" disabled={stepIdx === 0}
                    onClick={() => setStepIdx((i) => Math.max(0, i - 1))}
                    aria-label="Kürzer"
                  >{I.minus}</button>
                  <span className="step-value">{min} Min.</span>
                  <button
                    className="step-btn" disabled={stepIdx === STEPS.length - 1}
                    onClick={() => setStepIdx((i) => Math.min(STEPS.length - 1, i + 1))}
                    aria-label="Länger"
                  >{I.plus}</button>
                </span>
              </div>

              {/* Modus */}
              <div className="eyebrow" style={{ marginTop: 20 }}>Modus</div>
              <div className="seg mode">
                {MODES.map((m) => (
                  <button key={m.id} className={mode === m.id ? "on" : ""} onClick={() => setMode(m.id)}>{m.label}</button>
                ))}
              </div>
              <p className="mode-help">{modeHelp(mode, min)}</p>

              {/* Klang — Karten-Picker */}
              <div className="eyebrow" style={{ marginTop: 18 }}>Klang</div>
              <div className="tone-list">
                {TONES.map((T) => {
                  const sel = tone === T.id;
                  const vib = !T.audio;
                  return (
                    <button key={T.id} className={`tone ${sel ? "sel" : ""}`} onClick={() => selectTone(T.id)}>
                      <span
                        className={`preview-btn ${ringing === T.id ? (vib ? "buzz" : "ringing") : ""}`}
                        onClick={(e) => { e.stopPropagation(); preview(T.id); }}
                        role="button" aria-label={`${T.id} anhören`}
                      >{vib ? I.haptic : I.play}</span>
                      <span className="tone-main">
                        <span className="tone-name" style={{ display: "block" }}>{T.id}</span>
                        {showDesc && <span className="tone-desc" style={{ display: "block" }}>{T.desc}</span>}
                      </span>
                      {vib
                        ? <span className="haptic-dots"><i /><i /><i /></span>
                        : <ToneWave id={T.id} />}
                      {sel && <span className="tone-check">{I.check}</span>}
                    </button>
                  );
                })}
              </div>

              {tone === "Vibration" ? (
                <p className="helper">
                  Dein Gerät gibt statt eines Klangs einen <em>sanften Impuls</em> — lautlos, ideal für stille Räume.
                </p>
              ) : (
                <React.Fragment>
                  {/* Lautstärke */}
                  <div className="eyebrow" style={{ marginTop: 18 }}>Lautstärke</div>
                  <div className="vol-card">
                    <div className="vol-row">
                      <span className="vol-ico">{I.volLow}</span>
                      <input
                        className="slider" type="range" min="0" max="100" step="1"
                        value={vol}
                        onChange={(e) => setVol(+e.target.value)}
                      />
                      <span className="vol-ico">{I.volHigh}</span>
                    </div>
                  </div>
                </React.Fragment>
              )}
            </React.Fragment>
          )}

          {!on && (
            <p className="helper" style={{ marginTop: 6 }}>
              Schalte <em>Intervall-Gongs</em> ein, um in regelmäßigen Abständen einen sanften Klang zu hören — eine ruhige Markierung der Zeit.
            </p>
          )}
        </div>

        {/* Tab bar */}
        <div className="tabbar">
          <Tab label="Meditationen" icon={I.wave} active={false} />
          <Tab label="Timer" icon={I.timer} active={true} />
          <Tab label="Einstellungen" icon={I.gear} active={false} />
        </div>
        <div className="home-ind" />
      </div>

      <window.TweaksPanel>
        <window.TweakSection label="Klang-Liste" />
        <window.TweakToggle
          label="Beschreibungen"
          value={t.descriptions === true}
          onChange={(v) => setTweak("descriptions", v)}
        />
        <window.TweakSection label="Akzent" />
        <window.TweakColor
          label="Akzentfarbe"
          value={t.accent}
          options={["#CC7E5F", "#C2A26B", "#9C8F7E", "#B5715A"]}
          onChange={(v) => setTweak("accent", v)}
        />
      </window.TweaksPanel>
    </div>
  );
}

/* ---------- scale phone to viewport ---------- */
function fitPhone() {
  const p = document.getElementById("phone");
  if (!p) return;
  const margin = 40;
  const s = Math.min((window.innerWidth - margin) / 393, (window.innerHeight - margin) / 852, 1.05);
  p.style.transform = `scale(${s})`;
}
window.addEventListener("resize", fitPhone);
const _obs = setInterval(fitPhone, 300);
setTimeout(() => clearInterval(_obs), 3000);

ReactDOM.createRoot(document.getElementById("stage")).render(<App />);
setTimeout(fitPhone, 60);
