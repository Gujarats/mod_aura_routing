### Task 2: Add tested opt-in launch and restart behavior

Read the binding specification at `docs/superpowers/specs/2026-07-19-restart-battle-brothers-design.md` and implement only this task.

## Files

- Modify `build_mod.py`
- Modify `tests/test_build_mod.py`

## Requirements

- Windows-only behavior uses exact `steam://run/365360`.
- Launch/restart only after successful archive deployment.
- `--launch-game` is opt-in.
- `--restart-game` implies launch.
- Warn of unsaved progress on restart.
- Tests must not launch Steam or terminate real processes.
- Do not add Steam-path configuration or undocumented Steam commands.

## Interfaces

Implement `ModBuilder.is_game_running() -> bool`, `ModBuilder.restart_game() -> None`, and revise `ModBuilder.build(launch_game=False, restart_game=False) -> None`.

`is_game_running()` uses:

```python
subprocess.run(
    ["tasklist", "/FI", "IMAGENAME eq BattleBrothers.exe", "/NH"],
    capture_output=True, text=True, check=True,
)
```

and returns whether `BattleBrothers.exe` is in stdout, case-insensitively.

`restart_game()` on Windows prints a warning; returns without action when the process is absent; otherwise calls `taskkill /IM BattleBrothers.exe`, polls every 0.25 seconds for at most eight checks, and calls `taskkill /F /IM BattleBrothers.exe` only if it remains running. Off Windows it returns without action.

Add argparse flags `--launch-game` and `--restart-game` using `action="store_true"`. Call `builder.build(launch_game=args.launch_game or args.restart_game, restart_game=args.restart_game)`.

## Test-first requirement

First revise/add tests to cover: default no launch; `--launch-game` launch after archive; `--restart-game` restart then launch after archive; absent game means no taskkill; graceful exit avoids force kill; persistent process gets force kill; archive exception prevents restart/launch. Mock all process and Steam interactions. Run `python -m unittest tests.test_build_mod -v` and capture the expected RED output before production edits. After implementation, run the focused suite, `python -m py_compile build_mod.py`, and `python build_mod.py --help`. Commit only `build_mod.py` and `tests/test_build_mod.py` as `Add opt-in game restart`.
