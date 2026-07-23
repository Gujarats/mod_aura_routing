# Restart Battle Brothers Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add explicit Windows flags for launching or restarting Battle Brothers after a successful Aura Routing mod deployment.

**Architecture:** `main()` maps `--launch-game` and `--restart-game` to explicit `ModBuilder.build()` arguments. `is_game_running()` queries the Windows process list; `restart_game()` owns process shutdown, bounded waiting, and fallback force termination; `build()` invokes it only after deploying the ZIP and immediately before the existing Steam launch boundary.

**Tech Stack:** Python standard library (`argparse`, `subprocess`, `time`, `unittest.mock`), Windows `taskkill`, Steam URI protocol.

## Global Constraints

- Windows-only behavior using the exact URI `steam://run/365360`.
- Launch or restart only after archive deployment succeeds.
- `--launch-game` is opt-in; `--restart-game` implies launch.
- Restart is explicit and warns about unsaved progress.
- Tests must not launch Steam or terminate real processes.
- No Steam-path configuration or undocumented Steam restart command.

---

### Task 1: Add tested opt-in launch and restart behavior

**Files:**
- Modify: `build_mod.py`
- Modify: `tests/test_build_mod.py`

**Interfaces:**
- Consumes: existing `ModBuilder.launch_game()` and `ModBuilder.create_zip_archives()`.
- Produces: `ModBuilder.is_game_running() -> bool`, `ModBuilder.restart_game() -> None`, and `ModBuilder.build(launch_game=False, restart_game=False) -> None`.

- [ ] **Step 1: Write failing tests**

```python
def test_build_does_not_launch_game_by_default(self):
    builder = self.create_builder_with_recorded_steps()
    builder.build()
    self.assertEqual(self.steps, ["cleanup", "brushes", "archive"])

def test_build_restarts_then_launches_when_requested(self):
    builder = self.create_builder_with_recorded_steps()
    builder.restart_game = lambda: self.steps.append("restart")
    builder.launch_game = lambda: self.steps.append("launch")
    builder.build(restart_game=True)
    self.assertEqual(self.steps, ["cleanup", "brushes", "archive", "restart", "launch"])

def test_restart_game_force_stops_after_graceful_timeout(self):
    builder = build_mod.ModBuilder.__new__(build_mod.ModBuilder)
    with patch("build_mod.platform.system", return_value="Windows"), \
         patch("build_mod.subprocess.run") as run, \
         patch("build_mod.time.sleep"), \
         patch.object(builder, "is_game_running", side_effect=[True, True, False]):
        builder.restart_game()
    self.assertEqual(run.call_args_list, [
        call(["taskkill", "/IM", "BattleBrothers.exe"], check=False),
        call(["taskkill", "/F", "/IM", "BattleBrothers.exe"], check=False),
    ])
```

- [ ] **Step 2: Run tests to verify RED**

Run: `python -m unittest tests.test_build_mod -v`

Expected: FAIL because `build()` launches without a flag, does not accept arguments, and `restart_game()` does not exist.

- [ ] **Step 3: Add minimal implementation**

```python
GAME_PROCESS_NAME = "BattleBrothers.exe"

def is_game_running(self):
    result = subprocess.run(
        ["tasklist", "/FI", f"IMAGENAME eq {GAME_PROCESS_NAME}", "/NH"],
        capture_output=True,
        text=True,
        check=True,
    )
    return GAME_PROCESS_NAME.lower() in result.stdout.lower()

def restart_game(self):
    """Stop Battle Brothers before requesting a fresh Steam launch on Windows."""
    if platform.system() != "Windows":
        return
    print("Restarting Battle Brothers; unsaved game progress may be lost.")
    if not self.is_game_running():
        return
    subprocess.run(["taskkill", "/IM", GAME_PROCESS_NAME], check=False)
    for _ in range(8):
        time.sleep(0.25)
        if not self.is_game_running():
            return
    subprocess.run(["taskkill", "/F", "/IM", GAME_PROCESS_NAME], check=False)

def build(self, launch_game=False, restart_game=False):
    # Preserve existing build and deployment operations.
    self.create_zip_archives()
    if restart_game:
        self.restart_game()
        launch_game = True
    if launch_game:
        self.launch_game()
```

Add parser arguments with `action="store_true"`, and call:

```python
builder.build(launch_game=args.launch_game or args.restart_game, restart_game=args.restart_game)
```

- [ ] **Step 4: Run focused tests to verify GREEN**

Run: `python -m unittest tests.test_build_mod -v`

Expected: PASS, with no real Steam launch or process termination.

- [ ] **Step 5: Run syntax and command-interface checks**

Run:

```powershell
python -m py_compile build_mod.py
python build_mod.py --help
```

Expected: exit code 0; help lists `--launch-game` and `--restart-game`.

- [ ] **Step 6: Commit implementation**

```powershell
git add -- build_mod.py tests/test_build_mod.py
git commit -m "Add opt-in game restart"
```
