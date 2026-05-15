# ModeBar Mobile-Layout Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Responsive ModeBar — auf Mobile (≤ 768px) im Klinik-Modus nur "Outreach"-Button, im Outreach-Modus ✕ + "Outreach-Modus"-Label + Standort-Input mit flex-wrap.

**Architecture:** Neuer `useIsMobile`-Hook (matchMedia, useState, useEffect). ModeBar bekommt zwei getrennte Render-Pfade: Desktop (unverändert) und Mobile (konditionell nach Modus). Desktop-Standort-Input bekommt feste Breite 160px.

**Tech Stack:** TypeScript, React 18, Jest + @testing-library/react, inline CSS

---

## File Map

| Aktion | Datei |
|--------|-------|
| Neu | `esm/msi-esm-field-app/src/hooks/useIsMobile.ts` |
| Neu | `esm/msi-esm-field-app/src/hooks/useIsMobile.test.ts` |
| Ändern | `esm/msi-esm-field-app/src/components/ModeBar/ModeBar.tsx` |
| Ändern | `esm/msi-esm-field-app/src/components/ModeBar/ModeBar.test.tsx` |

---

### Task 1: `useIsMobile`-Hook

**Files:**
- Create: `esm/msi-esm-field-app/src/hooks/useIsMobile.test.ts`
- Create: `esm/msi-esm-field-app/src/hooks/useIsMobile.ts`

- [ ] **Step 1: Failing tests schreiben**

```typescript
// esm/msi-esm-field-app/src/hooks/useIsMobile.test.ts
import { renderHook, act } from '@testing-library/react';

function createMatchMedia(matches: boolean) {
  const listeners: Array<(e: { matches: boolean }) => void> = [];
  return {
    matches,
    addEventListener: (_: string, cb: (e: { matches: boolean }) => void) => listeners.push(cb),
    removeEventListener: jest.fn(),
    trigger: (m: boolean) => listeners.forEach((cb) => cb({ matches: m })),
  };
}

describe('useIsMobile', () => {
  it('returns true when media query matches (<=768px)', () => {
    const mq = createMatchMedia(true);
    window.matchMedia = jest.fn(() => mq as unknown as MediaQueryList);
    const { useIsMobile } = require('./useIsMobile');
    const { result } = renderHook(() => useIsMobile());
    expect(result.current).toBe(true);
  });

  it('returns false when media query does not match (>768px)', () => {
    const mq = createMatchMedia(false);
    window.matchMedia = jest.fn(() => mq as unknown as MediaQueryList);
    const { useIsMobile } = require('./useIsMobile');
    const { result } = renderHook(() => useIsMobile());
    expect(result.current).toBe(false);
  });

  it('updates state when media query changes', () => {
    const mq = createMatchMedia(false);
    window.matchMedia = jest.fn(() => mq as unknown as MediaQueryList);
    const { useIsMobile } = require('./useIsMobile');
    const { result } = renderHook(() => useIsMobile());
    expect(result.current).toBe(false);
    act(() => mq.trigger(true));
    expect(result.current).toBe(true);
  });
});
```

- [ ] **Step 2: Tests laufen lassen — müssen fehlschlagen**

```bash
cd /Users/paulkaufmann/mvi/esm/msi-esm-field-app && yarn test useIsMobile --no-coverage 2>&1 | tail -10
```

Expected: `Cannot find module './useIsMobile'`

- [ ] **Step 3: Hook implementieren**

```typescript
// esm/msi-esm-field-app/src/hooks/useIsMobile.ts
import { useState, useEffect } from 'react';

export function useIsMobile(): boolean {
  const [isMobile, setIsMobile] = useState<boolean>(
    typeof window !== 'undefined' ? window.matchMedia('(max-width: 768px)').matches : false,
  );

  useEffect(() => {
    if (typeof window === 'undefined') return;
    const mq = window.matchMedia('(max-width: 768px)');
    const handler = (e: MediaQueryListEvent) => setIsMobile(e.matches);
    mq.addEventListener('change', handler);
    return () => mq.removeEventListener('change', handler);
  }, []);

  return isMobile;
}
```

- [ ] **Step 4: Tests laufen lassen — müssen alle 3 bestehen**

```bash
cd /Users/paulkaufmann/mvi/esm/msi-esm-field-app && yarn test useIsMobile --no-coverage 2>&1 | tail -10
```

Expected: `Tests: 3 passed, 3 total`

- [ ] **Step 5: Commit**

```bash
cd /Users/paulkaufmann/mvi/esm/msi-esm-field-app && git add src/hooks/useIsMobile.ts src/hooks/useIsMobile.test.ts && git commit -m "feat: add useIsMobile hook (matchMedia 768px breakpoint)"
```

---

### Task 2: ModeBar mit Mobile-Layout aktualisieren

**Files:**
- Modify: `esm/msi-esm-field-app/src/components/ModeBar/ModeBar.test.tsx`
- Modify: `esm/msi-esm-field-app/src/components/ModeBar/ModeBar.tsx`

- [ ] **Step 1: Tests aktualisieren — Mobile-Fälle hinzufügen + `useIsMobile` mocken**

Ersetze den gesamten Inhalt von `esm/msi-esm-field-app/src/components/ModeBar/ModeBar.test.tsx`:

```tsx
import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';

const mockSetMode = jest.fn();
const mockSetOutreachLocation = jest.fn();

jest.mock('../../hooks/useAppMode', () => ({ useAppMode: jest.fn() }));
jest.mock('../../hooks/useModeConfigSync', () => ({ useModeConfigSync: jest.fn() }));
jest.mock('../../hooks/useIsMobile', () => ({ useIsMobile: jest.fn() }));
jest.mock('@openmrs/esm-framework', () => ({
  useConfig: jest.fn(() => ({ outreachLocations: ['Dorf Nord', 'Grenzcamp Süd'] })),
}));

const { useAppMode } = require('../../hooks/useAppMode');
const { useIsMobile } = require('../../hooks/useIsMobile');

describe('ModeBar', () => {
  beforeEach(() => jest.clearAllMocks());

  describe('Desktop (isMobile=false)', () => {
    beforeEach(() => useIsMobile.mockReturnValue(false));

    it('renders Klinik and Outreach buttons', () => {
      useAppMode.mockReturnValue({ mode: 'clinic', outreachLocation: null, setMode: mockSetMode, setOutreachLocation: mockSetOutreachLocation });
      const { ModeBar } = require('./ModeBar');
      render(<ModeBar />);
      expect(screen.getByRole('button', { name: /klinik/i })).toBeInTheDocument();
      expect(screen.getByRole('button', { name: /outreach/i })).toBeInTheDocument();
    });

    it('does not show standort input in clinic mode', () => {
      useAppMode.mockReturnValue({ mode: 'clinic', outreachLocation: null, setMode: mockSetMode, setOutreachLocation: mockSetOutreachLocation });
      const { ModeBar } = require('./ModeBar');
      render(<ModeBar />);
      expect(screen.queryByPlaceholderText(/standort/i)).not.toBeInTheDocument();
    });

    it('shows standort input in outreach mode', () => {
      useAppMode.mockReturnValue({ mode: 'outreach', outreachLocation: null, setMode: mockSetMode, setOutreachLocation: mockSetOutreachLocation });
      const { ModeBar } = require('./ModeBar');
      render(<ModeBar />);
      expect(screen.getByPlaceholderText(/standort/i)).toBeInTheDocument();
    });

    it('shows current outreachLocation in standort input', () => {
      useAppMode.mockReturnValue({ mode: 'outreach', outreachLocation: 'Dorf Nord', setMode: mockSetMode, setOutreachLocation: mockSetOutreachLocation });
      const { ModeBar } = require('./ModeBar');
      render(<ModeBar />);
      expect(screen.getByDisplayValue('Dorf Nord')).toBeInTheDocument();
    });

    it('calls setMode("clinic") when Klinik clicked', () => {
      useAppMode.mockReturnValue({ mode: 'outreach', outreachLocation: null, setMode: mockSetMode, setOutreachLocation: mockSetOutreachLocation });
      const { ModeBar } = require('./ModeBar');
      render(<ModeBar />);
      fireEvent.click(screen.getByRole('button', { name: /klinik/i }));
      expect(mockSetMode).toHaveBeenCalledWith('clinic');
    });

    it('calls setMode("outreach") when Outreach clicked', () => {
      useAppMode.mockReturnValue({ mode: 'clinic', outreachLocation: null, setMode: mockSetMode, setOutreachLocation: mockSetOutreachLocation });
      const { ModeBar } = require('./ModeBar');
      render(<ModeBar />);
      fireEvent.click(screen.getByRole('button', { name: /outreach/i }));
      expect(mockSetMode).toHaveBeenCalledWith('outreach');
    });

    it('calls setOutreachLocation on blur when value changed', () => {
      useAppMode.mockReturnValue({ mode: 'outreach', outreachLocation: null, setMode: mockSetMode, setOutreachLocation: mockSetOutreachLocation });
      const { ModeBar } = require('./ModeBar');
      render(<ModeBar />);
      const input = screen.getByPlaceholderText(/standort/i);
      fireEvent.change(input, { target: { value: 'Grenzcamp Süd' } });
      fireEvent.blur(input);
      expect(mockSetOutreachLocation).toHaveBeenCalledWith('Grenzcamp Süd');
    });
  });

  describe('Mobile (isMobile=true)', () => {
    beforeEach(() => useIsMobile.mockReturnValue(true));

    it('shows only Outreach button in clinic mode', () => {
      useAppMode.mockReturnValue({ mode: 'clinic', outreachLocation: null, setMode: mockSetMode, setOutreachLocation: mockSetOutreachLocation });
      const { ModeBar } = require('./ModeBar');
      render(<ModeBar />);
      expect(screen.getByRole('button', { name: /outreach/i })).toBeInTheDocument();
      expect(screen.queryByRole('button', { name: /klinik/i })).not.toBeInTheDocument();
    });

    it('calls setMode("outreach") when Outreach button tapped on mobile', () => {
      useAppMode.mockReturnValue({ mode: 'clinic', outreachLocation: null, setMode: mockSetMode, setOutreachLocation: mockSetOutreachLocation });
      const { ModeBar } = require('./ModeBar');
      render(<ModeBar />);
      fireEvent.click(screen.getByRole('button', { name: /outreach/i }));
      expect(mockSetMode).toHaveBeenCalledWith('outreach');
    });

    it('shows X button and Outreach-Modus label in outreach mode', () => {
      useAppMode.mockReturnValue({ mode: 'outreach', outreachLocation: null, setMode: mockSetMode, setOutreachLocation: mockSetOutreachLocation });
      const { ModeBar } = require('./ModeBar');
      render(<ModeBar />);
      expect(screen.getByRole('button', { name: '✕' })).toBeInTheDocument();
      expect(screen.getByText(/outreach-modus/i)).toBeInTheDocument();
    });

    it('shows standort input in outreach mode on mobile', () => {
      useAppMode.mockReturnValue({ mode: 'outreach', outreachLocation: null, setMode: mockSetMode, setOutreachLocation: mockSetOutreachLocation });
      const { ModeBar } = require('./ModeBar');
      render(<ModeBar />);
      expect(screen.getByPlaceholderText(/standort/i)).toBeInTheDocument();
    });

    it('calls setMode("clinic") when X clicked on mobile', () => {
      useAppMode.mockReturnValue({ mode: 'outreach', outreachLocation: null, setMode: mockSetMode, setOutreachLocation: mockSetOutreachLocation });
      const { ModeBar } = require('./ModeBar');
      render(<ModeBar />);
      fireEvent.click(screen.getByRole('button', { name: '✕' }));
      expect(mockSetMode).toHaveBeenCalledWith('clinic');
    });
  });
});
```

- [ ] **Step 2: Tests laufen lassen — Mobile-Tests müssen fehlschlagen**

```bash
cd /Users/paulkaufmann/mvi/esm/msi-esm-field-app && yarn test ModeBar --no-coverage 2>&1 | tail -15
```

Expected: Desktop-Tests bestehen, Mobile-Tests schlagen fehl mit `Cannot find module '../../hooks/useIsMobile'` oder ähnlichem.

- [ ] **Step 3: ModeBar-Komponente ersetzen**

Ersetze den gesamten Inhalt von `esm/msi-esm-field-app/src/components/ModeBar/ModeBar.tsx`:

```tsx
import React, { useState } from 'react';
import { useConfig } from '@openmrs/esm-framework';
import { useAppMode } from '../../hooks/useAppMode';
import { useModeConfigSync } from '../../hooks/useModeConfigSync';
import { useIsMobile } from '../../hooks/useIsMobile';
import { type Config } from '../../config-schema';

export function ModeBar() {
  const { mode, outreachLocation, setMode, setOutreachLocation } = useAppMode();
  const { outreachLocations } = useConfig<Config>();
  const [inputValue, setInputValue] = useState(outreachLocation ?? '');
  const isMobile = useIsMobile();
  useModeConfigSync();

  const listId = 'msi-outreach-locations-list';

  const locationDatalist = (
    <datalist id={listId}>
      {(outreachLocations ?? []).map((loc) => (
        <option key={loc} value={loc} />
      ))}
    </datalist>
  );

  const handleLocationBlur = () => {
    if (inputValue && inputValue !== outreachLocation) setOutreachLocation(inputValue);
  };

  if (isMobile) {
    if (mode === 'clinic') {
      return (
        <div style={{ background: '#0f62fe', padding: '0.35rem 0.75rem' }}>
          <button
            onClick={() => setMode('outreach')}
            style={{
              background: '#fff',
              color: '#0f62fe',
              border: 'none',
              padding: '0.15rem 0.8rem',
              borderRadius: '2px',
              fontSize: '0.82rem',
              fontWeight: 600,
              cursor: 'pointer',
            }}
          >
            Outreach
          </button>
        </div>
      );
    }
    return (
      <div
        style={{
          background: '#0f62fe',
          color: '#fff',
          padding: '0.35rem 0.75rem',
          display: 'flex',
          flexWrap: 'wrap',
          alignItems: 'center',
          gap: '0.5rem',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', flexShrink: 0 }}>
          <button
            onClick={() => setMode('clinic')}
            style={{
              background: '#fff',
              color: '#0f62fe',
              border: 'none',
              width: '1.6rem',
              height: '1.4rem',
              borderRadius: '2px',
              fontSize: '0.85rem',
              fontWeight: 700,
              cursor: 'pointer',
            }}
          >
            ✕
          </button>
          <span style={{ fontSize: '0.78rem', opacity: 0.85 }}>Outreach-Modus</span>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', flexShrink: 0 }}>
          <span style={{ fontSize: '0.75rem', opacity: 0.75 }}>Standort:</span>
          {locationDatalist}
          <input
            list={listId}
            value={inputValue}
            placeholder="Standort wählen…"
            onChange={(e) => setInputValue(e.target.value)}
            onBlur={handleLocationBlur}
            style={{
              background: 'rgba(255,255,255,0.15)',
              border: '1px solid rgba(255,255,255,0.5)',
              color: '#fff',
              padding: '0.15rem 0.5rem',
              borderRadius: '2px',
              fontSize: '0.75rem',
            }}
          />
        </div>
      </div>
    );
  }

  const activeStyle: React.CSSProperties = {
    background: '#fff',
    color: '#0f62fe',
    border: 'none',
    padding: '0.15rem 0.6rem',
    borderRadius: '2px',
    fontSize: '0.78rem',
    fontWeight: 600,
    cursor: 'pointer',
  };
  const inactiveStyle: React.CSSProperties = {
    background: 'rgba(255,255,255,0.18)',
    color: '#fff',
    border: 'none',
    padding: '0.15rem 0.6rem',
    borderRadius: '2px',
    fontSize: '0.78rem',
    fontWeight: 400,
    cursor: 'pointer',
  };

  return (
    <div
      style={{
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        background: '#0f62fe',
        color: '#fff',
        height: '2.25rem',
        padding: '0 1rem',
        width: '100%',
        boxSizing: 'border-box',
      }}
    >
      <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
        <span style={{ opacity: 0.75, fontSize: '0.82rem' }}>Modus:</span>
        <button style={mode === 'clinic' ? activeStyle : inactiveStyle} onClick={() => setMode('clinic')}>
          Klinik
        </button>
        <button style={mode === 'outreach' ? activeStyle : inactiveStyle} onClick={() => setMode('outreach')}>
          Outreach
        </button>
      </div>
      {mode === 'outreach' && (
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
          <span style={{ fontSize: '0.78rem', opacity: 0.85 }}>Standort:</span>
          {locationDatalist}
          <input
            list={listId}
            value={inputValue}
            placeholder="Standort wählen…"
            onChange={(e) => setInputValue(e.target.value)}
            onBlur={handleLocationBlur}
            style={{
              background: 'rgba(255,255,255,0.15)',
              border: '1px solid rgba(255,255,255,0.5)',
              color: '#fff',
              padding: '0.15rem 0.5rem',
              borderRadius: '2px',
              fontSize: '0.78rem',
              width: '160px',
            }}
          />
        </div>
      )}
    </div>
  );
}

export default ModeBar;
```

- [ ] **Step 4: Alle Tests laufen lassen — 7 Desktop + 5 Mobile = 12 total**

```bash
cd /Users/paulkaufmann/mvi/esm/msi-esm-field-app && yarn test ModeBar --no-coverage 2>&1 | tail -15
```

Expected: `Tests: 12 passed, 12 total`

- [ ] **Step 5: Volles Test-Suite laufen lassen — keine Regressions**

```bash
cd /Users/paulkaufmann/mvi/esm/msi-esm-field-app && yarn test --no-coverage 2>&1 | tail -10
```

Expected: alle Test-Suites grün.

- [ ] **Step 6: Commit**

```bash
cd /Users/paulkaufmann/mvi/esm/msi-esm-field-app && git add src/components/ModeBar/ModeBar.tsx src/components/ModeBar/ModeBar.test.tsx && git commit -m "feat: ModeBar responsive — mobile-layout mit Outreach/X-Button und flex-wrap Standort"
```
