# Phase 1 Assessment

Date: 2026-07-24

## Scope

This phase inventories the deployed HavenGM prototype, the HavenCore command
implementation, and MarsAdmin as a clean-room feature reference. It deliberately
does not modify HavenCore, databases, server configuration, or the deployed
addon.

## Inputs inspected

- HavenCore command handlers and command tables;
- the previously deployed HavenGM prototype;
- MarsAdmin as a clean-room feature reference;
- the HavenGM redesign requirements.

The deployed two-file addon (`HavenGM.lua`, `HavenGM.toc`) was used as the
canonical runtime baseline.

## Existing prototype

The prototype is a single 33 KB Lua file plus a TOC. It already provides:

- local toggle UI for GM, god, cast-time, cooldown, power and fly;
- immediate speed adjustment;
- quest add, complete, remove and go-to;
- item add/remove and item/spell lookup;
- spell learn/unlearn;
- character level controls;
- categorized teleports;
- item and quest ID capture hooks;
- minimap/settings integration.

These behaviors must survive the refactor:

- speed changes immediately from plus/minus; no Apply Speed button;
- no RESET OFF button;
- a fresh login presents toggles as OFF without silently issuing commands;
- `/reload` preserves the locally displayed toggle state;
- shift-right-click fills an ID field without opening chat;
- teleport controls remain aligned and non-overlapping.

## MarsAdmin assessment

MarsAdmin has useful feature groupings across character, NPC, game object,
teleport, ticket, server and lookup workflows. It targets an older TrinityCore
generation and cannot be treated as a command compatibility source.

Its archive also contains its complete `.git` directory. It must never be
extracted into the HavenGM repository. Only feature names and interaction ideas
may be studied. No implementation is copied because MarsAdmin is GPL-2.0 and
HavenGM is being developed as an independent implementation.

## Key technical findings

1. HavenCore registers commands through RBAC-backed C++ command tables. The
   source handler is the authority, not MarsAdmin button labels.
2. Entry IDs and spawn GUIDs are different concepts. Creator tools must use
   separate fields and labels.
3. A WoW addon cannot read the server's current cheat/fly state reliably.
   Toggle colors are local intent, not authoritative telemetry.
4. Lookup results are chat text. Parsing them is locale- and format-sensitive.
   The first lookup panel should retain raw output and treat parsed rows as
   best-effort.
5. System clipboard access is unavailable to ordinary addon Lua. “Copy” must
   mean placing text in a focused, selectable edit box.
6. Persistent NPC/object mutations, deletes, resets and mass operations need a
   confirmation and preview layer.
7. Quest replay/reset needs special care. HavenCore exposes add, complete,
   remove and reward, but a single safe universal “replay” command has not been
   established.

## Verification vocabulary

- **Source verified**: command path, handler and RBAC node were found in this
  HavenCore checkout.
- **Runtime observed**: the current prototype or a manual test was seen to work
  on the local server.
- **Fully verified**: source verified, exact syntax recorded, executed locally,
  output observed, and permissions/side effects documented.
- **Candidate**: present in source but exact runtime behavior is not yet tested.
- **Unsupported**: no suitable HavenCore command was found.
- **Dangerous**: supported, but destructive, persistent, or able to affect other
  players/server state.

## Recommended architecture

The next implementation should split the monolith into:

- `Core/State.lua`: saved state and login/reload semantics;
- `Core/Commands.lua`: command registry, validation, preview and execution;
- `Core/Output.lua`: chat capture and raw/parsed result handling;
- `Core/Widgets.lua`: common controls and Haven styling;
- `Modules/Player.lua`;
- `Modules/Quest.lua`;
- `Modules/Lookup.lua`;
- `Modules/Teleport.lua`;
- `Modules/CreatorNPC.lua`;
- `Modules/CreatorObject.lua`;
- `Modules/Debug.lua`;
- `Data/Teleports.lua`;
- `Data/CommandCatalog.lua`.

The command registry is the central boundary. UI modules should request a
registered action instead of constructing chat strings themselves.

## Release boundary

v0.1 should stabilize and modularize what already works, then add the raw
lookup/output panel. NPC/object creation belongs in v0.2. Broad server/debug
administration belongs in v0.3 after its risk model is tested.
