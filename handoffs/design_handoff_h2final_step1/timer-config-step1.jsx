/* Step 1 — Timer-Konfigurations-Screen mit 5 sichtbaren Setting-Karten.

   FOKUS DIESES HANDOFFS: Informationsarchitektur-Änderung.
   - Die 5 Sitzungs-Settings (Vorbereitung, Einstimmung, Hintergrund, Gong, Intervall)
     wandern aus dem dedizierten Settings-Tab/Screen heraus DIREKT auf den Idle-Screen.
   - Jedes Setting wird als klar tippbare Karte sichtbar — Label, Wert, On/Off-State.
   - Tap → öffnet das bereits existierende Detail-Sheet/Subscreen für dieses Setting
     (keine neuen Sheets, keine neue Engine-Logik).

   AUSSERHALB DES SCOPES (in einem späteren Schritt):
   - Die zentrale Zeitauswahl bleibt der bestehende Number-Picker.
     Die Umstellung auf den Atemkreis ist Schritt 2 und gehört NICHT hier rein.
   - Atmosphärische Politur (Sternenhimmel, Halos, 2-zeilige Werte) ist Schritt 3.

   Dieser Prototyp zeigt also bewusst NUR Schritt 1.
*/

const { useState: uS_S1, useRef: uR_S1, useEffect: uE_S1 } = React;
const { StatusBar: SB_S1, TabBar: TB_S1, Phone: Ph_S1, Icons: Ic_S1 } = window.SM;

/* Klassischer vertikaler Number-Picker — entspricht dem heutigen Picker.
   (Bleibt in Schritt 1 unverändert.) */
function ClassicMinutePicker({ value, onChange, max = 60 }) {
  const ref = uR_S1(null);
  const ITEM_H = 48;
  uE_S1(() => {
    if (ref.current) ref.current.scrollTop = (value - 1) * ITEM_H;
  }, []);
  const onScroll = () => {
    if (!ref.current) return;
    const idx = Math.round(ref.current.scrollTop / ITEM_H);
    const v = Math.max(1, Math.min(max, idx + 1));
    if (v !== value) onChange?.(v);
  };
  const opts = Array.from({ length: max }, (_, i) => i + 1);
  return (
    <div style={{ position: "relative", height: ITEM_H * 5, margin: "0 60px" }}>
      <div style={{
        position: "absolute", left: 0, right: 0, top: ITEM_H * 2, height: ITEM_H,
        background: "rgba(235,226,214,0.05)", borderRadius: 999, pointerEvents: "none",
      }}/>
      <div style={{
        position: "absolute", inset: 0, pointerEvents: "none",
        background: "linear-gradient(180deg, rgba(20,10,7,1) 0%, rgba(20,10,7,0) 30%, rgba(20,10,7,0) 70%, rgba(20,10,7,1) 100%)",
        zIndex: 2,
      }}/>
      <div ref={ref} onScroll={onScroll} style={{
        height: "100%", overflowY: "auto", scrollSnapType: "y mandatory",
        paddingTop: ITEM_H * 2, paddingBottom: ITEM_H * 2, textAlign: "center",
      }}>
        {opts.map(o => (
          <div key={o}
            onClick={() => { onChange?.(o); if (ref.current) ref.current.scrollTop = (o - 1) * ITEM_H; }}
            style={{
              height: ITEM_H, lineHeight: `${ITEM_H}px`,
              fontSize: o === value ? 56 : 30,
              fontFamily: "var(--sm-font-display)",
              color: o === value ? "var(--sm-text)" : "rgba(168,154,140,0.35)",
              fontWeight: 300, scrollSnapAlign: "center", cursor: "pointer",
              transition: "all 0.25s ease",
            }}>{o}</div>
        ))}
      </div>
    </div>
  );
}

/* Setting-Karte — klar tippbar, zeigt Label + aktuellen Wert.
   On/Off-State über Opazität sichtbar.
   Tap → onClick (öffnet existierendes Sheet/Subscreen für dieses Setting). */
function SettingCard({ icon, label, value, on, onClick }) {
  const dim = on === false;
  return (
    <button onClick={onClick} className="press" aria-label={label}
      style={{
        cursor: "pointer", textAlign: "left", width: "100%",
        background: "linear-gradient(180deg, rgba(235,226,214,0.045), rgba(235,226,214,0.015))",
        border: "1px solid rgba(235,226,214,0.08)",
        borderRadius: 16,
        padding: "12px 12px 11px",
        opacity: dim ? 0.45 : 1,
        transition: "opacity 0.25s, background 0.2s, border-color 0.2s",
        display: "flex", flexDirection: "column", alignItems: "center", gap: 7,
        minWidth: 0, color: "inherit", fontFamily: "inherit",
      }}>
      <span style={{
        fontSize: 9.5, letterSpacing: "0.14em", textTransform: "uppercase",
        color: "var(--sm-text-3)", fontWeight: 500,
        textAlign: "center", lineHeight: 1.1,
        overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap", maxWidth: "100%",
      }}>{label}</span>
      <span style={{
        width: 24, height: 24, color: "var(--sm-accent-text)",
        display: "inline-flex", alignItems: "center", justifyContent: "center",
      }}>{icon}</span>
      <span style={{
        fontSize: 12, color: "var(--sm-text-2)",
        fontFamily: "var(--sm-font-display)",
        textAlign: "center", lineHeight: 1.2,
        overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap", maxWidth: "100%",
      }}>{value}</span>
    </button>
  );
}

function TimerConfigStep1({ minutes, setMinutes, dense, onStart, onOpenConfig, activeTab, setActiveTab }) {
  const settings = [
    { key: "prep",     icon: Ic_S1.hourglass, label: "Vorbereitung",
      value: dense.prepOn ? dense.prepDur : "Aus", on: dense.prepOn },
    { key: "intro",    icon: Ic_S1.sparkle,   label: "Einstimmung",
      value: dense.introOn ? dense.intro : "Ohne", on: dense.introOn },
    { key: "ambient",  icon: Ic_S1.wave,      label: "Hintergrund",
      value: dense.ambientOn ? dense.ambient : "Stille", on: dense.ambientOn },
    { key: "gong",     icon: Ic_S1.bell,      label: "Gong",
      value: dense.gong, on: true },
    { key: "interval", icon: Ic_S1.refresh,   label: "Intervall",
      value: dense.intervalOn ? dense.interval : "Aus", on: dense.intervalOn },
  ];
  return (
    <Ph_S1 label="Timer-Konfiguration (Schritt 1)">
      <SB_S1/>
      <div className="screen-content">
        <div style={{ textAlign: "center", padding: "10px 32px 0" }}>
          <div className="h-display" style={{ fontSize: 24, fontWeight: 400 }}>Schön, dass du da bist</div>
        </div>

        {/* Bestehender Number-Picker bleibt — Umstellung auf Atemkreis ist NICHT Teil dieses Schritts */}
        <div style={{ marginTop: 14 }}>
          <ClassicMinutePicker value={minutes} onChange={setMinutes}/>
        </div>
        <div style={{ textAlign: "center", marginTop: 4, fontSize: 11, letterSpacing: "0.06em", color: "var(--sm-text-3)" }}>
          Minuten
        </div>

        {/* NEU: 5 sichtbare Setting-Karten direkt auf dem Konfig-Screen */}
        <div style={{ padding: "20px 18px 0", display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 8 }}>
          {settings.slice(0, 3).map(s => (
            <SettingCard key={s.key} {...s} onClick={() => onOpenConfig?.(s.key)}/>
          ))}
        </div>
        <div style={{ padding: "8px 18px 0", display: "grid", gridTemplateColumns: "1fr 1fr", gap: 8 }}>
          {settings.slice(3).map(s => (
            <SettingCard key={s.key} {...s} onClick={() => onOpenConfig?.(s.key)}/>
          ))}
        </div>
        <div style={{ textAlign: "center", marginTop: 6, fontSize: 10.5, letterSpacing: "0.12em", textTransform: "uppercase", color: "var(--sm-text-3)" }}>
          Tippen, um anzupassen
        </div>

        <div style={{ textAlign: "center", marginTop: 18 }}>
          <button className="btn-primary press" onClick={onStart}>
            <span style={{ width: 18, height: 18, display: "inline-flex" }}>{Ic_S1.play}</span>
            Beginnen
          </button>
        </div>
      </div>
      <TB_S1 active={activeTab} onChange={setActiveTab}/>
    </Ph_S1>
  );
}

/* Vorher-Vergleich: aktueller Idle-Screen mit kryptischen Pillen.
   Nur als Referenz im Handoff — KEINE Implementierungs-Vorlage. */
function TimerConfigBefore({ minutes, setMinutes, dense, onStart, activeTab, setActiveTab }) {
  return (
    <Ph_S1 label="Aktuell (Vorher)">
      <SB_S1/>
      <div className="screen-content">
        <div style={{ textAlign: "center", padding: "10px 32px 0" }}>
          <div className="h-display" style={{ fontSize: 24, fontWeight: 400 }}>Schön, dass du da bist</div>
        </div>
        <div style={{ marginTop: 14 }}>
          <ClassicMinutePicker value={minutes} onChange={setMinutes}/>
        </div>
        <div style={{ textAlign: "center", marginTop: 4, fontSize: 11, letterSpacing: "0.06em", color: "var(--sm-text-3)" }}>
          Minuten
        </div>

        {/* Die kryptischen Pillen — sehen wie Tags aus, sind aber Buttons */}
        <div style={{ display: "flex", justifyContent: "center", gap: 8, marginTop: 24, padding: "0 24px", flexWrap: "wrap" }}>
          {[dense.gong, dense.ambientOn ? dense.ambient : "Stille", dense.intervalOn ? dense.interval : "Aus"].map((p, i) => (
            <span key={i} style={{
              padding: "6px 14px", borderRadius: 999,
              background: "rgba(196,122,94,0.18)",
              color: "var(--sm-text)", fontSize: 12,
              border: "1px solid rgba(196,122,94,0.25)",
            }}>{p}</span>
          ))}
        </div>
        <div style={{ textAlign: "center", marginTop: 6, fontSize: 10.5, letterSpacing: "0.12em", textTransform: "uppercase", color: "var(--sm-text-3)", opacity: 0.6 }}>
          (sehen wie Tags aus — sind aber Buttons)
        </div>

        <div style={{ textAlign: "center", marginTop: 32 }}>
          <button className="btn-primary press" onClick={onStart}>
            <span style={{ width: 18, height: 18, display: "inline-flex" }}>{Ic_S1.play}</span>
            Beginnen
          </button>
        </div>
      </div>
      <TB_S1 active={activeTab} onChange={setActiveTab}/>
    </Ph_S1>
  );
}

window.SM_TimerConfigStep1 = { TimerConfigStep1, TimerConfigBefore };
