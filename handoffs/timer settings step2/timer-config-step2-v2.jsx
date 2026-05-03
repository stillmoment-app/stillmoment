/* Step 2 v2 — Variante 6 (Atemkreis + Feintuning) mit kritischen Verbesserungen:
   - Tropfen größer + sanfter Pulse-Halo (klarere Drag-Affordance)
   - Tick-Marken entfernt (kein falsches Zifferblatt-Signal)
   - Card-Labels in Sentence-Case statt UPPERCASE (warmer Ton, lesbarer)
   - Mehr Atem zwischen Picker und "Passe den Timer an" (44px statt 20px Top-Padding)
*/

const { useState: uS_S2V2 } = React;
const { StatusBar: SB_S2V2, TabBar: TB_S2V2, Phone: Ph_S2V2, Icons: Ic_S2V2 } = window.SM;

function SettingCard_S2V2({ icon, label, value, on, onClick }) {
  const dim = on === false;
  return (
    <button onClick={onClick} className="press" aria-label={label}
      style={{
        cursor: "pointer", textAlign: "left", width: "100%",
        background: "linear-gradient(180deg, rgba(235,226,214,0.045), rgba(235,226,214,0.015))",
        border: "1px solid rgba(235,226,214,0.08)",
        borderRadius: 16, padding: "12px 12px 11px",
        opacity: dim ? 0.45 : 1, transition: "opacity 0.25s",
        display: "flex", flexDirection: "column", alignItems: "center", gap: 7,
        minWidth: 0, color: "inherit", fontFamily: "inherit",
      }}>
      {/* v2: Sentence-Case, kein UPPERCASE/Letterspacing — wärmer */}
      <span style={{
        fontSize: 11, letterSpacing: "0.01em",
        color: "var(--sm-text-3)", fontWeight: 400, textAlign: "center", lineHeight: 1.15,
        overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap", maxWidth: "100%",
        fontFamily: "var(--sm-font-display)",
      }}>{label}</span>
      <span style={{ width: 24, height: 24, color: "var(--sm-accent-text)",
        display: "inline-flex", alignItems: "center", justifyContent: "center" }}>{icon}</span>
      <span style={{
        fontSize: 12, color: "var(--sm-text-2)", fontFamily: "var(--sm-font-display)",
        textAlign: "center", lineHeight: 1.2, overflow: "hidden",
        textOverflow: "ellipsis", whiteSpace: "nowrap", maxWidth: "100%",
      }}>{value}</span>
    </button>
  );
}

function VariantPhoneV2({ label, sub, Picker, minutes, setMinutes, dense, activeTab, setActiveTab }) {
  const settings = [
    { key: "prep",     icon: Ic_S2V2.hourglass, label: "Vorbereitung",
      value: dense.prepOn ? dense.prepDur : "Aus", on: dense.prepOn },
    { key: "intro",    icon: Ic_S2V2.sparkle,   label: "Einstimmung",
      value: dense.introOn ? dense.intro : "Ohne", on: dense.introOn },
    { key: "ambient",  icon: Ic_S2V2.wave,      label: "Hintergrund",
      value: dense.ambientOn ? dense.ambient : "Stille", on: dense.ambientOn },
    { key: "gong",     icon: Ic_S2V2.bell,      label: "Gong", value: dense.gong, on: true },
    { key: "interval", icon: Ic_S2V2.refresh,   label: "Intervall",
      value: dense.intervalOn ? dense.interval : "Aus", on: dense.intervalOn },
  ];
  return (
    <div className="pair">
      <div className="pair-label">{label}</div>
      <div className="pair-sub">{sub}</div>
      <Ph_S2V2 label={label}>
        <SB_S2V2/>
        <div className="screen-content">
          <div style={{ textAlign: "center", padding: "10px 32px 0" }}>
            <div className="h-display" style={{ fontSize: 22, fontWeight: 400 }}>Wie viel Zeit schenkst du dir?</div>
          </div>

          <div style={{ marginTop: 6 }}>
            <Picker value={minutes} onChange={setMinutes}/>
          </div>

          {/* v2: mehr Atem zwischen Picker und Sub-Section */}
          <div style={{
            padding: "44px 32px 4px", textAlign: "center",
          }}>
            <div className="h-display" style={{
              fontSize: 18, fontWeight: 400, color: "var(--sm-text-2)",
            }}>Passe den Timer an</div>
          </div>

          <div style={{ padding: "8px 18px 0", display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 8 }}>
            {settings.slice(0, 3).map(s => (
              <SettingCard_S2V2 key={s.key} {...s} onClick={() => {}}/>
            ))}
          </div>
          <div style={{ padding: "8px 18px 0", display: "grid", gridTemplateColumns: "1fr 1fr", gap: 8 }}>
            {settings.slice(3).map(s => (
              <SettingCard_S2V2 key={s.key} {...s} onClick={() => {}}/>
            ))}
          </div>

          <div style={{ textAlign: "center", marginTop: 32 }}>
            <button className="btn-primary press">
              <span style={{ width: 18, height: 18, display: "inline-flex" }}>{Ic_S2V2.play}</span>
              Beginnen
            </button>
          </div>
        </div>
        <TB_S2V2 active={activeTab} onChange={setActiveTab}/>
      </Ph_S2V2>
    </div>
  );
}

window.SM_Step2V2 = { VariantPhoneV2 };
