# Design: ModeBar Mobile-Layout

**Datum:** 2026-05-04
**Status:** Approved

## Ziel

Die ModeBar auf mobilen Screens (≤ 768px) vereinfachen: statt zwei Toggle-Buttons nur einen kontextuellen Button, und das Standort-Feld platzsparend mit flex-wrap.

## Verhalten nach Screen-Größe

### Desktop (> 768px) — unverändert
```
Links:  "Modus:" [Klinik] [Outreach]
Rechts: "Standort:" [input, width:160px]   ← nur im Outreach-Modus
```

### Mobile (≤ 768px) — Klinik-Modus
```
[Outreach]   ← ein Button, wechselt zu Outreach-Modus
```

### Mobile (≤ 768px) — Outreach-Modus
```
flex-wrap-Container:
  [✕] "Outreach-Modus"    ← flex-shrink:0, Klick → wechselt zu Klinik
  "Standort:" [input]      ← flex-shrink:0, bricht bei Platzmangel in zweite Zeile
```

## Dateien

| Aktion | Datei |
|--------|-------|
| Neu | `esm/msi-esm-field-app/src/hooks/useIsMobile.ts` |
| Neu | `esm/msi-esm-field-app/src/hooks/useIsMobile.test.ts` |
| Ändern | `esm/msi-esm-field-app/src/components/ModeBar/ModeBar.tsx` |
| Ändern | `esm/msi-esm-field-app/src/components/ModeBar/ModeBar.test.tsx` |

## `useIsMobile`-Hook

```typescript
// src/hooks/useIsMobile.ts
export function useIsMobile(): boolean
```

- Initialisiert mit `window.matchMedia('(max-width: 768px)').matches`
- Registriert `change`-Listener, gibt State zurück
- SSR-sicher: `typeof window !== 'undefined'`-Check, Fallback `false`
- Cleanup im `useEffect` return

## ModeBar-Änderungen

- `useIsMobile()` am Anfang der Komponente aufrufen
- Desktop-Render-Pfad bleibt unverändert, Standort-Input bekommt `width: 160px` (statt bisherigem `140px`)
- Mobiler Render-Pfad: zwei getrennte Conditional-Blöcke für Klinik- und Outreach-Modus
- Styling inline (konsistent mit bisherigem Code), kein CSS-Modul
