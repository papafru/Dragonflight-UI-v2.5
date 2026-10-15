# Dragonflight UI: Reforged v2.5

**An enhanced version of Dragonflight UI: Reforged for classic-era World of Warcraft.** Built on the original addon, with new functionality, quality-of-life improvements, and more updates planned for the future.

> **Current stable addon release: v1.3.6.** “v2.5” is the GitHub project name, **not** the in-game addon version. The original `DragonflightUI-Reforged` addon folder, in-game name, and SavedVariables remain unchanged for compatibility.

[**Download the stable release**](https://github.com/papafru/DragonflightUI-Reforged-v2.5/releases/tag/v1.3.6) · [Experimental development (`testing`)](https://github.com/papafru/DragonflightUI-Reforged-v2.5/tree/testing)

![Original Dragonflight UI: Reforged interface (upstream screenshot)](https://github.com/user-attachments/assets/5386c88c-9c1c-422b-84e4-e231772ee29e)

*Screenshot from the original Dragonflight UI: Reforged project. The stable build retains its original visual style.*

## What's new in this enhanced version

These features are included in the **stable v1.3.6** release:

- **New mouseover keybinding system:** Assign keybinds by hovering over action-bar buttons. This is an addition to Reforged, not merely an update to an existing keybinding feature.
- **Safer binding changes:** Explicit **Save Changes** and **Cancel** controls. Escape clears a hovered button's binding provisionally; pressing Escape away from a bindable button cancels unsaved changes. Left and right mouse clicks cannot be assigned accidentally.
- **Improved Edit Mode:** Move supported UI elements with clearly labeled drag handles and more reliable position previews.
- **Frame-positioning fixes:** More stable Edit Mode previews for Target, Target of Target, buffs, temporary enchant icons, and quest-related frames, including fixes for flickering elements.
- **Preserved appearance:** The stable version keeps Reforged's original visuals rather than introducing unfinished redesigns.

## Installation

**Recommended:** Download `DragonflightUI-Reforged-v1.3.6.zip` from [GitHub Releases](https://github.com/papafru/DragonflightUI-Reforged-v2.5/releases/tag/v1.3.6). This is the packaged addon build, not the repository's **Code → Download ZIP** development archive.

1. Extract the release ZIP.
2. Copy the folder `DragonflightUI-Reforged` to your game's `Interface/AddOns/` directory.
3. Verify that the file is located at `Interface/AddOns/DragonflightUI-Reforged/DragonflightUI-Reforged.toc`.
4. Launch or restart the game.

**GitHub addon managers:** Use `papafru/DragonflightUI-Reforged-v2.5` and select the **latest stable release asset** if your manager supports GitHub Releases. The ZIP has a single `DragonflightUI-Reforged/` root folder.

## Future updates

Development is **currently paused**. Experimental work is preserved in the [`testing` branch](https://github.com/papafru/DragonflightUI-Reforged-v2.5/tree/testing), including:

- Optional **Modern Dark** visual theme, redesigned action-button and unit-frame styling.
- Modernized Player/Target cast-bar appearance.
- Thin, square minimap style and updated zone/time header.
- Extra action-button highlight options, including a visibility toggle and black highlight color.

**These experimental features are not included in the stable release** and are awaiting further in-game testing before any future release.

## Credits and project origins

This is a community enhancement of **[Dragonflight UI: Reforged](https://github.com/Stormhand-dev/DragonflightUI-Reforged)**, based on the work of **Stormhand** and **Guzruul** (Dragonflight UI 2 Reloaded). Thanks also to **Shagu**, **Karl-Heinz-Schneider**, **Blizzard**, and the earlier Dragonflight UI contributors acknowledged by the original project.

Original addon credit and the legacy internal addon identity are intentionally retained. This repository is an enhanced continuation, not an official Blizzard project.
