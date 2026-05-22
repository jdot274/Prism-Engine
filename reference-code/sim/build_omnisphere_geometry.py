"""
build_omnisphere_geometry.py
BlurFocus - Procedural OmniSphere showcase mesh builder.

Generates the project's core showcase mesh: a dense, Nanite-enabled
cube-sphere saved at /Game/Sim/Meshes/SM_OmniSphere.

The mesh is built from box topology, then projected to a sphere. That keeps
the BlurFocus meta primitive cube-derived while the rendered silhouette stays
round and hero-ball ready.

Run via MCP:  python Content/Python/run_mcp.py Content/Python/sim/build_omnisphere_geometry.py
Or in-editor: Tools -> Execute Python Script -> build_omnisphere_geometry.py

Idempotent: if SM_OmniSphere already exists it is deleted and rebuilt at
the same path (no SM_OmniSphere_1 spam).
"""
from __future__ import annotations

import unreal

ASSET_FOLDER       = "/Game/Sim/Meshes"
ASSET_FULL_PATH    = f"{ASSET_FOLDER}/SM_OmniSphere"
MATERIAL_SLOT_NAME = "OmniSphereMat"

PREFERRED_MATERIAL = "/Game/Sim/Materials/M_SimSphere"

EAL = unreal.EditorAssetLibrary


def _ensure_dir(path: str) -> None:
    if not EAL.does_directory_exist(path):
        EAL.make_directory(path)
        unreal.log(f"[OmniSphere] Created folder {path}")


def _resolve_slot_material() -> unreal.MaterialInterface | None:
    """Return the project-owned ball material if it exists.

    Do not load /Engine/EngineMaterials/DefaultMaterial here. Source-control
    checkout/save sweeps can mistake engine-owned stock assets for writable
    project content after material/mesh graph work.
    """
    if EAL.does_asset_exist(PREFERRED_MATERIAL):
        mat = EAL.load_asset(PREFERRED_MATERIAL)
        if mat:
            return mat
    unreal.log_warning(
        f"[OmniSphere] Project ball material missing; slot left empty: {PREFERRED_MATERIAL}")
    return None


def _delete_if_exists(path: str) -> None:
    """Idempotent rebuild: remove any pre-existing asset at `path`."""
    if not EAL.does_asset_exist(path):
        return
    try:
        EAL.delete_asset(path)
        unreal.log(f"[OmniSphere] Removed existing {path} (rebuilding).")
    except Exception as e:
        unreal.log_error(f"[OmniSphere] Could not delete {path}: {e}")


def _build_dynamic_mesh(radius_cm: float, subdivisions: int) -> unreal.DynamicMesh:
    """Generate the meta cube-sphere geometry into a DynamicMesh."""
    dm = unreal.DynamicMesh()
    prim_opts = unreal.GeometryScriptPrimitiveOptions()
    xform     = unreal.Transform()
    prims     = unreal.GeometryScript_Primitives

    steps = max(4, int(subdivisions))
    prims.append_sphere_box(
        target_mesh=dm,
        primitive_options=prim_opts,
        transform=xform,
        radius=radius_cm,
        steps_x=steps,
        steps_y=steps,
        steps_z=steps,
        origin=unreal.GeometryScriptPrimitiveOriginMode.CENTER,
    )
    unreal.log(
        f"[OmniSphere] Built cube-sphere meta mesh "
        f"(box steps={steps}, r={radius_cm}cm)."
    )
    return dm


def _bake_static_mesh(dm: unreal.DynamicMesh, asset_path: str) -> unreal.StaticMesh | None:
    """Bake the DynamicMesh into a brand-new StaticMesh asset."""
    out_opts = unreal.GeometryScriptCreateNewStaticMeshAssetOptions()
    out_opts.enable_nanite             = False  # explicit Nanite pass below
    out_opts.enable_recompute_normals  = True
    out_opts.enable_recompute_tangents = True
    # Suppress lightmap UV generation (Lumen handles GI). Property name may
    # differ across UE versions; non-fatal if it doesn't exist.
    try:
        out_opts.generate_lightmap_u_vs = False
    except Exception:
        pass

    result = unreal.GeometryScript_NewAssetUtils.create_new_static_mesh_asset_from_mesh(
        dm, asset_path, out_opts,
    )
    sm = result[0] if result else None
    if sm is None:
        unreal.log_error(
            f"[OmniSphere] create_new_static_mesh_asset_from_mesh "
            f"returned no asset for {asset_path}.")
    return sm


def _apply_build_settings(sm: unreal.StaticMesh) -> None:
    """High-quality normals/tangents, no degenerates, no lightmap UVs."""
    sm_sub = unreal.get_editor_subsystem(unreal.StaticMeshEditorSubsystem)
    try:
        bs: unreal.MeshBuildSettings = sm_sub.get_lod_build_settings(sm, 0)
        bs.use_high_precision_tangent_basis = True
        bs.remove_degenerates               = True
        bs.recompute_normals                = True
        bs.recompute_tangents               = True
        bs.generate_lightmap_u_vs           = False
        sm_sub.set_lod_build_settings(sm, 0, bs)
    except Exception as e:
        unreal.log_warning(f"[OmniSphere] Build settings tweak failed: {e}")


def _apply_nanite(sm: unreal.StaticMesh) -> None:
    """Enable Nanite with FallbackTarget=NumTris, 1% fallback, AUTO precision.

    UE 5.7 PYTHON API UNCERTAINTY: NaniteFallbackTarget enum name and the
    `fallback_target` / `fallback_percent_triangles` property names have
    drifted across 5.x releases; we set what binds and warn otherwise.
    """
    ns = unreal.MeshNaniteSettings()
    ns.enabled = True
    # PositionPrecision = AUTO uses sentinel -1.
    ns.position_precision = -1
    try:
        ns.fallback_target = unreal.NaniteFallbackTarget.NUM_TRIS
    except Exception as e:
        unreal.log_warning(
            f"[OmniSphere] NaniteFallbackTarget.NUM_TRIS unavailable ({e}).")
    try:
        ns.fallback_percent_triangles = 0.01
    except Exception as e:
        unreal.log_warning(
            f"[OmniSphere] fallback_percent_triangles unavailable ({e}).")

    sm_sub = unreal.get_editor_subsystem(unreal.StaticMeshEditorSubsystem)
    sm_sub.set_nanite_settings(sm, ns, apply_changes=True)


def _apply_material_slot(sm: unreal.StaticMesh) -> None:
    """Single section, single material slot named OmniSphereMat."""
    slot_mat = _resolve_slot_material()
    slot = unreal.StaticMaterial()
    slot.material_slot_name = MATERIAL_SLOT_NAME
    if slot_mat is not None:
        slot.material_interface = slot_mat
    try:
        sm.set_editor_property("static_materials", [slot])
    except Exception as e:
        unreal.log_warning(
            f"[OmniSphere] static_materials set failed ({e}); using set_material fallback.")
        if slot_mat is not None:
            sm.set_material(0, slot_mat)


def build_omnisphere_mesh(
    asset_path: str = ASSET_FULL_PATH,
    radius_cm: float = 100.0,
    subdivisions: int = 64,
    enable_nanite: bool = True,
) -> unreal.StaticMesh | None:
    """Build (or rebuild) the OmniSphere showcase StaticMesh.

    Returns the freshly built StaticMesh, or None on failure.
    """
    folder = asset_path.rsplit("/", 1)[0]
    _ensure_dir(folder)
    _delete_if_exists(asset_path)

    try:
        dm = _build_dynamic_mesh(radius_cm=radius_cm, subdivisions=subdivisions)
    except Exception as e:
        unreal.log_error(f"[OmniSphere] Geometry generation failed: {e}")
        return None

    sm = _bake_static_mesh(dm, asset_path)
    if sm is None:
        return None

    _apply_build_settings(sm)
    _apply_material_slot(sm)
    if enable_nanite:
        _apply_nanite(sm)

    EAL.save_loaded_asset(sm, only_if_is_dirty=False)
    unreal.log(f"[OmniSphere] Saved {asset_path} (Nanite={enable_nanite}).")
    return sm


if __name__ == "__main__":
    with unreal.ScopedEditorTransaction("Build OmniSphere Geometry"):
        build_omnisphere_mesh()
