# First proof — measured results

Run date: 2026-10-07. Tested project: `D:/Codex/Projects/godot-ui-check`. Evidence: `F:/Codex/Builds/godot-ui-check/tests-1791397431-5324596/`.

## Environment

| Item | Observed |
|---|---|
| Engine | Godot 4.5.2 stable official, `6ce3de25a` |
| Renderer | `gl_compatibility` |
| Driver | `opengl3`, OpenGL API 3.3.0 Core Profile Context |
| Device | ATI Technologies Inc. / Radeon RX 570 Series |
| Driver string | `26.1.1.251211` |
| OS | Windows host |
| Font | Engine-bundled `ThemeDB.fallback_font`, explicitly assigned to the demo theme |
| Fixed fixture | 2026-01-15, order TS-1042, fixed quantities/copy, seed context 2026 |

## Results

**28 real-renderer checks passed, 0 failed. 6 headless checks passed, 0 failed.** The renderer suite captures multiple repeated matrices as well as the demo UI; it does not use synthetic substitute images.

| Check | Result |
|---|---|
| Registration: two states; duplicate, unsafe name and missing callback rejected | Passed |
| Invalid size rejected | Passed |
| Before and after: 8 PNGs each, correct target dimensions | Passed |
| Restore locale/time scale/FPS, preserve pause and window size | Passed |
| Before repeat: all 8 raw-pixel SHA-256 values identical | Passed |
| After repeat: all 8 raw-pixel SHA-256 values identical | Passed |
| Repeat output folders are unique | Passed |
| Cancel after first capture; save cancelled partial manifest | Passed |
| Cancel during setup/layout settling | Passed |
| Cancel while render loop is stopped | Passed |
| Stopped render loop fails after five seconds, restores settings | Passed |
| Output folder I/O error is explicit, no stale busy state | Passed |
| New run after cancellation yields the same pixels | Passed |
| Setup callback returning false reports failure and restores settings | Passed |
| HTML and JSON reports generated; 8 changed pairs detected | Passed |
| Identical runs generate 0 changed pairs | Passed |
| Different engine metadata rejected | Passed |
| Native primary, before, after and cancel button signals run correct flows | Passed |
| Headless capture explicitly rejected without changing settings | Passed |
| Optional Node syntax/data/embedded PNG dimensions/local-resource checks | Passed |

The I/O test deliberately makes a regular file where a folder is required; the associated Godot directory error in the log is expected and is asserted as a handled failure.

| Pair | Exact changed pixels (%) |
|---|---:|
| supply / 480×720 / en | 17.667 |
| supply / 480×720 / pt_BR | 17.889 |
| supply / 960×640 / en | 5.083 |
| supply / 960×640 / pt_BR | 5.132 |
| packed / 480×720 / en | 17.373 |
| packed / 480×720 / pt_BR | 17.557 |
| packed / 960×640 / en | 5.078 |
| packed / 960×640 / pt_BR | 5.127 |

These values show differences, not an automatic pass/fail layout judgment. Real mobile screenshots were inspected and show both intentional problems and the corrected result. Public demo PNGs are in `docs/screenshots/`; the portable generated example is `docs/sample-review.html`. Machine-readable checks are preserved in `docs/evidence/`.

## Implementation, verification and remaining work

Implemented and renderer-tested: callbacks, fresh scenes, small size/locale matrix, PNG/manifests, restore/cancel/repeat behavior, native capture actions and pixel/report generation.

Generated gallery: HTML/JSON and embedded image dimensions verified; its JavaScript is syntax-valid. **Browser visual/interaction QA is pending.** The environment's browser policy rejected `file://` navigation and explicitly prohibited a workaround. No local HTTP server or alternate browser was used to bypass that restriction. Open the file manually and check keyboard, slider, overlay, filters, download and responsive layout.

Not tested: other Godot versions/renderers/devices/OSes, RTL/CJK, arbitrary animated scenes, async setup cancellation, native dialogs and project-specific viewport effects. Native UI actions were exercised through their actual button signals in Godot, not desktop mouse/keyboard input automation. No exported executable was built because matching export templates were not available; the source project is directly runnable with the existing Godot binary.

Initial sandbox limitations: default application-data logs failed, so logging was disabled in the project and test logs were explicitly routed into allowed output folders. The first headless import also had global editor-settings writes denied; it was not repeated. Shader-cache/certificate-store messages occurred in the sandboxed preliminary run; the final permitted D:/F: renderer run completed without those messages. No SDK, package, engine download or new license acceptance was performed.
