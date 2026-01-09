extends Node3D

@export var stampable_mesh: StampableMesh

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    # stamp in the middle of the mesh:
    var mesh_center = stampable_mesh.mesh.get_aabb().position
    stampable_mesh._paint_circle_uv(Vector2(mesh_center.x, mesh_center.z), 10, 0.85)

    pass # Replace with function body.
