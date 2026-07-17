# Build output and Steam launch design

## Purpose

Make the Python builder's resolved configuration and progress easy to read, and let a user opt in to launching Battle Brothers after a successful deployment.

## Command interface

`python build_mod.py` retains its current behavior: build and deploy the mod archive without starting the game.

`python build_mod.py --launch-game` builds and deploys the archive, then opens Battle Brothers through Steam using the game's `steam://run/365360` URI.

## Output

At startup, the builder prints a Configuration block containing the resolved Battle Brothers data directory, repository directory, build directory, and whether post-deployment launching is enabled.

The build reports clear numbered phases: optional brush building, ZIP packaging, and deployment. After a successful deployment, the builder prints either that launching was skipped or that it is launching Battle Brothers through Steam.

## Safety and failures

Steam is started only after the archive has been successfully moved to the configured Battle Brothers data directory and only when `--launch-game` was supplied.

If building, packaging, or deployment fails, the existing error handling reports the failure and Steam is not opened. The builder does not delete the source `scripts/` directory.

## Verification

Tests will verify argument parsing, readable configuration output, Steam launch invocation only after successful deployment, and the absence of source-script deletion from the build flow. Existing user modifications to `build_mod.py` will be preserved.
