# Opt-in Steam launch after a mod build

## Goal

Keep `python build_mod.py` as a build-and-deploy command by default, and launch Battle Brothers only when explicitly requested.

## Command interface

`build_mod.py` will accept a boolean `--launch-game` flag.

```powershell
python build_mod.py
python build_mod.py --launch-game
```

Without the flag, the builder creates and deploys the mod ZIP without contacting Steam. With the flag, it requests Steam to launch Battle Brothers only after ZIP deployment succeeds.

## Implementation

`main()` passes the parsed flag to `ModBuilder.build(launch_game=False)`. The builder preserves its existing build sequence and invokes `launch_game()` after `create_zip_archives()` only when `launch_game` is true. The Windows launcher continues to use the exact URI `steam://run/365360`.

## Existing game process

The builder sends a launch request to Steam and does not inspect running processes. Steam determines how to handle a request for an already-running game.

## Tests

Unit tests will establish that build order excludes launch by default, includes it after successful archive deployment when enabled, and does not reach launch when archiving raises an exception. Steam remains mocked in every test.

## Scope

This is a Windows-only launch option. It does not add process detection, Steam-path configuration, or a stop/restart capability.
