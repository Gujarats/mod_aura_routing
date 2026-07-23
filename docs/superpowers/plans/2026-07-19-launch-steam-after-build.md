# Launch Steam After Build Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `python build_mod.py` launch Battle Brothers via Steam after a successful Windows build and deployment.

**Architecture:** Keep the Steam boundary in `ModBuilder.launch_game()` and invoke it after `create_zip_archives()` returns. Use the Windows `start` command with the registered Steam URI, so no Steam installation path is required. Unit tests patch that process boundary.

**Tech Stack:** Python standard library, `unittest`, Windows shell, Steam URI protocol.

## Global Constraints

- Windows-only behavior using the exact URI `steam://run/365360`.
- Launch only after the archive is successfully deployed.
- Do not add Steam-path configuration or a command-line flag.
- Tests must not launch Steam.

---

### Task 1: Add tested Steam launch behavior

**Files:**
- Create: `tests/test_build_mod.py`
- Modify: `build_mod.py:5-12, 133-157`

**Interfaces:**
- Consumes: `ModBuilder.build()` and its existing `create_zip_archives()` method.
- Produces: `ModBuilder.launch_game() -> None`, which invokes the Steam URI on Windows.

- [ ] **Step 1: Write the failing tests**

```python
from pathlib import Path
from tempfile import TemporaryDirectory
from unittest.mock import patch
import unittest

from build_mod import ModBuilder


class ModBuilderTests(unittest.TestCase):
    def test_launch_game_uses_the_battle_brothers_steam_uri_on_windows(self):
        with TemporaryDirectory() as temp_dir:
            builder = ModBuilder(repo_dir=Path(temp_dir), build_dir=Path(temp_dir) / "build")
            with patch("build_mod.platform.system", return_value="Windows"), patch("build_mod.subprocess.run") as run:
                builder.launch_game()

        run.assert_called_once_with(
            ["cmd", "/c", "start", "", "steam://run/365360"],
            check=True,
        )

    def test_build_launches_only_after_archives_are_created(self):
        with TemporaryDirectory() as temp_dir:
            builder = ModBuilder(repo_dir=Path(temp_dir), build_dir=Path(temp_dir) / "build")
            events = []
            builder.prebuild_cleanup = lambda: events.append("cleanup")
            builder.build_brushes = lambda: events.append("brushes")
            builder.create_zip_archives = lambda: events.append("archive")
            builder.launch_game = lambda: events.append("launch")

            builder.build()

        self.assertEqual(events, ["cleanup", "brushes", "archive", "launch"])


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `python -m unittest tests.test_build_mod -v`

Expected: FAIL because `ModBuilder` has no `launch_game` method and `build()` does not invoke it.

- [ ] **Step 3: Add the minimal implementation**

```python
import subprocess

# Add this method to ModBuilder.
def launch_game(self):
    """Launch Battle Brothers through Steam on Windows."""
    if platform.system() != "Windows":
        return

    print("Launching Battle Brothers through Steam...")
    subprocess.run(
        ["cmd", "/c", "start", "", "steam://run/365360"],
        check=True,
    )

# In ModBuilder.build(), immediately after self.create_zip_archives():
self.launch_game()
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `python -m unittest tests.test_build_mod -v`

Expected: PASS with 2 tests.

- [ ] **Step 5: Run the full project test suite and syntax check**

Run: `python -m unittest discover -v; python -m py_compile build_mod.py`

Expected: exit code 0.

- [ ] **Step 6: Commit the implementation**

```powershell
git add -- build_mod.py tests/test_build_mod.py
git commit -m "Launch Battle Brothers after build"
```
