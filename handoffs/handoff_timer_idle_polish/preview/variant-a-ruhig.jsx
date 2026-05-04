/* Variant A — RUHIG (SE-tauglich)
   - −/+ Buttons aus der Zeitenstellung entfernt (Drag im Ring + Tap auf Ring-Bereich)
   - Headline „Passe den Timer an" entfernt
   - Settings als ruhige Liste statt Karten-Raster
   - Responsiv: kompakte Defaults für SE, größere Werte für 393er-Frame
*/

const { Phone: Ph_A, StatusBar: SB_A, TabBar: TB_A, Icons: Ic_A } = window.SM;
const { RingQuiet: RQ_A } = window.SM_RingQuiet;

function CalmListRow_A({ label, value, on, onClick, compact }) {
  const dim = on === false;
  return (
    <button onClick={onClick}
      style={{
        width: "100%", background: "transparent", border: "none", cursor: "pointer",
        padding: compact ? "8px 4px" : "14px 4px",
        display: "flex", alignItems: "center", justifyContent: "space-between",
        color: "inherit", fontFamily: "inherit", textAlign: "left",
        opacity: dim ? 0.4 : 1, transition: "opacity 0.2s",
      }}>
      <span style={{ fontSize: compact ? 13 : 14, color: "var(--sm-text)", letterSpacing: "0.005em" }}>{label}</span>
      <span style={{ display: "inline-flex", alignItems: "center", gap: 8 }}>
        <span style={{
          fontFamily: "var(--sm-font-display)", fontWeight: 400,
          fontSize: compact ? 13 : 14, color: dim ? "var(--sm-text-3)" : "var(--sm-accent-text)",
        }}>{value}</span>
        <span style={{ width: 12, height: 12, color: "var(--sm-text-3)", opacity: 0.6 }}>{Ic_A.chevR}</span>
      </span>
    </button>
  );
}

function VariantA_Ruhig({ minutes, setMinutes, dense, activeTab, setActiveTab,
                         small = false, phoneClass = "" }) {
  const settings = [
    { key: "prep",     label: "Vorbereitung", value: dense.prepOn ? dense.prepDur : "Aus", on: dense.prepOn },
    { key: "gong",     label: "Gong",         value: dense.gong, on: true },
    { key: "interval", label: "Intervall",    value: dense.intervalOn ? dense.interval : "Aus", on: dense.intervalOn },
    { key: "ambient",  label: "Hintergrund",  value: dense.ambientOn ? dense.ambient : "Stille", on: dense.ambientOn },
  ];

  // SE-Tuning: jetzt mit einer Zeile weniger — etwas mehr Luft möglich
  const ringSize = small ? 196 : 236;
  const headlinePT = small ? 12 : 18;
  const ringMT = small ? 14 : 28;
  const listMT = small ? 18 : 32;
  const btnMT  = small ? 18 : 28;
  const headlineSize = small ? 20 : 22;

  return (
    <div className={phoneClass}>
      <Ph_A label={small ? "A — Ruhig (SE)" : "A — Ruhig"}>
        <SB_A/>
        <div className="screen-content">
          <div style={{ textAlign: "center", padding: `${headlinePT}px 32px 0` }}>
            <div className="h-display" style={{ fontSize: headlineSize, fontWeight: 400 }}>
              Wie viel Zeit schenkst du dir?
            </div>
          </div>

          {/* Ring — keine Stepper */}
          <div style={{ marginTop: ringMT }}>
            <RQ_A value={minutes} onChange={setMinutes} size={ringSize} showInlineSteppers={false}/>
          </div>

          {/* Settings als ruhige Liste */}
          <div style={{ padding: `${listMT}px 28px 0` }}>
            <div style={{
              display: "flex", flexDirection: "column",
              borderTop: "1px solid rgba(235,226,214,0.05)",
            }}>
              {settings.map(s => (
                <div key={s.key} style={{ borderBottom: "1px solid rgba(235,226,214,0.05)" }}>
                  <CalmListRow_A {...s} compact={small} onClick={() => {}}/>
                </div>
              ))}
            </div>
          </div>

          <div style={{ textAlign: "center", marginTop: btnMT }}>
            <button className="btn-primary press" style={small ? { padding: "13px 32px", fontSize: 16 } : {}}>
              <span style={{ width: 18, height: 18, display: "inline-flex" }}>{Ic_A.play}</span>
              Beginnen
            </button>
          </div>
        </div>
        <TB_A active={activeTab} onChange={setActiveTab}/>
      </Ph_A>
    </div>
  );
}

window.SM_VariantA = { VariantA_Ruhig };
