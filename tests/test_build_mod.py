import unittest
from unittest.mock import MagicMock, call, patch

import build_mod


class ModBuilderLaunchGameTests(unittest.TestCase):
    def make_builder(self):
        builder = build_mod.ModBuilder.__new__(build_mod.ModBuilder)
        builder.build_dir = MagicMock()
        builder.build_dir.exists.return_value = False
        return builder

    def test_launch_game_opens_battle_brothers_steam_uri_on_windows(self):
        builder = self.make_builder()

        with patch("build_mod.platform.system", return_value="Windows"), patch(
            "build_mod.subprocess.run"
        ) as run:
            builder.launch_game()

        run.assert_called_once_with(
            ["cmd", "/c", "start", "", "steam://run/365360"], check=True
        )

    def test_launch_game_does_nothing_off_windows(self):
        builder = self.make_builder()

        with patch("build_mod.platform.system", return_value="Linux"), patch(
            "build_mod.subprocess.run"
        ) as run:
            builder.launch_game()

        run.assert_not_called()

    def test_build_does_not_launch_game_by_default(self):
        builder = self.make_builder()
        steps = []
        builder.prebuild_cleanup = lambda: steps.append("cleanup")
        builder.build_brushes = lambda: steps.append("brushes")
        builder.create_zip_archives = lambda: steps.append("archive")
        builder.launch_game = lambda: steps.append("launch")
        builder.restart_game = lambda: steps.append("restart")

        builder.build()

        self.assertEqual(steps, ["cleanup", "brushes", "archive"])

    def test_build_launches_game_after_archive_when_requested(self):
        builder = self.make_builder()
        steps = []
        builder.prebuild_cleanup = lambda: steps.append("cleanup")
        builder.build_brushes = lambda: steps.append("brushes")
        builder.create_zip_archives = lambda: steps.append("archive")
        builder.launch_game = lambda: steps.append("launch")
        builder.restart_game = lambda: steps.append("restart")

        builder.build(launch_game=True)

        self.assertEqual(steps, ["cleanup", "brushes", "archive", "launch"])

    def test_build_restarts_then_launches_after_archive_when_requested(self):
        builder = self.make_builder()
        steps = []
        builder.prebuild_cleanup = lambda: steps.append("cleanup")
        builder.build_brushes = lambda: steps.append("brushes")
        builder.create_zip_archives = lambda: steps.append("archive")
        builder.launch_game = lambda: steps.append("launch")
        builder.restart_game = lambda: steps.append("restart")

        builder.build(launch_game=True, restart_game=True)

        self.assertEqual(steps, ["cleanup", "brushes", "archive", "restart", "launch"])

    def test_archive_exception_prevents_restart_and_launch(self):
        builder = self.make_builder()
        builder.prebuild_cleanup = MagicMock()
        builder.build_brushes = MagicMock()
        builder.create_zip_archives = MagicMock(side_effect=RuntimeError("archive failed"))
        builder.restart_game = MagicMock()
        builder.launch_game = MagicMock()

        with self.assertRaises(SystemExit):
            builder.build(launch_game=True, restart_game=True)

        builder.restart_game.assert_not_called()
        builder.launch_game.assert_not_called()


class ModBuilderRestartGameTests(unittest.TestCase):
    def test_is_game_running_matches_tasklist_stdout_case_insensitively(self):
        builder = build_mod.ModBuilder.__new__(build_mod.ModBuilder)
        result = MagicMock(stdout="battlebrothers.EXE                 1234 Console")

        with patch("build_mod.subprocess.run", return_value=result) as run:
            self.assertTrue(builder.is_game_running())

        run.assert_called_once_with(
            ["tasklist", "/FI", "IMAGENAME eq BattleBrothers.exe", "/NH"],
            capture_output=True,
            text=True,
            check=True,
        )

    def test_restart_game_does_not_kill_when_game_is_absent(self):
        builder = build_mod.ModBuilder.__new__(build_mod.ModBuilder)

        with patch("build_mod.platform.system", return_value="Windows"), patch.object(
            builder, "is_game_running", return_value=False
        ), patch("build_mod.subprocess.run") as run:
            builder.restart_game()

        run.assert_not_called()

    def test_restart_game_allows_graceful_exit_without_force_kill(self):
        builder = build_mod.ModBuilder.__new__(build_mod.ModBuilder)

        with patch("build_mod.platform.system", return_value="Windows"), patch.object(
            builder, "is_game_running", side_effect=[True, False]
        ), patch("build_mod.subprocess.run") as run, patch("build_mod.time.sleep") as sleep:
            builder.restart_game()

        run.assert_called_once_with(
            ["taskkill", "/IM", "BattleBrothers.exe"], check=True
        )
        sleep.assert_called_once_with(0.25)

    def test_restart_game_force_kills_a_persistent_process(self):
        builder = build_mod.ModBuilder.__new__(build_mod.ModBuilder)

        with patch("build_mod.platform.system", return_value="Windows"), patch.object(
            builder, "is_game_running", side_effect=[True] * 9
        ), patch("build_mod.subprocess.run") as run, patch("build_mod.time.sleep") as sleep:
            builder.restart_game()

        self.assertEqual(
            run.call_args_list,
            [
                call(["taskkill", "/IM", "BattleBrothers.exe"], check=True),
                call(["taskkill", "/F", "/IM", "BattleBrothers.exe"], check=True),
            ],
        )
        self.assertEqual(sleep.call_count, 8)


class MainTests(unittest.TestCase):
    def test_restart_flag_implies_launch(self):
        builder = MagicMock()

        with patch("build_mod.ModBuilder", return_value=builder), patch(
            "build_mod.sys.argv", ["build_mod.py", "--restart-game"]
        ):
            build_mod.main()

        builder.build.assert_called_once_with(launch_game=True, restart_game=True)


if __name__ == "__main__":
    unittest.main()
