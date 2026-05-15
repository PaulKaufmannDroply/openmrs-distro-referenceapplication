# Design: ModeBar — Sichtbarer Moduswechsel unter der Navbar

**Datum:** 2026-05-03
**Status:** Approved

## Ziel

Den Moduswechsel (Klinik / Outreach) und die Standortauswahl prominenter machen: als dauerhaft sichtbare, farblich abgehobene Leiste direkt unterhalb der Navbar.

## Entscheidungen

- Layout: Toggle links, Standort-Feld erscheint rechts nur im Outreach-Modus (Option A)
- Implementierung: Neue einzelne `ModeBar`-Komponente, ersetzt beide bisherigen Komponenten (Ansatz 1)
- ModeSelector wird aus dem `top-nav-actions-slot` entfernt
- Kein Emoji im UI

## Komponenten-Architektur

### Neu

- `src/components/ModeBar/ModeBar.tsx` — kombinierter Toggle + Standort-Input
- `src/components/ModeBar/ModeBar.test.tsx`

### Entfernt

- `src/components/ModeSelector/ModeSelector.tsx` + Test
- `src/components/OutreachBanner/OutreachBanner.tsx` + Test

### Geändert

- `src/index.ts` — `modeBar` Export statt `modeSelector` + `outreachBanner`
- `frontend/routes.registry.json` (im Distro-Repo) — ein Extension-Eintrag statt zwei

## ModeBar-Komponente

```
ModeBar (immer sichtbar, full-width)
Styling: background #0f62fe, color #fff, height ~2.25rem, padding 0 1rem

Links: "Modus:" Label + Klinik-Button + Outreach-Button
  Aktiver Modus   → weißer Hintergrund, blauer Text
  Inaktiver Modus → halbtransparenter weißer Hintergrund, weißer Text

Rechts (nur wenn mode === 'outreach'):
  "Standort:" Label
  <input list="..."> mit <datalist> aus outreachLocations-Config
    Styling: weißer Border, weißer Text (passend zum blauen Hintergrund)
    Verhalten: onBlur → setOutreachLocation() (wie bisher OutreachBanner)
```

Hooks: `useAppMode()`, `useConfig<Config>()`, `useModeConfigSync()` (wie bisher im ModeSelector).

Styling: inline CSS (konsistent mit bisherigem Projekt-Stil), kein CSS-Modul.

## Registrierung

**Vorher (`routes.registry.json`):**
```json
{ "name": "MSI Mode Selector", "component": "modeSelector", "slot": "top-nav-actions-slot" },
{ "name": "MSI Outreach Banner", "component": "outreachBanner", "slot": "breadcrumbs-slot" }
```

**Nachher:**
```json
{ "name": "MSI Mode Bar", "component": "modeBar", "slot": "breadcrumbs-slot" }
```

## Betroffene Repos

- `esm/msi-esm-field-app` — Komponenten + index.ts
- `o3/openmrs-distro-referenceapplication` — routes.registry.json
