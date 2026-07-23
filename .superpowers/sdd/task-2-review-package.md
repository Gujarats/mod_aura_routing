# Task 2 review package

Base: `e0a9177`  
Head: `8367e5a`

## Implementation summary

- Adds `time` import.
- Adds `ModBuilder.is_game_running()` using `tasklist /FI "IMAGENAME eq BattleBrothers.exe" /NH`.
- Adds Windows-only `restart_game()` that warns about unsaved progress, invokes `taskkill /IM BattleBrothers.exe`, polls eight times at 0.25 seconds, and invokes `taskkill /F /IM BattleBrothers.exe` if still running.
- Changes `build(launch_game=False, restart_game=False)` to deploy first, then restart, then launch only when flags request it.
- Adds `--launch-game` and `--restart-game`; restart implies launch.
- Adds unit coverage for default behavior, launch/restart sequence, archive exception, process detection, absent/game graceful/force stop, and parser semantics.

## Requirements

- Windows-only exact Steam URI `steam://run/365360`.
- Launch/restart only after successful archive deployment.
- Opt-in launch; restart implies launch.
- Explicit warning about unsaved progress.
- No real Steam/process calls in tests.
- No Steam path configuration or undocumented Steam restart command.

## Test evidence

`python -m unittest tests.test_build_mod -v`: 11 passed.  
`python -m py_compile build_mod.py`: passed.  
`python build_mod.py --help`: passed and lists both flags.
