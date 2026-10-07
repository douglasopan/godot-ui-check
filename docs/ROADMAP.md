# Roadmap

Implemented: callback registration, fresh scenes per cell, sequential size/locale matrix, PNG/manifests, cancellation, restoration, original broken/fixed demo, native capture UI and portable wipe/overlay gallery.

Tested: Godot 4.5.2, Windows, GL Compatibility / OpenGL 3, Radeon RX 570. See `TEST_RESULTS.md` for evidence and limits.

Small next tasks, in priority order:

1. **Manual gallery accessibility review.** Open a generated report from disk, check keyboard navigation/range controls, filter empty state and narrow viewport behavior. Record browsers and screenshots. Automated browser opening was blocked in the original execution environment.
2. **Persistent baseline selection.** Add native file pickers for existing manifests and a clear before/after provenance display. Handle moved capture folders using relative paths without automatically approving a new baseline.
3. **RTL/CJK fixture and compatibility reports.** Add distributable fonts with notices if needed, deterministic strings/data and captures under identified engines/renderers. Avoid claiming cross-driver pixel equality.
4. **Capture lifecycle hardening.** Measure cancellation while awaiting a frame, stopped rendering, teardown and callbacks that violate their contract. Decide whether to support bounded asynchronous setup; short direct callbacks are the current contract.
5. **Validate usefulness with five developers.** Measure state-preparation and review time. Discuss interoperability with existing screenshot and QA addons before growing the capture surface.

No backend, account, required AI, full input replay or mobile SDK is planned for this local proof. Hosted services and automatic baseline approval are out of scope.
