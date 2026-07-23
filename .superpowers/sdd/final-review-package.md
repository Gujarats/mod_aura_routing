# Whole-branch review package

Base: `d3c574a` (`main` merge-base)  
Head: `cfda7e2`

## Commits

- `c9a6603 Document Steam launch design`
- `cfda7e2 Launch Battle Brothers after build`

## Branch changes

- Adds a design specification documenting a Windows-only launch after successful ZIP deployment.
- Adds `import subprocess` to `build_mod.py`.
- Adds `ModBuilder.launch_game()`, which returns off Windows and otherwise calls `subprocess.run(["cmd", "/c", "start", "", "steam://run/365360"], check=True)`.
- Calls `self.launch_game()` immediately after `self.create_zip_archives()` returns.
- Adds `tests/test_build_mod.py` with Windows-command, non-Windows no-op, and build-order tests. Steam invocation is patched in all tests.

## Validation evidence

- Focused test command: `python -m unittest tests.test_build_mod -v` — 3 tests passed.
- Syntax check: `python -m py_compile build_mod.py` — passed.
- `python -m unittest discover -v` is blocked in unrelated `buildscript.python.upload` by `ModuleNotFoundError: No module named 'requests'`.
- Task review verdict: PASS, no blocking or high-severity findings.

## Requirements

- Windows-only behavior using the exact URI `steam://run/365360`.
- Launch only after the archive is successfully deployed.
- No Steam-path configuration or command-line flag.
- Tests must not launch Steam.
