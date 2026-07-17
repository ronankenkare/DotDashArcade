# Repository instructions

These instructions apply to the entire repository.

## Keep the systems documentation current

The HTML systems guide in `docs/` is part of the product and must stay synchronized with the app.

Whenever an app change affects behavior, architecture, game states, runtime sequences, difficulty rules, verification details, or visible UI, automatically update the applicable documentation files in the same task. Do not wait for a separate request to update them.

This includes, as applicable:

- Updating the relevant `docs/*.html` pages and Mermaid diagrams.
- Updating shared presentation or interactions in `docs/styles.css` and `docs/diagrams.js`.
- Recapturing or replacing simulator screenshots in `docs/assets/` when the documented UI changes.
- Adjusting labels, arrows, annotations, state previews, and explanatory text so they accurately describe the current program.

Only change documentation affected by the program change. Preserve the established app-inspired visual style and existing interactive diagram behavior.

After documentation changes, check Mermaid syntax, JavaScript syntax, local links, and referenced assets.
