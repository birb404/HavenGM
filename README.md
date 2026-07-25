# HavenGM

HavenGM is a Battle for Azeroth 8.3.7 GM and development addon for
HavenCore/BfaCore. It is intended to make repeatable quest testing, content
inspection, NPC/object staging, and common GM operations faster without hiding
which server commands are being executed.

## Current phase

v0.3.7-beta is implemented as a modular, tab-based feature build for a complete
in-client testing pass.

## Features

- Independent CHEATS and Fly runtime controls
- Combat, movement, repair, save and character-level tools
- Item, spell and quest testing workflows
- Categorized teleports, recents and visible one-click favorites
- Central item, spell, quest, creature and object lookup
- Temporary and persistent NPC/GameObject creator tools
- NPC animation, emote, speech, sound and spell-effect workflows
- GPS, GUID, distance, nearby entity and client-position debugging
- Saved scale, frame position, tab, inputs and safety preferences

Persistent spawns, deletes, moves, character flags and resets use confirmation
dialogs that display the command before execution.

## Reference material

- HavenCore command handlers are the authoritative compatibility source.
- The existing HavenGM prototype is the behavioral baseline.
- MarsAdmin is used only as clean-room UX and feature inspiration. Its code is
  GPL-2.0 and is not copied into this project.

See [Phase 1 Assessment](docs/Phase%201%20Assessment.md) and
[Compatibility Matrix](docs/Compatibility%20Matrix.md).

## Planned development

1. v0.1: modular refactor, stable existing tools, lookup/output panel.
2. v0.2 beta: broad Creator, lookup, character and debug feature pass.
3. v0.3: runtime-tested polish, parsed result rows and permission feedback.

## Safety rule

Destructive or persistent commands must be visually distinct, require
confirmation where appropriate, and show the exact command before execution.

## Installation

Copy the `HavenGM` directory into your Battle for Azeroth client's
`Interface/AddOns` directory, then enable HavenGM from the in-game AddOn list.
