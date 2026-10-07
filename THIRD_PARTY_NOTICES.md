# Third-party notices

No external addon, source code, font file, icon pack, sound or image is vendored in this proof. The demo uses original code-built controls. Node's built-in modules are used only by an optional checker. The executable Godot and test tools available on the development machine are not included in the repository or source archive.

Godot Engine is used as a separately installed runtime. Godot is MIT-licensed and includes its own third-party components; see the [official license page](https://godotengine.org/license/) and the engine's bundled notices. The demo renders text with `ThemeDB.fallback_font` supplied by that runtime; no font binaries are copied into this project.

The following projects informed the workflow comparison but are **not dependencies** and contributed no copied code/assets:

| Project | Observed root license | Source |
|---|---|---|
| treepumpkin/godot-screenshots | MIT | [LICENSE.md](https://github.com/treepumpkin/godot-screenshots/blob/main/LICENSE.md) |
| youichi-uda/godot-qa | MIT | [LICENSE](https://github.com/youichi-uda/godot-qa/blob/master/LICENSE) |
| graydwarf/godot-ui-automation | MIT | [LICENSE](https://github.com/graydwarf/godot-ui-automation/blob/main/LICENSE) |

Checked 2026-10-07. Root license compatibility does not automatically clear every ancillary asset in those repositories. Reuse would require inspecting the exact revision and all included asset licenses, preserving notices and documenting any modifications.
