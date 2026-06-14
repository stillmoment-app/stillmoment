/* gong-sheet.jsx — the "Klang" control, app-design-accurate.
   Gehobene Klang-Auswahl wie im Timer-Screen "Start & Ende":
   Klang-Karten mit Vorhör-Button, Mini-Wellenform (Charakter des Gongs),
   Beschreibung und Häkchen. ONE gong, same sound for start & end.
   Lautstärke bleibt automatisch (≈ +6 dB über der Sprach-RMS) — kein Slider. */

const { useState: uS, useEffect: uE } = React;

const Ico = {
  chevR: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M9 5 L16 12 L9 19"/></svg>,
  check: <svg width="19" height="19" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round"><path d="M4 12.5 L9.5 18 L20 6"/></svg>,
  x: <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round"><path d="M6 6 L18 18"/><path d="M18 6 L6 18"/></svg>,
  updown: <svg width="13" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round"><path d="M8 9 L12 5 L16 9"/><path d="M8 15 L12 19 L16 15"/></svg>,
  play: <svg width="15" height="15" viewBox="0 0 24 24" fill="currentColor"><path d="M7 5 L19 12 L7 19 Z"/></svg>,
};

/* Decay envelope per gong — left = Anschlag, right = Ausklang.
   Encodes character: Höhe ~ Tiefe/Fülle, Länge des Schwanzes ~ Nachhall. */
const WAVE = {
  "Tempelglocke":   [0.35, 0.9, 1.0, 0.85, 0.78, 0.68, 0.6, 0.5, 0.42, 0.34, 0.26],
  "Klangschale":    [0.3, 0.6, 0.85, 1.0, 0.9, 0.82, 0.74, 0.66, 0.56, 0.46, 0.36],
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

function GongKlang({ voiceModel, tone, onTone }) {
  const A = window.GongAudio;

  // volume is always automatic — derived from the recording's loudness
  const level = A.autoGongLevel(voiceModel.rms, 0);
  const [ringing, setRinging] = uS(null);

  uE(() => () => A.stopAll(), []);

  function preview(id) {
    A.stopAll();
    A.playGong(id, level);
    setRinging(id);
    setTimeout(() => setRinging((r) => (r === id ? null : r)), 900);
  }
  function pick(id) {
    onTone(id);
    preview(id);
  }

  return (
    <div className="tone-list">
      {A.TONE_ORDER.map((id) => {
        const sel = tone === id;
        return (
          <button key={id} className={`tone ${sel ? "sel" : ""}`} onClick={() => pick(id)}>
            <span
              className={`preview-btn ${ringing === id ? "ringing" : ""}`}
              onClick={(e) => { e.stopPropagation(); preview(id); }}
              role="button" aria-label={`${id} anhören`}
            >{Ico.play}</span>
            <span className="tone-main">
              <span className="tone-name" style={{ display: "block" }}>{id}</span>
            </span>
            <ToneWave id={id} />
            {sel && <span className="tone-check">{Ico.check}</span>}
          </button>
        );
      })}
    </div>
  );
}

window.GongKlang = GongKlang;
window.GongIco = Ico;
