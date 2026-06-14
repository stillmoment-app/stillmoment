/* gong-app.jsx — Meditation-Bearbeiten-Screen (Still Moment design system).
   Start-/Ende-Gong: one selectable gong (same sound for start & end), volume
   fully automatic. Built to the app's tokens — supports Hell & Dunkel themes. */

const { useState: uSA } = React;
const GA = window.GongAudio;
const Icon = window.GongIco;

/* ---------- helpers ---------- */
function scaleModel(m, k) {
  return { amp: m.amp.map((a) => Math.min(1, a * k)), rms: Math.min(1, m.rms * k), peak: Math.min(1, m.peak * k) };
}
const RECORDINGS = {
  "mindful": {
    teacher: "Sarah Kornfield", name: "Mindful Breathing",
    file: "mindful-breathing.mp3", dur: "7:33",
    model: scaleModel(GA.makeVoiceModel(96, 7), 0.8),
  },
  "bodyscan": {
    teacher: "Tara Goldstein", name: "Body Scan for Beginners",
    file: "body-scan.mp3", dur: "15:42",
    model: scaleModel(GA.makeVoiceModel(96, 23), 1.06),
  },
};

/* icons used only here */
const fileIcon = (
  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round"><path d="M6 3 H14 L19 8 V21 H6 Z"/><path d="M14 3 V8 H19"/></svg>
);
const scissors = (
  <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><circle cx="6" cy="6" r="2.5"/><circle cx="6" cy="18" r="2.5"/><path d="M8 8 L20 18"/><path d="M8 16 L20 6"/></svg>
);

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

function App() {
  const TD = window.TWEAK_DEFAULTS;
  const [t, setTweak] = window.useTweaks(TD);

  const rec = RECORDINGS[t.recording] || RECORDINGS["mindful"];

  const [startOn, setStartOn] = uSA(true);
  const [endOn, setEndOn] = uSA(true);
  const [tone, setTone] = uSA(GA.FIXED_GONG);

  const anyOn = startOn || endOn;
  const theme = t.theme === "hell" ? "light" : "dark";

  return (
    <div className="phone" id="phone" data-theme={theme}>
      <div className="screen">
        <StatusBar />

        <div className="nav">
          <button className="nav-x press" aria-label="Abbrechen">{Icon.x}</button>
          <button className="nav-save press">Speichern</button>
        </div>

        <div className="content">
          <div className="section-head" style={{ marginTop: 4 }}>Informationen</div>
          <div className="field">
            <div className="field-label">Lehrer / Guide</div>
            <div className="field-value">{rec.teacher}</div>
          </div>
          <div className="field">
            <div className="field-label">Name</div>
            <div className="field-value">{rec.name}</div>
          </div>

          <div className="file-foot">
            {fileIcon}
            <span>{rec.file}</span>
            <span>·</span>
            <span>{rec.dur}</span>
          </div>

          {/* Wiedergabebereich */}
          <div className="section-head">Wiedergabebereich</div>
          <div className="summary-card">
            <button className="row">
              <span className="row-main"><span className="row-title">Ganze Datei · {rec.dur}</span></span>
              <span className="range-sel">Bereich wählen {scissors}</span>
            </button>
          </div>

          {/* Zusätzlicher Gong */}
          <div className="section-head">Zusätzlicher Gong</div>
          <div className="summary-card">
            <div className="row static">
              <span className="row-main"><span className="row-title">Gong am Anfang</span></span>
              <button className={`switch ${startOn ? "on" : ""}`} onClick={() => setStartOn(!startOn)} aria-label="Gong am Anfang" />
            </div>
            <div className="row static">
              <span className="row-main"><span className="row-title">Gong am Ende</span></span>
              <button className={`switch ${endOn ? "on" : ""}`} onClick={() => setEndOn(!endOn)} aria-label="Gong am Ende" />
            </div>
          </div>

          {anyOn && (
            <React.Fragment>
              <div className="eyebrow" style={{ marginTop: 2 }}>Klang</div>
              <window.GongKlang voiceModel={rec.model} tone={tone} onTone={setTone} />
            </React.Fragment>
          )}
        </div>
      </div>

      <window.TweaksPanel>
        <window.TweakSection label="Erscheinungsbild" />
        <window.TweakRadio
          label="Theme" value={t.theme}
          options={[{ value: "hell", label: "Hell" }, { value: "dunkel", label: "Dunkel" }]}
          onChange={(v) => setTweak("theme", v)}
        />
        <window.TweakSection label="Aufnahme" />
        <window.TweakSelect
          label="Datei" value={t.recording}
          options={[{ value: "mindful", label: "Mindful Breathing (leiser)" }, { value: "bodyscan", label: "Body Scan (kräftiger)" }]}
          onChange={(v) => setTweak("recording", v)}
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
  const sx = (window.innerWidth - margin) / 393;
  const sy = (window.innerHeight - margin) / 852;
  const s = Math.min(sx, sy, 1.05);
  p.style.transform = `scale(${s})`;
}
window.addEventListener("resize", fitPhone);
const _obs = setInterval(fitPhone, 300);
setTimeout(() => clearInterval(_obs), 3000);

ReactDOM.createRoot(document.getElementById("stage")).render(<App />);
setTimeout(fitPhone, 60);
