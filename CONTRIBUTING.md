# Contributing

Thanks for helping make UI review easier. This is an early local proof maintained by Douglas Pan / thePan.art.

Before a change, describe the concrete scene/state and review problem. Keep a small reproducible scene, record Godot version, renderer, rendering driver, GPU/OS, size and locale, and attach only distributable material. Do not include secrets, personal data or proprietary game assets in captures.

1. Fork and create a focused branch.
2. Read `docs/DESIGN.md` before changing the capture/review UI.
3. Use an existing Godot installation; run the logic and renderer suites described in README.
4. For visual changes, attach matched before/after PNGs and explain the intended result. Pixel differences are not automatically bugs.
5. Submit a small PR with the problem, final behavior, tests and known limitations. Include the environment and test-results JSON with local paths redacted.

No build system or package install is required for the GDScript code. The optional Node checker uses only built-in modules. Keep reusable code under `addons/ui_check/`, the original demo under `demo/`, and generic harness/UI under `lab/`. Do not commit `.godot/`, logs, executables, captures of private projects or credential files.

Compatibility reports are welcome before broadening the supported-version claim. RTL/CJK, renderer-specific behavior and cancellation edge cases should be backed by real captures. Contributions are accepted under the project's MIT license; preserve third-party notices if a dependency is proposed.
