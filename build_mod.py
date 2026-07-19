#!/usr/bin/env python3
"""
OS-agnostic main build script for Legends mod
Replaces build_legends_mod.sh with cross-platform Python implementation
"""

import os
import sys
import shutil
import argparse
import subprocess
import time
from pathlib import Path
import platform
from buildscript.lib import VersionExtractor, BuildError, load_config

class ModBuilder:
    def __init__(self, bb_dir=None, repo_dir=None, build_dir=None):
        # Load config first
        config = load_config(Path(__file__).parent / ".build_config.py")

        # Use provided values, fall back to config, then to defaults
        if repo_dir is None:
            repo_dir = Path.cwd()
        if build_dir is None:
            build_dir = repo_dir / "build"

        # Set default paths based on OS if still None
        if bb_dir is None:
            if platform.system() == "Windows":
                bb_dir = r"C:\Program Files (x86)\Steam\steamapps\common\Battle Brothers\data"
            else:
                bb_dir = os.path.expanduser(
                    "~/.local/share/Steam/steamapps/common/Battle Brothers/data"
                )

        self.bb_dir = Path(bb_dir)
        self.repo_dir = repo_dir
        self.build_dir = Path(build_dir)
        self.current_dir = Path.cwd()
        # self.version_extractor = VersionExtractor(self.current_dir)

        print(f"Battle Brothers directory: {self.bb_dir}")
        print(f"Repository directory: {self.repo_dir}")
        print(f"Build directory: {self.build_dir}")
        print(f"Current directory: {self.current_dir}")

    def prebuild_cleanup(self):
        """Clean up generated folders and PNGs before building"""
        try:
            # Remove generated directories
            for rel in [
                "brushes",
                "build",
                "helmet_scripts",
                "legend_armor_scripts",
            ]:
                p = self.current_dir / rel
                if p.exists():
                    print(f"Deleting {p} ...")
                    shutil.rmtree(p, ignore_errors=True)

            # Remove top-level gfx PNGs
            gfx_dir = self.current_dir / "gfx"
            if gfx_dir.exists():
                for png in gfx_dir.glob("*.png"):
                    try:
                        print(f"Deleting {png}")
                        png.unlink()
                    except Exception:
                        pass

            # Remove gfx/ui PNGs
            gfx_ui_dir = gfx_dir / "ui"
            if gfx_ui_dir.exists():
                for png in gfx_ui_dir.glob("*.png"):
                    try:
                        print(f"Deleting {png} ...")
                        png.unlink()
                    except Exception:
                        pass

        except Exception as e:
            print(f"Warning: cleanup error {e}")

    def artifact_name_mod(self):
        """Generate mod artifact name"""
        # version = self.version_extractor.extract_version()
        # hardcoded for now
        return f"mod_aura_routing.zip"

    def artifact_name_assets(self):
        """Generate assets artifact name"""
        assets_version = self.version_extractor.get_legends_assets_version()
        return f"mod_legends-assets-{assets_version}.zip"

    def build_brushes(self):
        """Build brushes using the brush builder"""
        from build_brushes import BrushBuilder
        BrushBuilder(self.build_dir,self.repo_dir).build()

    def _merge_directories(self, src_dir, dest_dir):
        """Merge source directory into destination, preserving existing content"""
        for item in src_dir.rglob("*"):
            if item.is_file():
                # Calculate relative path and destination
                rel_path = item.relative_to(src_dir)
                dest_item = dest_dir / rel_path

                # Create parent directories if they don't exist
                dest_item.parent.mkdir(parents=True, exist_ok=True)

                # Copy the file
                shutil.copy2(item, dest_item)

    def create_zip_archives(self):
        """Create zip archives for mod and assets"""
        import zipfile

        # Change to build directory
        original_cwd = os.getcwd()
        print("self.repo_dir : " + str(self.repo_dir));
        os.chdir(self.repo_dir)

        try:
            print("Creating zip archives...")
            zip_name_mod = self.artifact_name_mod()

            # Create mod zip
            print(f"Creating mod zip: {zip_name_mod}")
            with zipfile.ZipFile(zip_name_mod, "w", zipfile.ZIP_DEFLATED) as zf:
                for dir_name in ["brushes", "gfx", "ui", "scripts"]:
                    print("check file " + dir_name +" is exist ", Path(dir_name).exists())
                    if Path(dir_name).exists():
                        for root, dirs, files in os.walk(dir_name):
                            # print("adding files from", dirs.__str__())
                            for file in files:
                                # print(f"Adding {file} to {zip_name_mod} ...")
                                file_path = Path(root) / file
                                zf.write(file_path, file_path)

            # Move zip files to BB directory
            shutil.move(zip_name_mod, self.bb_dir / zip_name_mod)
            print(f"Created {zip_name_mod} in {self.bb_dir}")

        finally:
            os.chdir(original_cwd)

    def launch_game(self):
        """Launch Battle Brothers through Steam on Windows."""
        if platform.system() != "Windows":
            return

        subprocess.run(
            ["cmd", "/c", "start", "", "steam://run/365360"], check=True
        )

    def is_game_running(self):
        """Return whether Battle Brothers is currently running on Windows."""
        result = subprocess.run(
            ["tasklist", "/FI", "IMAGENAME eq BattleBrothers.exe", "/NH"],
            capture_output=True,
            text=True,
            check=True,
        )
        return "battlebrothers.exe" in result.stdout.lower()

    def restart_game(self):
        """Request a running Battle Brothers process to exit before launching it."""
        if platform.system() != "Windows":
            return

        print("Warning: restarting Battle Brothers can discard unsaved game progress.")
        if not self.is_game_running():
            return

        subprocess.run(["taskkill", "/IM", "BattleBrothers.exe"], check=True)
        for _ in range(8):
            time.sleep(0.25)
            if not self.is_game_running():
                return

        subprocess.run(["taskkill", "/F", "/IM", "BattleBrothers.exe"], check=True)

    def build(self, launch_game=False, restart_game=False):
        """Main build process"""
        try:
            print("Starting Mod build process...")

            # Build cleanup to ensure a fresh state
            self.prebuild_cleanup()

            # Remove and recreate build directory
            if self.build_dir.exists():
                shutil.rmtree(self.build_dir)
            self.build_dir.mkdir(parents=True)

            # Copy dead assets
            # self.copy_dead_assets()

            # Copy directories first (to establish base structure)
            # self.copy_directories()

            # Build brushes (which will add legend_armor/legend_helmets to existing scripts)
            self.build_brushes()

            # Create zip archives
            self.create_zip_archives()

            if restart_game:
                self.restart_game()
            if launch_game:
                self.launch_game()

            print("Legends mod build completed successfully!")

        except BuildError as e:
            print(f"Legends mod build failed: {e}")
            sys.exit(1)
        except Exception as e:
            print(f"Unexpected error: {e}")
            sys.exit(1)


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(description="Build complete Legends mod")
    parser.add_argument(
        "bb_dir",
        nargs="?",
        help="Battle Brothers data directory (default: from .build_config.py or auto-detect)",
    )
    parser.add_argument(
        "repo_dir",
        nargs="?",
        help="Repository directory name (default: from .build_config.py or 'Legends-public')",
    )
    parser.add_argument(
        "build_dir",
        nargs="?",
        help="Build directory (default: from .build_config.py or './build')",
    )
    parser.add_argument(
        "--launch-game",
        action="store_true",
        help="Launch Battle Brothers through Steam after a successful build",
    )
    parser.add_argument(
        "--restart-game",
        action="store_true",
        help="Restart Battle Brothers before launching it after a successful build",
    )

    args = parser.parse_args()

    builder = ModBuilder(args.bb_dir, args.repo_dir, args.build_dir)
    builder.build(
        launch_game=args.launch_game or args.restart_game,
        restart_game=args.restart_game,
    )
    print("Build process completed. Check the Battle Brothers data directory for the generated zip files.")


if __name__ == "__main__":
    main()
