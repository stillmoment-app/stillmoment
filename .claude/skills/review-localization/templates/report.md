# Localization Review Report

**Datum**: {date}
**Scope**: {scope}

---

## Zusammenfassung

| Pruefung | Status | Findings |
|----------|--------|----------|
| Vollstaendigkeit | {status_vollstaendigkeit} | {count_vollstaendigkeit} |
| Cross-Platform | {status_crossplatform} | {count_crossplatform} |
| Ungenutzte Keys | {status_unused} | {count_unused} |
| Accessibility | {status_accessibility} | {count_accessibility} |

**Legende:**
- OK - Keine Probleme gefunden
- Warnung - Nicht-kritische Findings
- Fehler - Kritische Findings die behoben werden sollten

---

## Statistik

### iOS
- **Keys (en)**: {ios_keys_en}
- **Keys (de)**: {ios_keys_de}
- **Parity**: {ios_parity}

### Android
- **Keys (en)**: {android_keys_en}
- **Keys (de)**: {android_keys_de}
- **Parity**: {android_parity}

### Cross-Platform
- **Gemeinsame Keys**: {common_keys}
- **Nur iOS**: {ios_only_keys}
- **Nur Android**: {android_only_keys}

---

## Details

### 1. Vollstaendigkeit

#### iOS - make check-localization
```
{ios_check_output}
```

#### iOS - make validate-localization
```
{ios_validate_output}
```

#### Android - Hardcoded Strings
{android_hardcoded_findings}

#### Android - Key Parity
{android_parity_findings}

---

### 2. Cross-Platform Differenzen

#### Keys nur in iOS (ohne Android-Aequivalent)
{ios_only_keys_list}

#### Keys nur in Android (ohne iOS-Aequivalent)
{android_only_keys_list}

#### Inhaltliche Inkonsistenzen
{content_inconsistencies}

---

### 3. Ungenutzte Keys

#### iOS - Moeglicherweise ungenutzt
{ios_unused_keys}

#### Android - Moeglicherweise ungenutzt
{android_unused_keys}

---

### 4. Accessibility-Konsistenz

#### iOS
{ios_accessibility_findings}

#### Android
{android_accessibility_findings}

---

## Empfehlungen

### Kritisch (sollte vor Release behoben werden)
{critical_recommendations}

### Mittel (sollte zeitnah behoben werden)
{medium_recommendations}

### Gering (bei Gelegenheit)
{low_recommendations}

---

*Report generiert mit `/review-localization` Skill*
