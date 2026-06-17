/* vorbereitung-app.jsx — Timer "Vorbereitungszeit" (Einstimm-Zeit), gehobene
   Neufassung im Muster des Start-&-Ende-Screens.
   - Master-Schalter an/aus
   - Großer Wert-Hero + gerasterter Slider (5-Sekunden-Schritte)
   - Kurzer Erklärungstext
   Nur Nacht-Theme (wie die App-Screenshots). */

const { useState: uS } = React;

const MIN_S = 5, MAX_S = 60, STEP_S = 5;

/* ---- Icons ---- */
const I = {
  back: <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><path d="M15 5 L8 12 L15 19"/></svg>,
  hourglass: <svg width="19" height="19" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round"><path d="M7 3 H17"/><path d="M7 21 H17"/><path d="M7 3 C7 8 12 9 12 12 C12 15 7 16 7 21"/><path d="M17 3 C17 8 12 9 12 12 C12 15 17 16 17 21"/></svg>,
  check: <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round"><path d="M4 12.5 L9.5 18 L20 6"/></svg>,
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

/* großer Wert + gerasterter Slider + Erklärung */

function App() {
  const TD = window.TWEAK_DEFAULTS;
  const [t, setTweak] = window.useTweaks(TD);

  const [on, setOn] = uS(true);   // Master: Vorbereitungszeit an/aus
  const [sel, setSel] = uS(10);   // gewählte Dauer in Sekunden

  const Tab = ({ label, icon, active }) => (
    <button className={`tab ${active ? "on" : ""}`}>
      <span className="ti">{icon}</span>
      <span>{label}</span>
    </button>
  );

  return (
    <div className="phone" id="phone" style={{ "--accent": t.accent, "--accent-soft": t.accent }}>
      <div className="screen">
        <StatusBar />

        <div className="nav">
          <button className="nav-back press">{I.back}<span>Zurück</span></button>
          <div className="nav-title">Vorbereitungszeit</div>
          <span />
        </div>

        <div className="content">
          {/* Master toggle */}
          <div className="master-card">
            <span className="master-ico">{I.hourglass}</span>
            <span className="master-main">
              <span className="master-title" style={{ display: "block" }}>Vorbereitungszeit</span>
              <span className="master-sub" style={{ display: "block" }}>
                {on ? "Eine kurze Stille vor dem Start" : "Aus — der Timer startet sofort"}
              </span>
            </span>
            <button className={`switch ${on ? "on" : ""}`} onClick={() => setOn(!on)} aria-label="Vorbereitungszeit an/aus" />
          </div>

          {on ? (
            <React.Fragment>
              <div className="eyebrow" style={{ marginTop: 20 }}>Dauer</div>
              <div className="prep-hero">
                <span className="prep-val">{sel}</span>
                <span className="prep-unit">{sel === 1 ? "Sekunde" : "Sekunden"}</span>
              </div>
              <div className="vol-card">
                <input
                  className="slider" type="range"
                  min={MIN_S} max={MAX_S} step={STEP_S}
                  value={sel} onChange={(e) => setSel(+e.target.value)}
                />
                <div className="slider-ends"><span>5 Sek.</span><span>1 Min.</span></div>
              </div>
            </React.Fragment>
          ) : (
            <p className="helper" style={{ marginTop: 6 }}>
              Schalte die <em>Vorbereitungszeit</em> ein, um vor dem Start kurz innezuhalten und anzukommen.
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
