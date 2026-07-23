### Task 1: Add tested Steam launch behavior

**Files:**
- Create: `tests/test_build_mod.py`
- Modify: `build_mod.py:5-12, 133-157`

**Interfaces:**
- Consumes: `ModBuilder.build()` and its existing `create_zip_archives()` method.
- Produces: `ModBuilder.launch_game() -> None`, which invokes the Steam URI on Windows.

## Binding requirements

- Windows-only behavior using the exact URI `steam://run/365360`.
- Launch only after the archive is successfully deployed.
- Do not add Steam-path configuration or a command-line flag.
- Tests must not launch Steam.

## Required test-first cycle

Create `tests/test_build_mod.py` with tests asserting `launch_game()` calls:

```python
["cmd", "/c", "start", "", "steam://run/365360"]
```

via a patched `build_mod.subprocess.run`, using `check=True`. Add a test that stubs the build steps and asserts the sequence is `cleanup`, `brushes`, `archive`, `launch`.

Run `python -m unittest tests.test_build_mod -v` and record the expected RED failure before production code. Then import `subprocess`, add `ModBuilder.launch_game()` that returns without action off Windows and otherwise calls the command above with `check=True`, and call it immediately after `self.create_zip_archives()` in `build()`.

Verify with:

```powershell
python -m unittest tests.test_build_mod -v
python -m unittest discover -v
python -m py_compile build_mod.py
```

Commit only `build_mod.py` and `tests/test_build_mod.py` with message `Launch Battle Brothers after build`.
