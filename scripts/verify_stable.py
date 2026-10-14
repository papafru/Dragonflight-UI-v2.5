#!/usr/bin/env python3
"""Validate stable source relative to pre-theme fruUI."""
from pathlib import Path
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
toc = (root / "DragonflightUI-Reforged.toc").read_text(encoding="utf-8")
errors = []
if "## Version: 1.3.6" not in toc:
    errors.append("Incorrect stable version")
if "DFRL_THEME_STATE" in toc:
    errors.append("Experimental theme SavedVariable present")
count = 0
for line in toc.splitlines():
    src = line.strip()
    if not src or src.startswith("#"):
        continue
    count += 1
    if not (root / src.replace("\\", "/")).is_file():
        errors.append("Missing TOC module: " + src)
for name in ("core/theme.lua", "core/theme_ui.lua", "core/theme_welcome.lua",
             "modules/bars/skins.lua", "modules/unit/skins.lua",
             "modules/map/skins.lua", "modules/cast/skins.lua", "modules/gui/themes.lua"):
    if (root / name).exists():
        errors.append("Experimental appearance module present: " + name)
baseline = "b4062b7e27e27eace568d14d8a6efc296d2bd5b4"
allowed = {
    "modules/bars/hoverbind.lua", "modules/frames/frames.lua",
    "modules/menu/editmode.lua", "DragonflightUI-Reforged.toc",
    "README.md", "RELEASE_NOTES.md", "tests/editmode_keybind.lua",
    "tests/editmode_preview.lua", "scripts/verify_stable.py",
    ".github/workflows/stable-release.yml",
}
changed = subprocess.check_output(
    ["git", "diff", "--name-only", baseline, "HEAD"],
    text=True, cwd=root).splitlines()
for path in changed:
    if path not in allowed:
        errors.append("Unapproved deviation from pre-theme baseline: " + path)
if errors:
    print("\n".join("ERROR: " + x for x in errors))
    sys.exit(1)
print("PASS:", count, "TOC modules;", len(changed), "allowlisted changes; no themes")
