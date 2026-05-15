/* Still Moment — Danke-Screen FINAL
   Entscheidung:
   - Glow-Kreis (Atem-Vokabular der App, kein Herz-Icon)
   - „Danke, dass du dir diesen Moment genommen hast."
   - „Fertig"-Button
   - Keine Subline, keine Zahlen, keine Stats — funktioniert für geführt + frei.
*/

const SM_BG = "radial-gradient(ellipse 90% 70% at 50% 35%, #3a201a 0%, #2a1610 38%, #190c08 72%, #110705 100%)";

function StatusBar() {
  const c = "#ebe2d6";
  return (
    <div style={{
      position: "absolute", top: 0, left: 0, right: 0, height: 54,
      padding: "18px 32px 0", display: "flex", alignItems: "center",
      justifyContent: "space-between",
      fontFamily: '-apple-system, "SF Pro Text", system-ui, sans-serif',
      fontWeight: 600, fontSize: 17, color: c, zIndex: 5,
    }}>
      <span>17:52</span>
      <div style={{ display: "flex", gap: 6, alignItems: "center" }}>
        <svg width="18" height="11" viewBox="0 0 18 11" fill="none">
          <rect x="0" y="6" width="3" height="5" rx="1" fill={c}/>
          <rect x="5" y="3" width="3" height="8" rx="1" fill={c}/>
          <rect x="10" y="0" width="3" height="11" rx="1" fill={c} opacity="0.4"/>
          <rect x="15" y="0" width="3" height="11" rx="1" fill={c} opacity="0.4"/>
        </svg>
        <svg width="16" height="12" viewBox="0 0 16 12" fill="none">
          <path d="M8 11.5L1 4.5C5 0.5 11 0.5 15 4.5L8 11.5Z" stroke={c} strokeWidth="1.5" fill="none"/>
        </svg>
        <div style={{ display: "inline-flex", alignItems: "center", gap: 3 }}>
          <span style={{ fontSize: 11, fontWeight: 700 }}>72</span>
          <div style={{ width: 24, height: 12, borderRadius: 3, border: `1.2px solid ${c}`, padding: 1.5, opacity: 0.85 }}>
            <div style={{ width: "72%", height: "100%", background: "#fff", borderRadius: 1 }}/>
          </div>
        </div>
      </div>
    </div>
  );
}

/* Glow-Kreis — statisch. Die Sitzung ist vorbei, also kein Pulsieren.
   Stattdessen ein ruhiges, nachglimmendes Licht. */
function GlowOrb() {
  return (
    <div style={{
      position: "relative", width: 180, height: 180,
      display: "flex", alignItems: "center", justifyContent: "center",
    }}>
      {/* äusserer weicher Halo */}
      <div style={{
        position: "absolute", inset: 0, borderRadius: "50%",
        background: "radial-gradient(circle at 50% 50%, rgba(217,154,126,0.22), rgba(196,122,94,0.05) 55%, transparent 78%)",
      }}/>
      {/* innerer warmer Kern */}
      <div style={{
        width: 96, height: 96, borderRadius: "50%",
        background: "radial-gradient(circle at 50% 45%, rgba(232,178,148,0.9), rgba(217,154,126,0.55) 38%, rgba(196,122,94,0.18) 68%, transparent 88%)",
        boxShadow: "0 0 70px 10px rgba(217,154,126,0.22)",
      }}/>
    </div>
  );
}

function DankeFinal() {
  return (
    <div style={{
      width: 393, height: 852, position: "relative", overflow: "hidden",
      borderRadius: 48, background: SM_BG, isolation: "isolate",
    }}>
      <StatusBar/>

      <div style={{
        position: "absolute", inset: 0,
        display: "flex", flexDirection: "column",
        alignItems: "center", justifyContent: "center",
        padding: "0 40px", textAlign: "center",
      }}>
        <div style={{ marginBottom: 44 }}>
          <GlowOrb/>
        </div>

        <div style={{
          fontFamily: "var(--sm-font-display)", fontWeight: 400,
          fontSize: 28, lineHeight: 1.3,
          color: "#ebe2d6",
          letterSpacing: "-0.005em",
          maxWidth: 320,
          textWrap: "balance",
        }}>
          Danke, dass du dir diesen<br/>Moment genommen hast.
        </div>

        <button style={{
          marginTop: 92,
          padding: "16px 56px", borderRadius: 999,
          background: "linear-gradient(180deg,#d68a6e,#b06a4f)",
          color: "#1a0d09", border: "none",
          fontFamily: "var(--sm-font-ui)", fontSize: 17, fontWeight: 600,
          boxShadow: "0 16px 40px -12px rgba(196,122,94,0.5)",
          cursor: "pointer", letterSpacing: "0.01em",
        }}>Fertig</button>
      </div>
    </div>
  );
}

/* Vergleichs-Card: vorher / nachher */
function ComparePanel() {
  return (
    <div style={{
      display: "flex", flexDirection: "column", alignItems: "center", gap: 14,
    }}>
      <div style={{
        width: 393, height: 852, position: "relative", overflow: "hidden",
        borderRadius: 48,
        background: "radial-gradient(ellipse 100% 80% at 50% 60%, #4a2a20 0%, #3a221c 30%, #2a1812 60%, #1a0d09 100%)",
        isolation: "isolate",
      }}>
        <StatusBar/>
        <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", padding: "0 40px", textAlign: "center" }}>
          <div style={{
            width: 96, height: 96, borderRadius: "50%",
            background: "rgba(196,122,94,0.18)",
            display: "inline-flex", alignItems: "center", justifyContent: "center",
            marginBottom: 28,
          }}>
            <svg width="40" height="40" viewBox="0 0 24 24" fill="#c47a5e">
              <path d="M12 21s-7-4.5-9.5-9.5C1 7.5 4 4 7.5 4c2 0 3.5 1 4.5 2.5C13 5 14.5 4 16.5 4 20 4 23 7.5 21.5 11.5 19 16.5 12 21 12 21z"/>
            </svg>
          </div>
          <div style={{ fontFamily: "var(--sm-font-display)", fontWeight: 400, fontSize: 32, color: "#ebe2d6" }}>
            Vielen Dank
          </div>
          <div style={{ marginTop: 14, fontSize: 15, color: "rgba(168,154,140,0.8)", lineHeight: 1.5, maxWidth: 280 }}>
            Schön, dass du dir diese<br/>Zeit genommen hast.
          </div>
          <button style={{
            marginTop: 80,
            padding: "16px 56px", borderRadius: 999,
            background: "linear-gradient(180deg,#d68a6e,#b06a4f)",
            color: "#1a0d09", border: "none",
            fontFamily: "var(--sm-font-ui)", fontSize: 17, fontWeight: 600,
            boxShadow: "0 16px 40px -12px rgba(196,122,94,0.5)",
            cursor: "pointer",
          }}>Zurück</button>
        </div>
      </div>
      <div style={{ fontFamily: "var(--sm-font-display)", fontSize: 19, color: "#ebe2d6" }}>vorher</div>
    </div>
  );
}

function FinalPanel() {
  return (
    <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 14 }}>
      <DankeFinal/>
      <div style={{ fontFamily: "var(--sm-font-display)", fontSize: 19, color: "#ebe2d6" }}>nachher</div>
    </div>
  );
}

function NoteCard() {
  return (
    <div style={{
      width: 360, padding: "26px 28px",
      borderRadius: 24,
      background: "#fef4a8",
      color: "#5a4a2a",
      fontFamily: "var(--sm-font-ui)",
      boxShadow: "0 18px 36px -20px rgba(0,0,0,0.25)",
      lineHeight: 1.55, fontSize: 13.5,
    }}>
      <div style={{ fontSize: 12, letterSpacing: "0.22em", textTransform: "uppercase", marginBottom: 12, opacity: 0.7 }}>
        Was sich geändert hat
      </div>
      <ul style={{ paddingLeft: 18, margin: 0, display: "flex", flexDirection: "column", gap: 10 }}>
        <li><strong>Herz-Icon</strong> raus → ruhig pulsierender <strong>Glow-Kreis</strong> (dasselbe Atem-Vokabular wie der Sitzungs-Anfang)</li>
        <li><strong>„Vielen Dank"</strong> → <strong>„Danke, dass du dir diesen Moment genommen hast."</strong> Aktive, warme Aussage statt transaktionale Floskel</li>
        <li>Subline gestrichen — der eine Satz trägt allein</li>
        <li><strong>Zurück</strong> → <strong>Fertig</strong>. Wärmerer Abschluss, kein Rückzugs-Wording</li>
        <li>Keine Zahlen, keine Streaks. Identisch nach geführter wie freier Sitzung</li>
      </ul>
    </div>
  );
}

function App() {
  return (
    <DesignCanvas
      title="Danke-Screen · Final"
      subtitle="Glow-Kreis · eine warme Botschaft · Fertig-Button. Funktioniert für geführte und freie Meditation."
    >
      <DCSection id="ba" title="Vorher / Nachher">
        <DCArtboard id="before" label="0 · Heute"  width={420} height={910}><ComparePanel/></DCArtboard>
        <DCArtboard id="after"  label="Final"      width={420} height={910}><FinalPanel/></DCArtboard>
        <DCArtboard id="note"   label="Änderungen" width={400} height={360}><NoteCard/></DCArtboard>
      </DCSection>
    </DesignCanvas>
  );
}

ReactDOM.createRoot(document.getElementById("root")).render(<App/>);
