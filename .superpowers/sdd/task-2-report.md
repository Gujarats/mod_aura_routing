# Task 2 report: opt-in game restart

## Scope

Modified only `build_mod.py` and `tests/test_build_mod.py` for the implementation. This report records the requested verification evidence.

## RED evidence

Command run before production edits:

```text
python -m unittest tests.test_build_mod -v
```

Result: exit code 1; 11 tests run with 1 failure and 8 errors. Expected feature-missing failures included:

```text
TypeError: ModBuilder.build() got an unexpected keyword argument 'launch_game'
AttributeError: 'ModBuilder' object has no attribute 'is_game_running'
python.exe -m unittest: error: unrecognized arguments: --restart-game
```

The default-launch regression test also failed because the old build implementation appended `launch` without an opt-in flag.

## GREEN evidence

After implementing the minimal behavior, the following commands all exited 0:

```text
python -m unittest tests.test_build_mod -v
python -m py_compile build_mod.py
python build_mod.py --help
```

Focused-suite result: `Ran 11 tests in 0.005s` and `OK`.

## Coverage added

- Default build does not launch Steam.
- `--launch-game` launches only after archive deployment.
- `--restart-game` implies launch and restarts after deployment.
- Missing process does not call `taskkill`.
- Graceful exit does not force-kill.
- A process still present after eight polls receives `taskkill /F`.
- Archive errors prevent restart and launch.
- Steam and process interactions are mocked; no real process is started or stopped.

## Reviewer follow-up: post-force termination guard

### Root cause

`restart_game()` previously returned immediately after `taskkill /F`, so `build()` could call Steam even when `BattleBrothers.exe` was still reported as running.

### RED evidence

After adding the persistent-process regression, the focused suite exited 1 with two expected failures:

```text
FAIL: test_persistent_process_after_force_kill_prevents_launch
AssertionError: RuntimeError not raised

FAIL: test_restart_game_force_kills_a_persistent_process
AssertionError: RuntimeError not raised
```

The process mock remained present through the initial check, eight polls, and the post-force state check.

### Fix and GREEN evidence

After `taskkill /F`, `restart_game()` now calls `is_game_running()` again and raises:

```text
Battle Brothers is still running after force termination.
```

`build()` handles that operational error with its existing `SystemExit(1)` path, so it never calls `launch_game()`.

Commands run after the fix:

```text
python -m unittest tests.test_build_mod -v
python -m py_compile build_mod.py
```

Both exited 0. The focused suite reported `Ran 12 tests` and `OK`.
