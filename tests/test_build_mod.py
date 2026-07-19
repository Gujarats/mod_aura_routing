import unittest
from unittest.mock import MagicMock, patch

import build_mod


class ModBuilderLaunchGameTests(unittest.TestCase):
    def test_launch_game_opens_battle_brothers_steam_uri_on_windows(self):
        builder = build_mod.ModBuilder.__new__(build_mod.ModBuilder)

        with patch("build_mod.platform.system", return_value="Windows"), patch(
            "build_mod.subprocess.run"
        ) as run:
            builder.launch_game()

        run.assert_called_once_with(
            ["cmd", "/c", "start", "", "steam://run/365360"], check=True
        )

    def test_launch_game_does_nothing_off_windows(self):
        builder = build_mod.ModBuilder.__new__(build_mod.ModBuilder)

        with patch("build_mod.platform.system", return_value="Linux"), patch(
            "build_mod.subprocess.run"
        ) as run:
            builder.launch_game()

        run.assert_not_called()

    def test_build_launches_game_after_archive_deployment(self):
        builder = build_mod.ModBuilder.__new__(build_mod.ModBuilder)
        builder.build_dir = MagicMock()
        builder.build_dir.exists.return_value = False
        steps = []
        builder.prebuild_cleanup = lambda: steps.append("cleanup")
        builder.build_brushes = lambda: steps.append("brushes")
        builder.create_zip_archives = lambda: steps.append("archive")
        builder.launch_game = lambda: steps.append("launch")

        builder.build()

        self.assertEqual(steps, ["cleanup", "brushes", "archive", "launch"])


if __name__ == "__main__":
    unittest.main()
