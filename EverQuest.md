# Project Specification: RPQuests (WoW Classic / Forever Addon)

## 1. Goal & Target Environment
Build a World of Warcraft Classic / Forever (`## Interface: 11503` / `16001`) roleplay questing addon in **Lua 5.1 & XML** using standard, TOS-compliant client APIs. 
- **Core Concept:** Non-linear, multiplayer "whodunit" and Choose-Your-Own-Adventure mysteries featuring a **GM Authoring/Broadcast mode** and an **obfuscated Player Runtime** to prevent `Ctrl+F` datamining spoilers.

---

## 2. Core Architecture & Modules

### A. Two-Stage Data Pipeline (Plaintext Authoring → Obfuscated Runtime)
1. **GM Authoring DB (`RPQuests_AuthorDB` - GM SavedVariables only):**
   - Stores human-readable quest graphs: `editorNote`, raw world coordinates (`UnitPosition("player")` -> `y, x, z, instanceID`), target NPC IDs, time buckets, `requiredSalt`, `grantsSalt`, and raw `revealText`.
   - Includes a one-click **Compiler** that converts plaintext nodes into sealed runtime entries and strips all plaintext metadata.
2. **Player Runtime DB (`RPQuests_RuntimeDB` + `RPQuests_CharDB`):**
   - Flat, unordered dictionary keyed by **32-bit FNV-1a hashes** (`[triggerHash] = encryptedHexBlob`).
   - Zero plaintext coordinates, zone names, or `if/else` branch logic exist in shipped files.

### B. Cryptographic Hash-Chain & Implicit Conditionals
- **Self-Unlocking Secrets:** Each trigger condition is serialized into a canonical key string (`rawKey`), hashed via FNV-1a (`triggerHash`), and used as the **XOR stream cipher key** to encrypt `grantsSalt .. "::" .. revealText`.
- **Spatial Quantization (Yard Grid):** Use `UnitPosition("player")` (world yards) divided into `5x5` yard tiles (`math.floor(x / 5)`, `math.floor(y / 5)`). During `/search`, check the player's current tile + 8 adjacent neighbors (`dx = -1..1, dy = -1..1`) to create a ~15x15 yard detection area centered on the target without storing coordinates. *(Fallback to `GetSubZoneText()` or `UnitGUID("target")` NPC ID inside instances where `UnitPosition` returns `nil`.)*
- **Environmental & Narrative Salts:** Fold conditions directly into `rawKey` (`POS:<inst>:<tx>:<ty>|TIME:<bucket>|NPC:<id>|SALT:<prevSalt>`):
  - **Time Buckets:** Quantize `GetGameTime()` into buckets (`WITCHING_HOUR`, `DAY`, `NIGHT`, `ANY`).
  - **Branching & Convergence:** Previous narrative choices grant distinct `grantsSalt` tokens stored in `RPQuests_CharDB.salts`. Visiting the exact same location/NPC later with different salts hashes to different nodes, unlocking divergent outcomes.

### C. World Interaction & Dynamic Text Parser
- **Active & Passive Triggers:**
  - `/search` slash command (evaluates location/target + held salts).
  - `PLAYER_TARGET_CHANGED` & `GOSSIP_SHOW` hooks (injects `[Investigate]` options or subtle prompts on flavor NPCs without requiring native gossip windows).
  - `CHAT_MSG_TEXT_EMOTE` & `CHAT_MSG_SAY` listeners (reacts to `/kneel`, `/threaten`, or spoken passphrases).
  - Throttled proximity ticker (`C_Timer.NewTicker(0.5, ...)`) for "hot/cold" audio/toast cues (`PlaySound`, `RaidWarningFrame`).
- **Dynamic Spin-Text & Token Parser (`ParseQuestText`):**
  - Resolves context tokens (`{name:player}`, `{class:player}`, `{race:player}`, `{sibling:player}`) and recursively resolves randomized spin groups `(Welcome|Hello|Hail)` via `string.gsub` before rendering to Blizzard parchment UI templates (`ItemTextFrame` / custom `QuestFont` frames).

### D. Live GM "To Be Continued" Episodic Sync (`C_ChatInfo`)
- **Anti-Spoiler Streaming:** Future chapters stay exclusively on the GM client until unlocked live.
- **Pull-Based Handshake (`PREFIX = "RPQ_SYNC"`):**
  1. GM client broadcasts a small heartbeat (`AVAIL:<questId>:<chapter>`) over `GUILD` or `RAID`.
  2. Clients at `AWAITING_GM` with the prerequisite completion salt send a `WHISPER` request (`REQ:<questId>:<chapter>:<proofSalt>`) to the GM character.
  3. GM validates the sender/salt and transmits the compiled chapter payload via a **255-byte chunking & rate-limited queue** (`MSG_ID|PART|TOTAL|HEX_DATA`).

---

## 3. Recommended File Structure
- `RPQuests.toc` — Declares Interface version, `SavedVariables: RPQuests_AuthorDB`, and `SavedVariablesPerCharacter: RPQuests_CharDB`.
- `Crypto.lua` — Pure Lua 5.1 (using WoW's `bit` library) FNV-1a hash, XOR cipher, `ToHex`/`FromHex`, and canonical key builders.
- `Parser.lua` — Spin-syntax `(A|B|C)` and `{token:unit}` text processor.
- `Runtime.lua` — `/search` engine, 3x3 yard-grid matcher, event listeners (target, emote, say, proximity), and `RPQuests_CharDB` state manager.
- `Comms.lua` — `C_ChatInfo.SendAddonMessage` beacon, chunker, reassembler, and throttled send queue.
- `Authoring.lua` — GM-only `/gmstamp` world capture tool, debug HUD, graph validator, and plaintext-to-hash compiler.
- `UI.xml` & `UI.lua` — Blizzard parchment-styled clue/quest popup frames, toast alerts, and GM authoring panel.

---

## 4. Next Step for Agent
Scaffold the `.toc` file alongside `Crypto.lua`, `Parser.lua`, and a minimal `Runtime.lua` + `Authoring.lua` (`/gmstamp` + `/search`) so we can test stamping, compiling, and unlocking a salted clue in-game.
