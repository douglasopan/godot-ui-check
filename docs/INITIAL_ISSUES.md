# Initial contributor tasks

These tasks are intentionally small. They do not imply that broader platform support is already verified.

## Manual gallery accessibility and responsive review

Open `docs/sample-review.html` from disk in an existing browser. Verify keyboard case selection, wipe/overlay range control, locale/difference filters, no-match state and JSON download. Test desktop and a narrow viewport. Record the browser, dimensions and screenshots. The original execution environment blocked automated `file://` opening.

Acceptance: reproducible checklist/results, any concrete failures fixed, screenshots showing desktop and narrow review, no CDN/network dependency.

## Select persisted before/after manifests in the native lab

The current UI keeps manifests in memory; the CLI can compare existing ones. Add labelled file pickers for completed before/after manifests, show provenance and report validation errors inline. Support moved capture folders with relative paths.

Acceptance: reopen two captures in a new lab session, reject incomplete/mismatched runs, preserve original evidence, generate the same pair IDs/diffs.

## Add an RTL/CJK reproducible fixture

Add one original deterministic UI state with long translated content and a distributable, pinned font if required. Document its font license and test engine/renderer. Capture narrow and wide cases.

Acceptance: real PNG evidence, repeat hashes measured on one identified environment, clear before/after layout case, no private assets and no broad cross-platform claims.
