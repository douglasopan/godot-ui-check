# Godot UI Check — first local proof

Design recorded before implementation, 2026-10-07.

## Product task

Prepare a known UI state once, render a small size × language matrix, then review the same case before and after a change. The reviewer should always know which state, resolution, language and version is visible.

## Screens

### 1. Capture lab (native Godot)

```
┌────────────────────────────────────────────────────────────┐
│ [UI] GODOT UI CHECK                 LOCAL PROOF / 0.1       │
│ Catch layout surprises before your players do.             │
├──────────────────────────────┬─────────────────────────────┤
│ 01 / Prepare                 │ 02 / Capture                │
│ Original Trail Supply demo   │ [Capture before]            │
│ • supply / packed            │ [Capture after]             │
│ • 480×720 / 960×640          │ [Run both + review]         │
│ • English / Português       │ [Cancel] progress / 8       │
│ Output folder [___________] │ [Open local gallery]        │
├──────────────────────────────┴─────────────────────────────┤
│ Status: Ready. No baseline is overwritten.                 │
│ Demo: fixed-width mobile panel + translated CTA clipping.  │
└────────────────────────────────────────────────────────────┘
```

Primary action is Run both + review. Before/after are explicit versions of the original demo, not auto-approved baselines. Every run uses a new folder. Capture is sequential. Cancel stays available during rendering. Outcome names: Ready, Capturing, Completed, Cancelled, Failed. Incomplete runs retain their manifest and never look complete. Output errors are shown inline.

### 2. Local review (self-contained HTML)

```
┌────────────────────────────────────────────────────────────┐
│ UI CHECK / REVIEW                  Before → After           │
│ 8 pairs    8 changed    0 unchanged   [Download JSON]       │
├─────────────────┬──────────────────────────────────────────┤
│ Filter language │ Supply / 480×720 / Português              │
│ Filter status   │ [Wipe] [Overlay] [Before] [After]         │
│ Case list       │ ┌──────────────────────────────────────┐ │
│ Supply / mobile │ │ actual Godot PNGs at same scale      │ │
│ Packed / mobile │ │             │ draggable split        │ │
│ ...             │ └──────────────────────────────────────┘ │
│                 │ Split [────────●──────] 50%              │
│                 │ Changed pixels 4.2% • manual review      │
│                 │ Engine / renderer / seed / font          │
└─────────────────┴──────────────────────────────────────────┘
```

Wipe is the default, a labelled keyboard-accessible range controls it. Overlay uses opacity. No opaque pass/fail verdict from a pixel percentage. Differences need human review. Filters and case navigation are keyboard accessible, images have alt text, focus is visible. Mobile review stacks the case list above the image. Report opens from disk without a server; image data is embedded for portability. No network requests or external fonts.

## Tokens

| Token | Value | Purpose |
|---|---|---|
| Canvas | #101820 | Calm dark background |
| Surface | #192630 | Cards and controls |
| Raised | #223441 | Hover and selection |
| Border | #3b5362 | Visible boundaries |
| Text | #edf4f5 | Main copy |
| Muted | #a7bbc5 | Metadata |
| Accent | #80e0c3 | Primary action and selection |
| Warning | #ffd18a | Changed and incomplete |
| Error | #ffabb0 | Capture error |
| Spacing | 8 / 12 / 16 / 24 / 32 px | Consistent rhythm |
| Radius | 12 px | Cards and buttons |
| Type | 14 metadata / 16 body / 24 section / 32 title | Clear hierarchy |

Godot uses its bundled fallback font, explicitly pinned in the demo theme. Browser review uses system UI type only for chrome; rendered evidence remains the embedded Godot pixels.

## Original demo

Trail Supply is a small fictional hiking supply checkout made from code, with no imported artwork. Two registered states: selecting a supply kit and a packed-order confirmation. Before intentionally uses a 620 px card on a 480 px viewport, and a 148 px CTA that truncates Portuguese copy. After uses viewport-relative card width and a full-width wrapping CTA. Fixed order, date, quantities and seed; no wall clock, network, animation or global RNG.

## Scope boundaries

Local native capture UI + local browser review. No hosted site, backend, account, input replay, Android build or AI dependency. Pixel comparisons are diagnostic, not a proof that layout is correct. Cross-driver determinism is not promised.
