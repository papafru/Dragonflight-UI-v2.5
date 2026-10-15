# Dragonflight UI v2.5

**An enhanced continuation of Dragonflight UI: Reforged**, focused on improved controls, reliable customization, and a polished Classic-era interface. Built on the original Reforged project, with **more updates planned for the future**.

> **Stable status:** The current downloadable addon build is **v1.3.6**. “Dragonflight UI v2.5” is the project/repository name; it does not rename the in-game version or imply an unreleased build.

## What's improved over Reforged

- **Enhanced Edit Mode:** Move supported UI elements with readable drag-handle labels and improved position previews.
- **Stable frame previews:** Target, Target of Target, buffs, temporary enchant icons, and quest-related frames can be repositioned without the Edit Mode flickering seen in earlier builds.
- **NEW — Mouseover keybinding mode:** A newly added feature that did not exist in the original Reforged addon. Assign keybinds by hovering over action buttons, with explicit **Save Changes** and **Cancel** controls.
- **Safer keybinding handling:** Escape clears a hovered action button's binding provisionally, or cancels unsaved changes when not hovering over a bindable button; left/right mouse clicks are protected.
- **Reliable distribution:** Stable ZIP contains one correctly named `DragonflightUI-Reforged/` addon folder for manual or GitHub addon-manager installation.
- **Automated validation:** Lua 5.1 syntax, keybinding/Edit Mode regressions, and stable addon packaging are checked in CI.

## Future updates

Further enhancements are planned. Experimental work is preserved in the [testing branch](https://github.com/papafru/fruUI/tree/testing), including the optional **Modern Dark** visual theme, flat unit-frame and action-button designs, updated cast bars, a lean square minimap, and expanded action-button highlight options. **These experimental features are not part of the current stable release.** Development is currently paused while the existing work is retained for future updates.

## Install the stable version

**[Download the latest stable release](https://github.com/papafru/fruUI/releases/tag/v1.3.6)** — `DragonflightUI-Reforged-v1.3.6.zip`.

For a GitHub addon manager, add `papafru/fruUI` (or its future renamed repository address), select the latest stable GitHub release, and install the release ZIP. For manual installation, the TOC must be at `Interface/AddOns/DragonflightUI-Reforged/DragonflightUI-Reforged.toc`.

## Project origins and credits

This project builds upon **Dragonflight UI: Reforged** by Stormhand and earlier work by Guzruul and other contributors. The original project's description and credits follow.


---

# 🐉 Dragonflight UI: Reforged

Dragonflight UI: Reforged is a reforging of a proven legacy.

Born from the foundations of Dragonflight: Reloaded, this project is not a simple fork — it is a deliberate evolution. Every module, default, and visual decision has been revisited, refined, and reforged with a single goal: to deliver a Dragonflight-inspired interface worthy of Classic-era Azeroth.

This is a UI shaped by restraint, precision, and intent — where modern clarity meets the timeless soul of World of Warcraft.

Made for World of Warcraft Vanilla Client 1.12.

<br>

![WoW 2025-12-01 23-00-42](https://github.com/user-attachments/assets/5386c88c-9c1c-422b-84e4-e231772ee29e)

## ⚔️ A UI Forged, Not Assembled

Dragonflight UI: Reforged abandons excess in favor of mastery.

Instead of overwhelming users with endless toggles, it embraces strong visual identity and sensible defaults, allowing the UI to feel complete from the very first login — powerful, cohesive, and immersive.

Customization exists where it matters.
Silence exists where it should.

<br>

## ✨ Core Philosophy

Epic clarity over clutter

Defaults that feel intentional, not generic

Modern Dragonflight aesthetics, adapted — not copied

Classic compatibility without compromise

Performance-first, always

This UI does not try to reinvent World of Warcraft.
It sharpens it.

<br>

## 🧩 Modular by Design

Every component is forged as a module:

Enable only what you need

Clean separation of features

Profile-aware configuration

Safe coexistence with other addons

Whether you seek immersion, efficiency, or both — Reforged adapts without losing its identity.

<br>

## 🐲 From Reloaded to Reforged

Dragonflight UI: Reforged stands on the shoulders of Dragonflight: Reloaded, honoring its vision while pushing it further:

Tighter visual cohesion

Smarter defaults

Reduced redundancy

Stronger first-run experience

What once was assembled is now forged.

<br>

## 🏹 Who This UI Is For

Players who value immersion and aesthetics

Classic-era veterans seeking modern clarity

Minimalists who want power without noise

Those who believe a UI should feel inevitable, not optional

<br>

## 🔌 Immersion Compatibility

Dragonflight UI: Reforged was designed to work seamlessly alongside Immersion, a minimal and intelligent UI addon focused on cinematic gameplay and visual clarity.

Both projects share the same design philosophy:
clean presentation, invisible systems, and immersion first.

When used together, Dragonflight UI: Reforged and Immersion create a unified interface experience — modern, restrained, and deeply atmospheric — without redundant elements or visual conflict.

Automatic detection when Immersion is loaded

Safe coexistence with shared UI elements

No forced overrides or duplicated logic

Immersion is developed and maintained by the same author.

🔗 Download Immersion:
[https://github.com/Stormhand81/Immersion]

<br>

## Collector Commands

The Collector module can exclude minimap buttons from Dragonflight UI: Reforged's minimap button collector.

```text
/dfrl collector list
/dfrl collector del <ButtonName>
/dfrl collector add <ButtonName>
/dfrl collector reset
```

Use `list` to show known minimap button names, `del` to release a button back to the minimap, `add` to collect it again, and `reset` to clear all exclusions.

<br>

## 🛠️ Installation

1. Download the **latest release** of **Dragonflight UI: Reforged**
2. Extract the ZIP file
3. Ensure the folder name is exactly: DragonflightUI-Reforged
4. Place the `DragonflightUI-Reforged` folder into your WoW directory: Interface\AddOns\
5. *(Optional)* Copy the contents of `1.EXTRAS` into: Interface\
6. Restart World of Warcraft

<br>

## 📜 Credits

- **Blizzard**
- **Guzruul for Dragonflight UI 2 Reloaded**
- **Shagu**
- **DragonflightUI by Karl-Heinz-Schneider**

