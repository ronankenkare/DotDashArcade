# Maintenance and known constraints

## Update policy

AGENTS.md requires the Plus-C systems materials to change alongside behavior, architecture, states, timing, difficulty, verification or visible UI changes. Update the affected native Plus-C views and documents under systems/ in the same task. Keep the Markdown, HTML and SVG review previews under systems/review/ synchronized. The source-checked Plus-C materials replace the retired HTML/Mermaid guide; the old guide and its dated simulator screenshots have been removed.

The root project.plc retains the original project identity. systems/ contains native diagram parts for the installed Plus-C app. Open the repository folder in Plus-C. The systems/review/ previews are companion review artifacts, not separate authoritative models. Model traces point from implementing code and design elements toward requirements.

## Known constraints from source inspection

- Classic width does not shrink, despite the README introduction suggesting every hit shrinks the zone.
- Target movement is attempted at most 16 times. The final candidate can move less than the preferred threshold.
- Foreground does not resume a paused run. Start resets it.
- Bests are saved on misses, so a discarded live run is not persisted.
- Particle x/y use per-update increments while age uses elapsed time; their displacement varies with refresh rate.
- CADisplayLink targets GameState strongly and requires explicit stopLoop on disappear/inactive. Verify lifecycle teardown when changing ownership.
- Speed has no maximum; movement clamps overshoot rather than reflecting remaining travel.
- Classic's initial instruction preview can use initializer world defaults until reset because same-mode changeMode is a no-op.
- Support is an external form whose availability is not controlled by this repository.

These are observed constraints and review candidates, not changes made by this documentation task. No severity ratings, release approvals or test-run results have been invented.

## Review checklist

After changes, run node scripts/verify-plusc.mjs to validate native models, split/merge round trips, trace endpoints and source hashes. Check identifiers, JavaScript syntax, local HTML links, SVG/XML and referenced assets. Inspect affected views in Plus-C. Any future simulator screenshots must be current, labeled captures stored with these materials; the retired screenshots are not evidence of the current UI.
