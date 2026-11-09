# Generic Addon

This is a lightweight, generic addon template for World of Warcraft Forever.

## Folder layout

- `GenericAddon.toc` — the addon manifest used by WoW.
- `Core.lua` — event handling, saved variables, and slash commands.
- `Config.lua` — a small config frame for toggling and testing the addon.

## Install

1. Copy the `GenericAddon` folder into your WoW Forever `AddOns` directory.
2. Restart the game or reload the UI with `/reload`.
3. Use:
   - `/ga toggle`
   - `/ga status`
   - `/ga say`
   - `/gacfg`

## Customize

Edit the values in `Core.lua` to change:

- the addon name and version
- default saved settings
- chat output colors and messages
- the command behavior

## Notes

This is intentionally generic so you can extend it with combat logic, timers, minimap buttons, or extra UI panels for your own gameplay needs.
