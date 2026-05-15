/* Import — "Meditation bearbeiten" Screen
   Verbesserungen ggü. aktuellem Production-Screen:
   - Header trunkiert nicht mehr ("Meditation b…" → "Meditation bearbeiten")
   - Name-Feld zeigt keine UUID mehr als Default
   - "Unknown Artist" raus
   - Datei-Informationen kompakt (kein doppelter Dateiname)
   - Speichern visuell gedimmt solange Name leer ist
   - Prefill-Kaskade:
       1. ID3-Tags (TPE1 → Lehrer:in, TIT2 → Titel) — falls vorhanden
       2. Dateiname enthält bekannte:n Lehrer:in → extrahiert + Rest als Titel
       3. Dateiname parsebar → als Titel-Vorschlag
       4. Dateiname ist Müll (UUID, Hex, …) → beides leer
   - Lehrer-Autocomplete zeigt Anzahl + zuletzt verwendet
   (Audio-Preview wird als dediziertes Feature behandelt, nicht hier.) */

const { useState: useStateIE, useRef: useRefIE } = React;
const { StatusBar: SBIE, Phone: PhIE, Icons: IconsIE } = window.SM;

/* ---------- Icons ---------- */

const PersonIcon = (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round">
    <circle cx="12" cy="8" r="4"/>
    <path d="M4 20 C4 16 7 14 12 14 C17 14 20 16 20 20"/>
  </svg>
);
const InfoDot = (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round">
    <circle cx="12" cy="12" r="9"/>
    <path d="M12 11 V17"/>
    <circle cx="12" cy="7.6" r="0.6" fill="currentColor"/>
  </svg>
);

/* ---------- Reusable bits ---------- */

function NavBar({ title, canSave = true, onCancel = () => {}, onSave = () => {} }) {
  return (
    <div style={{
      display: "flex", alignItems: "center", justifyContent: "space-between",
      padding: "8px 18px 12px",
      borderBottom: "1px solid rgba(235,226,214,0.05)",
      position: "relative", height: 44,
    }}>
      <button onClick={onCancel} className="press" style={{
        background: "none", border: "none", color: "var(--sm-accent-text)",
        fontFamily: "inherit", fontSize: 15, padding: "6px 0", cursor: "pointer",
      }}>
        Abbrechen
      </button>
      <div style={{
        position: "absolute", left: "50%", top: "50%",
        transform: "translate(-50%, -50%)",
        fontFamily: "var(--sm-font-display)", fontSize: 17, color: "var(--sm-text)",
        letterSpacing: "0.01em", whiteSpace: "nowrap",
      }}>
        {title}
      </div>
      <button onClick={onSave} disabled={!canSave} className="press" style={{
        background: "none", border: "none",
        color: canSave ? "var(--sm-accent-text)" : "var(--sm-text-3)",
        opacity: canSave ? 1 : 0.45,
        fontFamily: "inherit", fontSize: 15, fontWeight: 500, padding: "6px 0",
        cursor: canSave ? "pointer" : "default",
      }}>
        Speichern
      </button>
    </div>
  );
}

function FieldCard({ label, children, hint }) {
  return (
    <div style={{
      background: "var(--sm-card)",
      border: "1px solid var(--sm-card-line)",
      borderRadius: 18,
      padding: "14px 16px 12px",
      position: "relative",
    }}>
      <div style={{
        fontSize: 11, letterSpacing: "0.12em", textTransform: "uppercase",
        color: "var(--sm-text-3)", fontWeight: 500, marginBottom: 8,
      }}>
        {label}
      </div>
      {children}
      {hint && (
        <div style={{ fontSize: 11.5, color: "var(--sm-text-3)", marginTop: 8, lineHeight: 1.45 }}>
          {hint}
        </div>
      )}
    </div>
  );
}

function PlainInput({ value, onChange, placeholder, focused = false, dim = false }) {
  // iOS-style clear button (×) appears when field has content. Saves
  // the user from select-all + delete on a soft keyboard when they want
  // to throw away a prefill.
  return (
    <div style={{
      display: "flex", alignItems: "center", gap: 10,
    }}>
      <input
        autoFocus={focused}
        type="text"
        value={value}
        onChange={(e) => onChange?.(e.target.value)}
        placeholder={placeholder}
        style={{
          flex: 1, minWidth: 0,
          background: "transparent", border: "none", outline: "none",
          color: dim ? "var(--sm-text-2)" : "var(--sm-text)",
          fontFamily: "var(--sm-font-display)", fontSize: 18,
          padding: 0,
        }}
      />
      {value && (
        <button onClick={() => onChange?.("")} className="press" aria-label="Löschen" style={{
          flexShrink: 0,
          width: 20, height: 20, borderRadius: "50%",
          background: "rgba(235,226,214,0.18)", border: "none",
          color: "#1a0e0a",
          display: "inline-flex", alignItems: "center", justifyContent: "center",
          cursor: "pointer", padding: 0,
        }}>
          <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round">
            <path d="M6 6 L18 18"/><path d="M18 6 L6 18"/>
          </svg>
        </button>
      )}
    </div>
  );
}

function FileFooter({ name, dur, size }) {
  return (
    <div style={{
      display: "flex", alignItems: "center", gap: 8,
      padding: "10px 4px 0",
      fontSize: 11, color: "var(--sm-text-3)",
      fontFeatureSettings: '"tnum"',
    }}>
      <span style={{ width: 12, height: 12, color: "var(--sm-text-3)", flexShrink: 0 }}>{InfoDot}</span>
      <span style={{
        overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap", flex: 1, minWidth: 0,
      }}>
        {name}
      </span>
      <span style={{ flexShrink: 0 }}>{dur}{size ? ` · ${size}` : ""}</span>
    </div>
  );
}

/* ---------- Core EditMeta component ---------- */
/* Single form that takes a `prefill` describing what we found in the file.
   The form's defaults derive from it. No source badges — if the prefilled
   value is wrong, the user taps the × to clear and retypes. */

function EditMeta({ prefill, label, filename, dur = "16:30", size = "22,8 MB" }) {
  const [teacher, setTeacher] = useStateIE(prefill?.teacher ?? "");
  const [name, setName]       = useStateIE(prefill?.name ?? "");
  const canSave = name.trim().length > 0;

  return (
    <PhIE label={label}>
      <SBIE/>
      <NavBar title="Meditation bearbeiten" canSave={canSave}/>

      <div style={{ padding: "20px 18px 18px", display: "flex", flexDirection: "column", gap: 14 }}>
        <FieldCard label="Lehrer:in">
          <PlainInput value={teacher} onChange={setTeacher}
            placeholder="z.B. Tara Brach"/>
        </FieldCard>

        <FieldCard label="Name der Meditation">
          <PlainInput value={name} onChange={setName}
            placeholder="Tippe einen Namen…"
            focused={!prefill?.name}/>
        </FieldCard>

        <FileFooter name={filename} dur={dur} size={size}/>
      </div>
    </PhIE>
  );
}

/* ---------- Scenario wrappers ---------- */

/* 1. Best case — file has ID3 tags. Both fields filled. */
function EditMeta_ID3() {
  return (
    <EditMeta
      label="Edit · 1. ID3-Tags vorhanden (Bestfall)"
      filename="bodyscan-mbsr.mp3"
      prefill={{
        source: "id3",
        teacher: "Tara Brach",
        name: "Body Scan — MBSR",
      }}
    />
  );
}

/* 2. No ID3 — but filename contains a known teacher.
   "bodyscan-tara_brach.mp3"  →  Lehrer: Tara Brach,  Titel: Bodyscan */
function EditMeta_TeacherInFilename() {
  return (
    <EditMeta
      label="Edit · 2. Lehrer:in im Dateinamen erkannt (Bonus)"
      filename="bodyscan-tara_brach.mp3"
      prefill={{
        source: "teacherInFilename",
        teacher: "Tara Brach",
        name: "Bodyscan",
      }}
    />
  );
}

/* 3. No ID3, no teacher match — but filename is parseable.
   "anleitung-bodyscan-deutsch-mbsr.mp3"  →  Titel: Anleitung Bodyscan Deutsch MBSR */
function EditMeta_FilenameOnly() {
  return (
    <EditMeta
      label="Edit · 3. Nur Titel aus Dateiname"
      filename="anleitung-bodyscan-deutsch-mbsr.mp3"
      prefill={{
        source: "filename",
        teacher: "",
        name: "Anleitung Bodyscan Deutsch MBSR",
      }}
    />
  );
}

/* 4. Garbage filename — UUID-style, no ID3. Both fields empty. */
function EditMeta_GarbageFilename() {
  return (
    <EditMeta
      label="Edit · 4. Müll-Dateiname → beides leer"
      filename="d067c0ea-2c04-b934-1e04-94b2dc2f13dd.mp3"
      prefill={{
        source: "none",
        teacher: "",
        name: "",
      }}
    />
  );
}

/* 5. Autocomplete focus — show the dropdown with rich suggestions */

function HighlightMatch({ text, query }) {
  if (!query) return <>{text}</>;
  const idx = text.toLowerCase().indexOf(query.toLowerCase());
  if (idx < 0) return <>{text}</>;
  return (
    <>
      {text.slice(0, idx)}
      <span style={{ color: "var(--sm-accent-text)", fontWeight: 500 }}>
        {text.slice(idx, idx + query.length)}
      </span>
      {text.slice(idx + query.length)}
    </>
  );
}

function EditMeta_Autocomplete() {
  const [teacher, setTeacher] = useStateIE("T");
  const [name, setName]       = useStateIE("");
  const canSave = name.trim().length > 0;
  const known = [
    { name: "Tara Brach",        count: 12, last: "Gestern" },
    { name: "Thich Nhat Hanh",   count: 5,  last: "Letzte Woche" },
    { name: "Tilmann Lhündrup",  count: 3,  last: "vor 3 Wochen" },
  ];
  const q = teacher.trim().toLowerCase();
  const matches = q ? known.filter(t => t.name.toLowerCase().includes(q)) : known;

  return (
    <PhIE label="Edit · 5. Lehrer-Autocomplete (offen, beim Tippen)">
      <SBIE/>
      <NavBar title="Meditation bearbeiten" canSave={canSave}/>

      <div style={{ padding: "16px 18px 18px", display: "flex", flexDirection: "column", gap: 12 }}>
        <FieldCard label="Lehrer:in">
          <PlainInput value={teacher} onChange={setTeacher}
            placeholder="z.B. Tara Brach"
            focused/>

          <div style={{
            marginTop: 12,
            marginLeft: -16, marginRight: -16, marginBottom: -12,
            borderTop: "1px solid rgba(235,226,214,0.07)",
            background: "rgba(0,0,0,0.18)",
            borderBottomLeftRadius: 18, borderBottomRightRadius: 18,
            overflow: "hidden",
          }}>
            {matches.map((t, i) => (
              <button key={t.name} onClick={() => setTeacher(t.name)} className="press" style={{
                width: "100%",
                display: "flex", alignItems: "center", gap: 12,
                padding: "12px 16px",
                background: "transparent", border: "none",
                borderTop: i === 0 ? "none" : "1px solid rgba(235,226,214,0.04)",
                color: "var(--sm-text)", textAlign: "left", cursor: "pointer",
                fontFamily: "inherit",
              }}>
                <span style={{
                  width: 28, height: 28, borderRadius: "50%",
                  background: "rgba(235,226,214,0.05)", color: "var(--sm-text-2)",
                  display: "inline-flex", alignItems: "center", justifyContent: "center",
                  flexShrink: 0,
                }}>
                  <span style={{ width: 14, height: 14 }}>{PersonIcon}</span>
                </span>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontSize: 14, fontFamily: "var(--sm-font-display)" }}>
                    <HighlightMatch text={t.name} query={teacher}/>
                  </div>
                  <div style={{ fontSize: 11, color: "var(--sm-text-3)", marginTop: 2 }}>
                    {t.count} {t.count === 1 ? "Meditation" : "Meditationen"} · zuletzt {t.last}
                  </div>
                </div>
              </button>
            ))}
            {q && !matches.find(t => t.name.toLowerCase() === q) && (
              <button onClick={() => {}} className="press" style={{
                width: "100%",
                display: "flex", alignItems: "center", gap: 12,
                padding: "12px 16px",
                background: "transparent", border: "none",
                borderTop: "1px solid rgba(235,226,214,0.04)",
                color: "var(--sm-accent-text)", textAlign: "left", cursor: "pointer",
                fontFamily: "inherit", fontSize: 13,
              }}>
                <span style={{ width: 14, height: 14, flexShrink: 0 }}>{IconsIE.plus}</span>
                <span>„{teacher}" als neue:n Lehrer:in anlegen</span>
              </button>
            )}
          </div>
        </FieldCard>

        <FieldCard label="Name der Meditation">
          <PlainInput value={name} onChange={setName} placeholder="Tippe einen Namen…"/>
        </FieldCard>
      </div>
    </PhIE>
  );
}

window.SM_EditMeta = {
  EditMeta_ID3,
  EditMeta_TeacherInFilename,
  EditMeta_FilenameOnly,
  EditMeta_GarbageFilename,
  EditMeta_Autocomplete,
};
