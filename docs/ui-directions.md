# VENDRIX UI Direction Concepts

These are concept directions only. No UI has been implemented or selected. A selection is required before each major UI implementation.

All concepts use the project's dark foundation with Neon Blue, electric blue, and cyan accents. Player-facing strings must be Latin-script Finglish.

## Concept A — Minimal Glass
- Dark translucent panels with subtle blur-like layering.
- Thin cyan borders and restrained electric-blue highlights.
- Compact typography, generous spacing, minimal decoration.
- Best for a clean, modern RPG HUD with low visual clutter.

## Concept B — Neon Command
- Near-black surfaces with stronger electric-blue edge lighting.
- Clear status blocks, compact indicators, and technical separators.
- Stronger contrast for combat, faction, and territory information.
- Best for a more energetic cyber-RPG identity.

## Concept C — Tactical Grid
- Structured panels based on a consistent grid.
- Cyan focus states, blue section markers, and restrained geometric details.
- Information-dense layouts with clear hierarchy and alignment.
- Best for management screens, inventory, faction, and admin interfaces.

## Implementation constraints
- Present at least three distinct concepts before a major UI implementation.
- Wait for the user's explicit selection.
- Avoid continuous full-screen DX redraws when event-driven rendering is sufficient.
- Cache static text/layout calculations and release render resources on resource stop.
- Never trust client-side values for money, inventory, permissions, or gameplay outcomes.
