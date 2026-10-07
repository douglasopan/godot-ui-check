# Existing workflows and the specific problem

Sources checked 2026-10-07. This is a workflow comparison, not a benchmark or novelty claim.

| Source | Existing workflow | Relevance to this proof |
|---|---|---|
| [gdUnit4 #655](https://github.com/godot-gdunit-labs/gdUnit4/issues/655) | Reports empty viewport textures in the test context and asks for rendered screenshot access. Describes checking sizes, clipping and known-good images. | Reaching the correct UI state costs time. Use a real renderer and explicitly reject dummy/headless capture. Issue observed open during research. |
| [godot-screenshots](https://github.com/treepumpkin/godot-screenshots) | Play a scene, trigger a shutter/burst, configure sizes/locales, view a camera roll. Has an API and pause option. | Multi-resolution/localization capture already exists. Direct callback state setup and matched before/after review are the emphasis here. |
| [godot-qa](https://github.com/youichi-uda/godot-qa) | JSON playtest steps, input replay, waits, node/text assertions, screenshot baselines and CI/JUnit reports. Visual mode needs a real renderer. | A broader automated QA flow. This proof skips replay and CI gates, prepares scenes directly and favors human visual review. |
| [godot-ui-automation](https://github.com/graydwarf/godot-ui-automation) | Record/playback UI actions, screenshot checkpoints, tolerant comparisons and a built-in test manager. | Test management and screenshot validation already exist. This proof explores a smaller callback-first capture workflow and a portable local comparison file. |

All three repositories expose MIT root licenses; their ancillary assets still require individual checks before reuse. No dependency was downloaded, copied or vendored. The small original capture runner uses Godot's public API to keep this experiment self-contained under the task's no-download constraint. Future work should assess interoperability/reuse with these projects before expanding capture features.

Godot API references: [SubViewport](https://docs.godotengine.org/en/4.5/classes/class_subviewport.html), [RenderingServer](https://docs.godotengine.org/en/4.5/classes/class_renderingserver.html), [TranslationServer](https://docs.godotengine.org/en/4.5/classes/class_translationserver.html). The renderer waits for completed frames, gives SubViewports explicit dimensions/update modes and restores locale after capture.

Next validation: show the preparation callback and gallery to five Godot developers. Ask them to prepare a real screen, inspect a localized narrow layout and explain whether direct state setup and this review flow save time. No demand or collaborator interest has been proven yet.
