# Repository instructions

These instructions apply to the entire repository.

## Keep the Plus-C systems documentation current

The native Plus-C models and documents in `systems/` are part of the product and must stay synchronized with the app. The previous `docs/` guide has been retired.

Whenever an app change affects behavior, architecture, game states, runtime sequences, difficulty rules, verification details, or visible UI, automatically update the applicable Plus-C materials in the same task. Do not wait for a separate request.

This includes, as applicable:

- Updating the relevant native `systems/*.plc` diagrams and documents, requirements, and design/source trace links.
- Updating the companion Markdown, HTML, and SVG previews in `systems/review/` and the library index at `systems/index.html`.
- Keeping source-backed claims accurate and distinguishing inspected test coverage from executed test results.
- Using current, labeled captures if screenshots are added; do not reuse retired screenshots as current UI evidence.

Only change materials affected by the program change. Preserve the established app-inspired presentation style.

After changes, run `node scripts/verify-plusc.mjs` with the installed Plus-C app. Review affected source hashes and traces, validate native model round trips, and check JavaScript syntax, local links, SVG/XML, and referenced assets. Keep native documents and their review previews synchronized.
