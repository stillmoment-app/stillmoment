/* soundscape-app.jsx — Timer "Hintergrundklang" (Soundscape), gehobene Neufassung
   im Muster von "Start & Ende" (Gong-Auswahl) und "Intervall-Gongs":
   - Klang als Karten-Picker (Vorhören, charakteristische Wellenform, Häkchen)
   - "Stille" als ruhige Option (kein Ton — wie "Vibration" in der Gong-Liste)
   - "Meine Klänge": eigene importierte Dateien (+ Import-Aktion)
   - Lautstärke als Slider (entfällt bei "Stille")
   Nur Nacht-Theme (wie die App-Screenshots).

   Unterschied zum Gong: Hintergrundklänge LOOPEN. Der Vorhör-Button ist deshalb
   ein Play/Stop-Schalter, und die Wellenform animiert beim Abspielen. */

const { useState: uS, useRef: uR, useEffect: uE } = React;
const AM = window.AmbientAudio;

/* ---- Eingebaute Klänge ---- */
const SCAPES = [
  { id: "Stille",          silent: true, desc: "Vollkommene Ruhe — kein Klang" },
  { id: "Waldatmosphäre",  desc: "Sanftes Blätterrauschen, ferne Vögel" },
  { id: "Regen",           desc: "Gleichmäßiger, beruhigender Regen" },
];

/* Beispiel für "Meine Klänge" (nur sichtbar mit Tweak „Eigene Dateien") */
const OWN = [
  { id: "Meeresrauschen.m4a", desc: "Importiert · 12:40" },
  { id: "Tibet Bowls.mp3",    desc: "Importiert · 08:15" },
];

/* Charakteristische Loop-Wellenformen (13 Balken, 0..1) — rein visuell. */
const SWAVE = {
  "Waldatmosphäre":   [0.30, 0.55, 0.40, 0.70, 0.50, 0.62, 0.45, 0.72, 0.52, 0.60, 0.42, 0.58, 0.36],
  "Regen":            [0.62, 0.74, 0.58, 0.80, 0.66, 0.78, 0.60, 0.82, 0.64, 0.76, 0.58, 0.72, 0.60],
  "Meeresrauschen.m4a":[0.45, 0.70, 0.85, 0.62, 0.40, 0.58, 0.80, 0.66, 0.44, 0.62, 0.82, 0.58, 0.42],
  "Tibet Bowls.mp3":  [0.38, 0.92, 0.78, 0.64, 0.54, 0.46, 0.40, 0.34, 0.30, 0.26, 0.22, 0.18, 0.15],
};

/* ---- Icons ---- */
const I = {
  back: <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><path d="M15 5 L8 12 L15 19"/></svg>,
  check: <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round"><path d="M4 12.5 L9.5 18 L20 6"/></svg>,
  play: <svg width="15" height="15" viewBox="0 0 24 24" fill="currentColor"><path d="M7 5 L19 12 L7 19 Z"/></svg>,
  stop: <svg width="15" height="15" viewBox="0 0 24 24" fill="currentColor"><rect x="6" y="6" width="12" height="12" rx="2.5"/></svg>,
  mute: <svg width="19" height="19" viewBox="0 0 24 24" fill="none"><path d="M3 9 H7 L12 5 V19 L7 15 H3 Z" fill="currentColor"/><path d="M16 9.5 L21 14.5 M21 9.5 L16 14.5" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round"/></svg>,
  plus: <svg width="19" height="19" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round"><path d="M12 5 V19"/><path d="M5 12 H19"/></svg>,
  trash: <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round"><path d="M4 7 H20"/><path d="M9 7 V5 H15 V7"/><path d="M6 7 L7 20 H17 L18 7"/></svg>,
  edit: <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round"><path d="M14 4 L20 10 L9 21 L3.5 21 L3.5 15.5 Z"/><path d="M12.5 5.5 L18.5 11.5"/></svg>,
  more: <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><circle cx="12" cy="5" r="1.85"/><circle cx="12" cy="12" r="1.85"/><circle cx="12" cy="19" r="1.85"/></svg>,
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

function ScapeWave({ id, playing }) {
  const env = SWAVE[id] || SWAVE["Regen"];
  return (
    <span className={`scape-wave ${playing ? "playing" : ""}`}>
      {env.map((v, i) => (
        <i key={i} style={{ height: 4 + Math.round(v * 16), "--i": i }} />
      ))}
    </span>
  );
}

function App() {
  const TD = window.TWEAK_DEFAULTS;
  const [t, setTweak] = window.useTweaks(TD);

  const [scape, setScape] = uS("Waldatmosphäre");
  const [playing, setPlaying] = uS(null); // id currently previewing (loop) or null
  const [vol, setVol] = uS(60);
  const [ownList, setOwnList] = uS(OWN);
  const [pendingDelete, setPendingDelete] = uS(null);
  const [pendingRename, setPendingRename] = uS(null);
  const [renameText, setRenameText] = uS("");
  const [menuFor, setMenuFor] = uS(null);

  const level = Math.max(0.04, vol / 100);
  const showDesc = t.descriptions === true;
  const showOwn = t.ownFiles === true;
  const accent = t.accent;

  const allScapes = [...SCAPES, ...(showOwn ? ownList : [])];
  const current = allScapes.find((s) => s.id === scape) || SCAPES[0];
  const silent = !!current.silent;

  function startLoop(id) { AM.play(id, level); setPlaying(id); }
  function stopLoop() { AM.stopAll(); setPlaying(null); }

  function togglePreview(s) {
    if (s.silent) { stopLoop(); return; }
    if (playing === s.id) stopLoop();
    else startLoop(s.id);
  }

  function selectScape(s) {
    setScape(s.id);
    if (s.silent) stopLoop();
    else startLoop(s.id);
  }

  function confirmDelete() {
    if (!pendingDelete) return;
    const id = pendingDelete.id;
    setOwnList((l) => l.filter((x) => x.id !== id));
    if (playing === id) stopLoop();
    if (scape === id) { setScape("Waldatmosphäre"); }
    setPendingDelete(null);
  }

  function openRename(s) { setPendingRename(s); setRenameText(s.id); }
  function confirmRename() {
    if (!pendingRename) return;
    const oldId = pendingRename.id;
    const next = renameText.trim();
    if (!next || next === oldId || ownList.some((x) => x.id === next)) { setPendingRename(null); return; }
    if (SWAVE[oldId] && !SWAVE[next]) SWAVE[next] = SWAVE[oldId]; // keep the waveform character
    setOwnList((l) => l.map((x) => (x.id === oldId ? { ...x, id: next } : x)));
    if (scape === oldId) setScape(next);
    if (playing === oldId) setPlaying(next);
    setPendingRename(null);
  }

  // keep live preview level in sync with the slider
  uE(() => { AM.setLevel(level); }, [vol]);
  // stop audio if the chosen scape becomes silent
  uE(() => { if (silent) stopLoop(); }, [silent]);
  uE(() => () => { AM.stopAll(); }, []);

  const Tab = ({ label, icon, active }) => (
    <button className={`tab ${active ? "on" : ""}`}>
      <span className="ti">{icon}</span>
      <span>{label}</span>
    </button>
  );

  const ScapeRow = ({ s, removable }) => {
    const sel = scape === s.id;
    const isPlaying = playing === s.id;
    return (
      <button className={`tone ${sel ? "sel" : ""}`} onClick={() => selectScape(s)}>
        <span
          className={`preview-btn ${isPlaying ? "looping" : ""}`}
          onClick={(e) => { e.stopPropagation(); togglePreview(s); }}
          role="button" aria-label={`${s.id} ${s.silent ? "" : "anhören"}`}
        >{s.silent ? I.mute : (isPlaying ? I.stop : I.play)}</span>
        <span className="tone-main">
          <span className="tone-name" style={{ display: "block" }}>{s.id}</span>
          {showDesc && <span className="tone-desc" style={{ display: "block" }}>{s.desc}</span>}
        </span>
        {s.silent
          ? <span className="scape-flat"><i /></span>
          : <ScapeWave id={s.id} playing={isPlaying} />}
        {removable ? (
          <span className="tone-actions">
            {sel && <span className="tone-check">{I.check}</span>}
            <span className="tone-act" role="button" aria-label="Mehr"
                  onClick={(e) => { e.stopPropagation(); setMenuFor(s); }}>{I.more}</span>
          </span>
        ) : (
          sel && <span className="tone-check">{I.check}</span>
        )}
      </button>
    );
  };

  return (
    <div className="phone" id="phone" style={{ "--accent": accent, "--accent-soft": accent }}>
      <div className="screen">
        <StatusBar />

        <div className="nav">
          <button className="nav-back press">{I.back}<span>Zurück</span></button>
          <div className="nav-title">Hintergrundklang</div>
          <span />
        </div>

        <div className="content">
          <p className="intro">
            Wähle einen Hintergrundklang für deine Sitzung — oder wähle <em>Stille</em> für Ruhe.
          </p>

          {/* Klang — Karten-Picker */}
          <div className="eyebrow">Klang</div>
          <div className="tone-list">
            {SCAPES.map((s) => <ScapeRow key={s.id} s={s} />)}
          </div>

          {/* Meine Klänge */}
          <div className="eyebrow" style={{ marginTop: 22 }}>Meine Klänge</div>
          {showOwn && ownList.length > 0 ? (
            <div className="tone-list">
              {ownList.map((s) => <ScapeRow key={s.id} s={s} removable />)}
            </div>
          ) : (
            <div className="empty-card">Du kannst auch eigene Hintergrundklänge importieren</div>
          )}
          <button className="import-btn press">
            <span className="ib-ico">{I.plus}</span>Eigene Datei importieren
          </button>

          {/* Lautstärke */}
          {silent ? (
            <p className="helper" style={{ marginTop: 18 }}>
              <em>Stille</em> bedeutet vollkommene Ruhe — nur deine Atmung und der Raum um dich.
            </p>
          ) : (
            <React.Fragment>
              <div className="eyebrow" style={{ marginTop: 22 }}>Lautstärke</div>
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
        </div>

        {/* Tab bar */}
        <div className="tabbar">
          <Tab label="Meditationen" icon={I.wave} active={false} />
          <Tab label="Timer" icon={I.timer} active={true} />
          <Tab label="Einstellungen" icon={I.gear} active={false} />
        </div>
        <div className="home-ind" />

        {menuFor && (
          <div className="sheet-backdrop" onClick={() => setMenuFor(null)}>
            <div className="sheet" onClick={(e) => e.stopPropagation()}>
              <div className="sheet-group">
                <div className="sheet-title">{menuFor.id}</div>
                <button className="sheet-btn" onClick={() => { const s = menuFor; setMenuFor(null); openRename(s); }}>Umbenennen</button>
                <button className="sheet-btn destructive" onClick={() => { const s = menuFor; setMenuFor(null); setPendingDelete(s); }}>Entfernen</button>
              </div>
              <button className="sheet-btn cancel" onClick={() => setMenuFor(null)}>Abbrechen</button>
            </div>
          </div>
        )}

        {pendingRename && (
          <div className="dialog-backdrop" onClick={() => setPendingRename(null)}>
            <div className="dialog" onClick={(e) => e.stopPropagation()}>
              <div className="dialog-title">Umbenennen</div>
              <div className="dialog-body">
                <input
                  className="dialog-input" type="text" autoFocus
                  value={renameText}
                  onChange={(e) => setRenameText(e.target.value)}
                  onKeyDown={(e) => { if (e.key === "Enter") confirmRename(); }}
                />
              </div>
              <div className="dialog-actions">
                <button className="dialog-btn" onClick={() => setPendingRename(null)}>Abbrechen</button>
                <button className="dialog-btn primary" onClick={confirmRename}>Sichern</button>
              </div>
            </div>
          </div>
        )}

        {pendingDelete && (
          <div className="dialog-backdrop" onClick={() => setPendingDelete(null)}>
            <div className="dialog" onClick={(e) => e.stopPropagation()}>
              <div className="dialog-title">Datei entfernen?</div>
              <div className="dialog-msg">„{pendingDelete.id}“ wird aus deinen Klängen entfernt.</div>
              <div className="dialog-actions">
                <button className="dialog-btn" onClick={() => setPendingDelete(null)}>Abbrechen</button>
                <button className="dialog-btn destructive" onClick={confirmDelete}>Entfernen</button>
              </div>
            </div>
          </div>
        )}
      </div>

      <window.TweaksPanel>
        <window.TweakSection label="Klang-Liste" />
        <window.TweakToggle
          label="Beschreibungen"
          value={t.descriptions === true}
          onChange={(v) => setTweak("descriptions", v)}
        />
        <window.TweakToggle
          label="Eigene Dateien (Beispiel)"
          value={t.ownFiles === true}
          onChange={(v) => setTweak("ownFiles", v)}
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
