"""Batch import all .abc files in a folder as Geometry Cache assets.

Run from the UE editor's Python console:
    py "C:/Path/To/geometry-cache-import.py"

Edit SOURCE_DIR and DEST_PATH for your project.
"""

import os
import unreal

SOURCE_DIR = r"C:\Sims\Out"            # Where the .abc files live on disk
DEST_PATH  = "/Game/FX/Caches"         # Asset path inside UE


def import_one(abc_path: str, dest_package: str) -> bool:
    task = unreal.AssetImportTask()
    task.filename = abc_path
    task.destination_path = dest_package
    task.replace_existing = True
    task.automated = True
    task.save = True

    options = unreal.AbcImportSettings()
    options.import_type = unreal.AlembicImportType.GEOMETRY_CACHE
    options.geometry_cache_settings.flatten_tracks = True
    options.geometry_cache_settings.compressed_position_precision = 0.01
    options.material_settings.find_materials = True
    task.options = options

    asset_tools = unreal.AssetToolsHelpers.get_asset_tools()
    asset_tools.import_asset_tasks([task])

    if task.imported_object_paths:
        unreal.log(f"Imported: {task.imported_object_paths[0]}")
        return True
    unreal.log_warning(f"Failed to import: {abc_path}")
    return False


def main():
    if not os.path.isdir(SOURCE_DIR):
        unreal.log_error(f"Source dir not found: {SOURCE_DIR}")
        return

    abcs = [f for f in os.listdir(SOURCE_DIR) if f.lower().endswith(".abc")]
    unreal.log(f"Found {len(abcs)} .abc files")

    for filename in abcs:
        import_one(os.path.join(SOURCE_DIR, filename), DEST_PATH)

    unreal.log(f"Done. Imported {len(abcs)} caches into {DEST_PATH}.")


if __name__ == "__main__":
    main()
