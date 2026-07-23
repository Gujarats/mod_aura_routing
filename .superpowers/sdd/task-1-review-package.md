# Review package: Task 1

Base: `c9a6603`  
Head: `cfda7e2`

## Commit

`cfda7e2 Launch Battle Brothers after build`

## Files changed

- `build_mod.py`
- `tests/test_build_mod.py`

## Diff

```diff
diff --git a/build_mod.py b/build_mod.py
index c38bf03..6f5a501 100644
--- a/build_mod.py
+++ b/build_mod.py
@@
 import shutil
 import argparse
+import subprocess
 from pathlib import Path
 import platform
@@
+    def launch_game(self):
+        """Launch Battle Brothers through Steam on Windows."""
+        if platform.system() != "Windows":
+            return
+
+        subprocess.run(
+            ["cmd", "/c", "start", "", "steam://run/365360"], check=True
+        )
+
     def build(self):
@@
             # Create zip archives
             self.create_zip_archives()
 
+            self.launch_game()
+
             print("Legends mod build completed successfully!")
diff --git a/tests/test_build_mod.py b/tests/test_build_mod.py
new file mode 100644
--- /dev/null
+++ b/tests/test_build_mod.py
@@
+import unittest
+from unittest.mock import MagicMock, patch
+
+import build_mod
+
+
+class ModBuilderLaunchGameTests(unittest.TestCase):
+    def test_launch_game_opens_battle_brothers_steam_uri_on_windows(self):
+        builder = build_mod.ModBuilder.__new__(build_mod.ModBuilder)
+
+        with patch("build_mod.platform.system", return_value="Windows"), patch(
+            "build_mod.subprocess.run"
+        ) as run:
+            builder.launch_game()
+
+        run.assert_called_once_with(
+            ["cmd", "/c", "start", "", "steam://run/365360"], check=True
+        )
+
+    def test_launch_game_does_nothing_off_windows(self):
+        builder = build_mod.ModBuilder.__new__(build_mod.ModBuilder)
+
+        with patch("build_mod.platform.system", return_value="Linux"), patch(
+            "build_mod.subprocess.run"
+        ) as run:
+            builder.launch_game()
+
+        run.assert_not_called()
+
+    def test_build_launches_game_after_archive_deployment(self):
+        builder = build_mod.ModBuilder.__new__(build_mod.ModBuilder)
+        builder.build_dir = MagicMock()
+        builder.build_dir.exists.return_value = False
+        steps = []
+        builder.prebuild_cleanup = lambda: steps.append("cleanup")
+        builder.build_brushes = lambda: steps.append("brushes")
+        builder.create_zip_archives = lambda: steps.append("archive")
+        builder.launch_game = lambda: steps.append("launch")
+
+        builder.build()
+
+        self.assertEqual(steps, ["cleanup", "brushes", "archive", "launch"])
+
+
+if __name__ == "__main__":
+    unittest.main()
```
