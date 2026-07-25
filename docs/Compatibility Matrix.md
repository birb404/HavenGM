# HavenCore Compatibility Matrix

Date: 2026-07-24

This is the Phase 1 source audit. “Observed” refers to behavior already exercised
through the deployed HavenGM prototype. Everything else still needs a controlled
runtime test before it can be called fully verified.

| Area | Command or family | Evidence | Status | Risk / notes |
|---|---|---|---|---|
| Quest | `.quest add <id>` | `cs_quest.cpp` | Source verified + observed | Mutates character quest log |
| Quest | `.quest complete <id>` | `cs_quest.cpp` | Source verified + observed | Can bypass objectives |
| Quest | `.quest remove <id>` | `cs_quest.cpp` | Source verified + observed | Removes progress |
| Quest | `.quest reward <id>` | `cs_quest.cpp` | Candidate | Reward side effects; test separately |
| Quest | `.go quest <id>` | `cs_go.cpp` | Source verified + observed | Destination choice must be documented |
| Quest | universal replay/reset | No dedicated safe command established | Unsupported for v0.1 | Compose remove/add only with explicit warning |
| Cheats | `.cheat god on/off` | `cs_cheat.cpp` | Source verified + observed | Local toggle is not server telemetry |
| Cheats | `.cheat casttime on/off` | `cs_cheat.cpp` | Source verified + observed | Local toggle is not server telemetry |
| Cheats | `.cheat cooldown on/off` | `cs_cheat.cpp` | Source verified + observed | Local toggle is not server telemetry |
| Cheats | `.cheat power on/off` | `cs_cheat.cpp` | Source verified + observed | Local toggle is not server telemetry |
| Cheats | `.cheat waterwalk on/off` | `cs_cheat.cpp` | Candidate | Safe after runtime test |
| Cheats | `.cheat taxi on/off` | `cs_cheat.cpp` | Candidate | Changes taxi discovery/access |
| Cheats | `.cheat explore on/off` | `cs_cheat.cpp` | Candidate | May alter exploration flags |
| GM | `.gm on/off` | `cs_gm.cpp` | Source verified + observed | “ALL” semantics must be explicit |
| Movement | `.gm fly on/off` | `cs_gm.cpp` | Source verified + observed | Persists server-side across `/reload` |
| Movement | `.modify speed all <rate>` | `cs_modify.cpp` | Source verified + observed | Validate safe numeric range |
| Combat | `.die` | `cs_misc.cpp` | Source verified + observed | Requires selected unit |
| Combat | `.damage <amount>` | `cs_misc.cpp` | Source verified + observed | `-80% HP` needs computed value or core support |
| Character | `.levelup <delta>` | `cs_character.cpp` | Source verified | Current Set Level composition needs runtime documentation |
| Character | `.character level ...` | `cs_character.cpp` | Candidate | Console-capable; syntax/target rules need test |
| Character | `.revive` | `cs_misc.cpp` | Source verified | Target behavior and permissions need test |
| Character | `.recall` | `cs_misc.cpp` | Candidate | Useful rescue action |
| Character | `.save` | `cs_misc.cpp` | Candidate | Character persistence |
| Items | `.additem <id> [count]` | `cs_misc.cpp` | Source verified + observed | Negative count removal is currently relied upon; retest |
| Spell | `.learn <id>` | `cs_learn.cpp` | Source verified + observed | Character mutation |
| Spell | `.unlearn <id>` | `cs_learn.cpp` | Source verified + observed | Character mutation |
| Lookup | `.lookup item <text>` | `cs_lookup.cpp` | Source verified + observed | Chat parsing is format-sensitive |
| Lookup | `.lookup spell <text>` | `cs_lookup.cpp` | Source verified + observed | Supports a nested `id` route |
| Lookup | `.lookup quest <text>` | `cs_lookup.cpp` | Source verified | Add to v0.1 lookup panel |
| Lookup | `.lookup creature <text>` | `cs_lookup.cpp` | Source verified | Add to v0.1 lookup panel |
| Lookup | `.lookup object <text>` | `cs_lookup.cpp` | Source verified | Add to v0.1 lookup panel |
| Lookup | `.lookup tele <text>` | `cs_lookup.cpp` | Source verified | Add to v0.1 lookup panel |
| Lookup | map/area/faction/itemset/skill/title | `cs_lookup.cpp` | Candidate | Defer until core lookup UI is stable |
| Teleport | `.tele <name>` | `cs_tele.cpp` | Source verified + observed | Known named locations are safest |
| Teleport | `.tele add/del` | `cs_tele.cpp` | Dangerous candidate | Mutates shared teleport database |
| Position | `.go xyz ...`, `.go zonexy ...` | `cs_go.cpp` | Source verified | Validate map/coordinates before execution |
| Position | `.gps` | `cs_misc.cpp` | Source verified | Good candidate for raw output capture |
| NPC | `.npc info` | `cs_npc.cpp` | Source verified | Selected spawn; expose entry and GUID separately |
| NPC | `.npc near [distance]` | `cs_npc.cpp` | Source verified | Raw/parsed output candidate |
| NPC | `.npc add <entry>` | `cs_npc.cpp` | Dangerous candidate | Persistent spawn unless temp route is used |
| NPC | `.npc add temp <entry>` | `cs_npc.cpp` | Source verified candidate | Preferred Creator prototype after runtime test |
| NPC | `.npc delete ...` | `cs_npc.cpp` | Dangerous | Confirmation and exact target identity required |
| NPC | `.npc move` | `cs_npc.cpp` | Dangerous candidate | Persistent positional mutation |
| NPC | `.npc set model/level/factionid/...` | `cs_npc.cpp` | Dangerous candidate | Each subcommand needs its own schema |
| NPC | `.npc playemote <id>` | `cs_npc.cpp` | Source verified candidate | Good Creator feature |
| NPC | `.npc say/yell/textemote/whisper` | `cs_npc.cpp` | Source verified candidate | Good video/staging feature |
| NPC | `.npc aianimkit ...` | `cs_npc.cpp` | Candidate | BFA-specific; exact syntax needs inspection/test |
| Object | `.gobject info/near/target` | `cs_gobject.cpp` | Source verified candidate | Entry vs spawn GUID distinction applies |
| Object | `.gobject add [temp]` | `cs_gobject.cpp` | Dangerous candidate | Prefer temporary creation |
| Object | `.gobject delete/move/turn/set` | `cs_gobject.cpp` | Dangerous | Confirmation and preview mandatory |
| Debug | `.debug anim <id>` | `cs_debug.cpp` | Source verified candidate | Selected unit; useful for video staging |
| Debug | `.debug play sound/movie/cinematic` | `cs_debug.cpp` | Candidate | Client-facing effects; test one by one |
| Debug | packet/world/vehicle/phase commands | `cs_debug.cpp` | Dangerous candidate | v0.3 only |
| Lists | `.list quests`, `.list auras`, `.list scenes` | `cs_list.cpp` | Candidate | Useful raw output sources |
| Reset | `.reset level/spells/stats/talents/all` | `cs_reset.cpp` | Dangerous | Never expose without confirmation |

## Immediate runtime test queue

1. Capture raw output from `.gps`, `.npc info`, `.gobject info` and the five main
   lookup commands.
2. Confirm exact target and argument rules for `.damage`, `.revive`,
   `.character level`, `.npc add temp`, `.npc playemote` and `.debug anim`.
3. Confirm whether negative `.additem` is reliable in this HavenCore build.
4. Decide whether ALL controls Fly. If it does not, rename it to CHEATS to avoid
   displaying `ALL OFF` while Fly is ON.
