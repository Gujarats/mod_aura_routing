# Restart Battle Brothers after a mod build

## Goal

Allow an explicit Windows command to stop a running Battle Brothers session and launch a fresh one after a successful mod build and deployment.

## Command interface

`build_mod.py` will provide two opt-in flags:

```powershell
python build_mod.py --launch-game
python build_mod.py --restart-game
```

`--launch-game` requests a normal Steam launch after deployment. `--restart-game` implies launch and first attempts to restart the existing Battle Brothers process.

## Restart behavior

On Windows, the builder checks for the game executable process, requests termination, waits for it to exit, force-terminates it only if the bounded wait expires, and only then sends the existing Steam URI `steam://run/365360`. The command will warn that restarting can discard unsaved game progress.

## Tests

Tests will mock all process operations and Steam calls. They will verify the normal launch flag, restart ordering, no restart action when no game process exists, and no Steam launch if the existing process does not exit.

## Scope

This is Windows-only. It does not use an undocumented Steam restart command or perform restart unless `--restart-game` is explicitly supplied.
