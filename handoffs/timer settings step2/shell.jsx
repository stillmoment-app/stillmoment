/* Shared phone shell — status bar, tab bar, common bits. */

const { useState, useEffect, useRef, useMemo, useCallback } = React;

/* --- Status bar --- */
function StatusBar({ time = "09:41" }) {
  return (
    <div className="statusbar">
      <span>{time}</span>
      <div className="icons">
        {/* Signal */}
        <svg width="18" height="12" viewBox="0 0 18 12" fill="none">
          <rect x="0" y="8" width="3" height="4" rx="0.5" fill="#ebe2d6"/>
          <rect x="5" y="6" width="3" height="6" rx="0.5" fill="#ebe2d6"/>
          <rect x="10" y="3" width="3" height="9" rx="0.5" fill="#ebe2d6"/>
          <rect x="15" y="0" width="3" height="12" rx="0.5" fill="#ebe2d6"/>
        </svg>
        {/* Wifi */}
        <svg width="16" height="12" viewBox="0 0 16 12" fill="none">
          <path d="M8 11 L9.5 9.5 A2 2 0 0 0 6.5 9.5 Z" fill="#ebe2d6"/>
          <path d="M8 7 A4.5 4.5 0 0 0 4 9 L5 10 A3.2 3.2 0 0 1 11 10 L12 9 A4.5 4.5 0 0 0 8 7Z" fill="#ebe2d6"/>
          <path d="M8 3 A8.5 8.5 0 0 0 1 6 L2.5 7.5 A6.5 6.5 0 0 1 13.5 7.5 L15 6 A8.5 8.5 0 0 0 8 3Z" fill="#ebe2d6"/>
        </svg>
        {/* Battery (charging) */}
        <svg width="28" height="13" viewBox="0 0 28 13" fill="none">
          <rect x="0.5" y="0.5" width="24" height="12" rx="3" stroke="#ebe2d6" opacity="0.5"/>
          <rect x="2.5" y="2.5" width="14" height="8" rx="1.5" fill="#34c759"/>
          <rect x="26" y="4" width="2" height="5" rx="1" fill="#ebe2d6" opacity="0.5"/>
          <path d="M11 1.5 L7.5 6.5 H10 L9 11.5 L13 6 H10.5 L11.5 1.5 Z" fill="#0a0604"/>
        </svg>
      </div>
    </div>
  );
}

/* --- Tab bar --- */
const TIMER_ICON = (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round">
    <circle cx="12" cy="13" r="8"/>
    <path d="M12 13 L12 9"/>
    <path d="M9 3 H15"/>
  </svg>
);
const MED_ICON = (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round">
    <path d="M5 12 V14"/>
    <path d="M8 9 V17"/>
    <path d="M11 6 V20"/>
    <path d="M14 9 V17"/>
    <path d="M17 11 V15"/>
    <path d="M20 13 V13"/>
  </svg>
);
const SETTINGS_ICON = (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round">
    <path d="M5 7 H19"/>
    <circle cx="9" cy="7" r="2" fill="currentColor"/>
    <path d="M5 17 H19"/>
    <circle cx="15" cy="17" r="2" fill="currentColor"/>
    <path d="M5 12 H19" opacity="0"/>
  </svg>
);

function TabBar({ active, onChange }) {
  const tabs = [
    { id: "timer", label: "Timer", icon: TIMER_ICON },
    { id: "med", label: "Meditationen", icon: MED_ICON },
    { id: "settings", label: "Einstellungen", icon: SETTINGS_ICON },
  ];
  return (
    <div className="tabbar">
      {tabs.map(t => (
        <button
          key={t.id}
          className={`tab ${active === t.id ? "active" : ""}`}
          onClick={() => onChange?.(t.id)}
        >
          {t.icon}
          <span>{t.label}</span>
        </button>
      ))}
    </div>
  );
}

/* --- Phone wrapper --- */
function Phone({ children, label, bare = false }) {
  return (
    <div className={`phone ${bare ? "phone-bare" : ""} bg-vignette`} data-screen-label={label}>
      {children}
    </div>
  );
}

/* --- Icons used across screens --- */
const Icons = {
  bell: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"><path d="M6 16 C6 12 6 8.5 8 7 C9 6.2 10.5 6 12 6 C13.5 6 15 6.2 16 7 C18 8.5 18 12 18 16 H6 Z"/><path d="M10 19 A2 2 0 0 0 14 19"/></svg>,
  wave: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round"><path d="M3 11 C5 11 5 13 7 13 C9 13 9 11 11 11 C13 11 13 13 15 13 C17 13 17 11 19 11 C20 11 20 11 21 11"/><path d="M3 15 C5 15 5 17 7 17 C9 17 9 15 11 15 C13 15 13 17 15 17 C17 17 17 15 19 15 C20 15 20 15 21 15" opacity="0.4"/></svg>,
  refresh: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"><path d="M4 12 A8 8 0 0 1 19 8 L21 6 M21 6 V11 M21 6 H16"/><path d="M20 12 A8 8 0 0 1 5 16" opacity="0.5"/></svg>,
  hourglass: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"><path d="M7 4 H17"/><path d="M7 20 H17"/><path d="M7 4 V7 L12 12 L7 17 V20"/><path d="M17 4 V7 L12 12 L17 17 V20"/></svg>,
  chevR: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M9 6 L15 12 L9 18"/></svg>,
  chevUD: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M8 10 L12 6 L16 10"/><path d="M8 14 L12 18 L16 14"/></svg>,
  chevL: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"><path d="M15 6 L9 12 L15 18"/></svg>,
  plus: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round"><path d="M12 6 V18"/><path d="M6 12 H18"/></svg>,
  play: <svg viewBox="0 0 24 24" fill="currentColor"><path d="M8 5 V19 L19 12 Z"/></svg>,
  edit: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"><path d="M4 20 H8 L18 10 L14 6 L4 16 Z"/><path d="M14 6 L18 10"/></svg>,
  leaf: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"><path d="M5 19 C5 12 9 6 19 5 C18 15 12 19 5 19 Z"/><path d="M5 19 L12 12"/></svg>,
  sparkle: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.4" strokeLinecap="round" strokeLinejoin="round"><path d="M12 4 L13 10 L19 11 L13 12 L12 18 L11 12 L5 11 L11 10 Z"/></svg>,
  moon: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"><path d="M20 14 A8 8 0 1 1 10 4 A6 6 0 0 0 20 14 Z"/></svg>,
  flame: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"><path d="M12 21 C7 21 5 17 6 14 C7 11 9 11 9 8 C9 6 11 5 12 3 C12 7 16 8 17 12 C18 16 16 21 12 21 Z"/></svg>,
};

window.SM = { StatusBar, TabBar, Phone, Icons };
