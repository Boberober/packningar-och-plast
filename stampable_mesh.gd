extends MeshInstance3D
class_name StampableMesh

@export var mask_size: int = 1024
@export var stamp_radius_px: int = 24
@export_range(0.0, 1.0, 0.01) var stamp_hardness: float = 0.85 # 1 = hard edge

var _mask_image: Image
var _mask_tex: ImageTexture

# Cached triangle data for UV lookup
var _triangles := [] # each: {a,b,c, uva,uvb,uvc} in local space

func _ready() -> void:
    _init_mask()
    _cache_mesh_triangles()

func _init_mask() -> void:
    _mask_image = Image.create(mask_size, mask_size, false, Image.FORMAT_RF)
    _mask_image.fill(Color(0, 0, 0))
    _mask_tex = ImageTexture.create_from_image(_mask_image)

    # Push into the shader material
    var sm := material_override as ShaderMaterial
    if sm == null:
        push_warning("Assign a ShaderMaterial as material_override (or adapt code to use surface override).")
        return
    sm.set_shader_parameter("mask_tex", _mask_tex)

func _cache_mesh_triangles() -> void:
    _triangles.clear()

    var m := mesh
    if m == null:
        push_warning("No mesh on this MeshInstance3D.")
        return

    # For simplicity, we read surface 0. If you have multiple surfaces, expand this.
    var arrays := m.surface_get_arrays(0)
    var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
    var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
    var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]

    if verts.is_empty() or uvs.is_empty() or indices.is_empty():
        push_warning("Mesh needs vertices, UVs, and indices for UV stamping.")
        return

    for i in range(0, indices.size(), 3):
        var ia := indices[i]
        var ib := indices[i + 1]
        var ic := indices[i + 2]

        _triangles.append({
            "a": verts[ia], "b": verts[ib], "c": verts[ic],
            "uva": uvs[ia], "uvb": uvs[ib], "uvc": uvs[ic],
        })

func stamp_from_world_ray(ray_origin: Vector3, ray_dir: Vector3) -> bool:
    # Convert ray to local space
    var inv := global_transform.affine_inverse()
    var o := inv * ray_origin
    var d := (inv.basis * ray_dir).normalized()

    var hit = _ray_to_uv(o, d)
    if hit == null:
        return false

    var uv: Vector2 = hit
    _paint_circle_uv(uv, stamp_radius_px, stamp_hardness)
    return true

func _ray_to_uv(o: Vector3, d: Vector3) -> Variant:
    # Brute-force triangle intersection (fine for small/medium meshes; can optimize later with BVH)
    var best_t := INF
    var best_uv := Vector2.ZERO

    for tri in _triangles:
        var a: Vector3 = tri["a"]
        var b: Vector3 = tri["b"]
        var c: Vector3 = tri["c"]

        var res = Geometry3D.ray_intersects_triangle(o, d, a, b, c)
        if res == null:
            continue

        var p: Vector3 = res
        var t = (p - o).dot(d)
        if t < 0.0 or t >= best_t:
            continue

        # Barycentric coordinates for UV interpolation
        var uv := _barycentric_uv(p, a, b, c, tri["uva"], tri["uvb"], tri["uvc"])
        best_t = t
        best_uv = uv

    if best_t == INF:
        return null
    return best_uv

func _barycentric_uv(p: Vector3, a: Vector3, b: Vector3, c: Vector3, uva: Vector2, uvb: Vector2, uvc: Vector2) -> Vector2:
    var v0 := b - a
    var v1 := c - a
    var v2 := p - a

    var d00 := v0.dot(v0)
    var d01 := v0.dot(v1)
    var d11 := v1.dot(v1)
    var d20 := v2.dot(v0)
    var d21 := v2.dot(v1)

    var denom := d00 * d11 - d01 * d01
    if abs(denom) < 1e-12:
        return uva

    var v := (d11 * d20 - d01 * d21) / denom
    var w := (d00 * d21 - d01 * d20) / denom
    var u := 1.0 - v - w

    return uva * u + uvb * v + uvc * w

func _paint_circle_uv(uv: Vector2, radius_px: int, hardness: float) -> void:
    # Wrap UVs so you can stamp across seams if you want (optional)
    var u := fposmod(uv.x, 1.0)
    var v := fposmod(uv.y, 1.0)

    var cx := int(u * float(mask_size))
    var cy := int(v * float(mask_size))

    var r := radius_px
    var r2 := r * r

    for y in range(cy - r, cy + r + 1):
        if y < 0 or y >= mask_size:
            continue
        for x in range(cx - r, cx + r + 1):
            if x < 0 or x >= mask_size:
                continue

            var dx := x - cx
            var dy := y - cy
            var dist2 := dx * dx + dy * dy
            if dist2 > r2:
                continue

            # Soft edge control
            var dist := sqrt(float(dist2)) / float(r) # 0..1
            var edge := smoothstep(hardness, 1.0, dist) # 0 inside, 1 at edge
            var add := 1.0 - edge

            var cur = _mask_image.get_pixel(x, y).r
            var next = clamp(cur + add, 0.0, 1.0)
            _mask_image.set_pixel(x, y, Color(next, 0, 0))

    _mask_tex.update(_mask_image)

static func smoothstep(edge0: float, edge1: float, x: float) -> float:
    var t = clamp((x - edge0) / max(1e-6, (edge1 - edge0)), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)
