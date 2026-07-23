# Task 1: Launch Battle Brothers after build

## Scope

- Modified `build_mod.py`.
- Added `tests/test_build_mod.py`.
- Left the pre-existing deletion of `gfx/aura_routing_effect.png` and documentation changes untouched.

## RED evidence

Command run before production changes:

```powershell
python -m unittest tests.test_build_mod -v
```

Result: expected failure (`FAILED (failures=1, errors=2)`).

- Both launch tests errored because `build_mod.subprocess` did not yet exist.
- The build-order test failed because the actual sequence ended at `archive`, without `launch`.

This demonstrated that the requested import, launch method, and post-archive call were absent.

## GREEN implementation

- Imported `subprocess`.
- Added `ModBuilder.launch_game()`: it returns immediately off Windows and otherwise runs `cmd /c start "" steam://run/365360` with `check=True`.
- Called `launch_game()` immediately after `create_zip_archives()` in `build()`.
- Added isolated tests for the Windows command, non-Windows no-op, and build-step ordering. Steam is always patched in tests.

## GREEN evidence

```powershell
python -m unittest tests.test_build_mod -v
```

Result: `Ran 3 tests ... OK`.

```powershell
python -m py_compile build_mod.py
```

Result: exit code 0.

## Full-discovery check

```powershell
python -m unittest discover -v
```

Result: blocked by a pre-existing unrelated import failure in `buildscript.python.upload`: `ModuleNotFoundError: No module named 'requests'`. The upload package prints `Missing dependencies! Run: pip install requests tqdm dacite` and exits during discovery. The focused Task 1 suite is green.

## Self-review

- The command exactly matches the required Steam URI and argument sequence.
- The platform guard prevents Steam invocation outside Windows.
- `check=True` propagates a failed launcher command instead of reporting a successful build.
- The launch is sequenced only after archive deployment returns successfully.
- No Steam path configuration or command-line flag was added.
