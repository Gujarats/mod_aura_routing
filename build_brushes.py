#!/usr/bin/env python3
"""
OS-agnostic brush building script for Legends mod
Replaces build_brushes.sh with cross-platform Python implementation
"""

import argparse
import shutil
import sys
import time
from concurrent.futures import ProcessPoolExecutor
from pathlib import Path

from buildscript.lib import BrushUtils


class BrushBuildError(Exception):
    """Custom exception for brush build errors"""

    pass


class BrushBuilder:
    def __init__(self, build_dir=None, repo_dir="Legends-public"):
        self.current_dir = Path.cwd()

        # Set default build directory
        if build_dir is None:
            build_dir = self.current_dir / "build"

        self.build_dir = Path(build_dir)
        self.repo_dir = repo_dir
        self.brush = BrushUtils(self.current_dir, self.repo_dir)

        print(f"Build directory: {self.build_dir}")
        print(f"Repository directory: {self.repo_dir}")
        print(f"Current directory: {self.current_dir}")

    def handle_exit(self, result, context=""):
        """Handle subprocess exit codes"""
        if result.returncode != 0:
            error_msg = f"Failed to build {context if context else 'brushes'}!"
            print(error_msg)
            if result.stderr:
                print(f"Error output: {result.stderr}")
            raise BrushBuildError(error_msg)

    def check_for_error(self, output, brush_name):
        """Check output for ERROR messages"""
        if "ERROR" in output:
            for line in output.split("\n"):
                print(line)
            raise BrushBuildError(f"Failed to build Legends brush {brush_name}")

    def copy_brushes_and_gfx(self):
        """Copy brushes and graphics to build directory for packaging"""
        print(f"Copying brushes to {self.build_dir}/brushes ...")

        # Copy brushes to build directory
        build_brushes_dir = self.build_dir / "brushes"
        build_brushes_dir.mkdir(parents=True, exist_ok=True)

        local_brushes_dir = self.current_dir / "brushes"
        if local_brushes_dir.exists() and any(local_brushes_dir.iterdir()):
            shutil.copytree(local_brushes_dir, build_brushes_dir, dirs_exist_ok=True)

        print(f"Copying gfx files to {self.build_dir}/gfx ...")

        # Copy gfx files to build directory
        build_gfx_dir = self.build_dir / "gfx"
        build_gfx_dir.mkdir(parents=True, exist_ok=True)

        local_gfx_dir = self.current_dir / "gfx"
        if local_gfx_dir.exists():
            for png_file in local_gfx_dir.glob("*.png"):
                shutil.copy2(png_file, build_gfx_dir)

    def build_all_brushes(self):
        """Build all brushes"""
        # Create brushes directory
        brushes_dir = self.current_dir / "brushes"
        if brushes_dir.exists():
            shutil.rmtree(brushes_dir)
        brushes_dir.mkdir(exist_ok=True)

        start = time.time()
        # # Build each brush
        # with ProcessPoolExecutor() as executor:
        #     list(
        #         executor.map(
        #             self.brush.build_brush,
        #             # these are build as bbrusher would
        #             [
        #                 "world_tiles",
        #                 "terrain",
        #                 "legend_detail",
        #             ],
        #         )
        #     )
        # with ProcessPoolExecutor() as executor:
        #     list(
        #         executor.map(
        #             self.brush.build_brush_best_fit,
        #             # these are using different packaging method for better compression
        #             [
        #                 "legend_armor",
        #                 "legend_helmets",
        #                 "legend_characters",
        #                 "legend_enemies",
        #                 "legend_weapons",
        #                 "legend_world",
        #                 "legend_horses",
        #                 "legend_ui",
        #                 "legend_objects",
        #                 "legend_effects",
        #             ],
        #         )
        #     )
        print("Elapsed build brush", time.time() - start)

    def build(self):
        """Main build process"""
        try:
            print("Starting brush build process...")

            # Build scripts first
            self.build_helmets()
            self.build_armor()
            self.build_enemies()

            # Build all brushes
            self.build_all_brushes()

            # Copy brushes and assets to build directory for packaging
            self.copy_brushes_and_gfx()

            print("Brush build completed successfully!")

        except BrushBuildError as e:
            print(f"Brush build failed: {e}")
            sys.exit(1)
        except Exception as e:
            print(f"Unexpected error: {e}")
            sys.exit(1)


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(description="Build brushes for Legends mod")
    parser.add_argument(
        "build_dir", nargs="?", help="Build directory (default: ./build)"
    )
    parser.add_argument(
        "repo_dir",
        nargs="?",
        default="Legends-public",
        help="Repository directory name (default: Legends-public)",
    )

    args = parser.parse_args()

    builder = BrushBuilder(args.build_dir, args.repo_dir)
    builder.build()


if __name__ == "__main__":
    main()
