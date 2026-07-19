# Launch Battle Brothers after a successful build

## Goal

Superseded by the opt-in launch design: normal `python build_mod.py` builds and deploys the Aura Routing ZIP without launching the game. Use `python build_mod.py --launch-game` to request a Steam launch.

## Design

`ModBuilder` will gain a small `launch_game()` method. On Windows it invokes the Steam game URI `steam://run/365360` through the Windows shell. The URI delegates Steam discovery to Windows, so the builder does not need to know Steam's installation directory.

`build()` will call `launch_game()` only after `create_zip_archives()` has completed. A failed build or deploy exits before the launch request, so a stale or absent archive does not trigger the game.

## Error handling

The launch request is part of a successful build. If Windows cannot start the URI, the builder reports the exception through its existing unexpected-error path and exits non-zero.

## Tests

Add a unit test that creates a builder with temporary paths and mocks the Windows launch boundary. It will assert that Windows uses `steam://run/365360` and that the test does not open Steam. A second test will confirm the build sequence launches only after archiving succeeds.

## Scope

This change is Windows-only. It does not add a command-line switch, Steam-path configuration, or non-Windows behavior.
