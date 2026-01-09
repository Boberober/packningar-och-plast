## Utility class for drawing debug shapes in 3D space.
## Provides methods for visualizing debug information during development.
class_name DebugDraw

## Draws a debug arrow from start position to end position.
## @param from: Starting position of the arrow (Vector3)
## @param to: Ending position of the arrow (Vector3)
## @param color: Color of the arrow (Color, default: white)
## @param arrowhead_size: Size of the arrowhead as a fraction of the total length (float, default: 0.2)
## @param thickness: Thickness of the arrow shaft (float, default: 0.05)
## @param parent: Optional Node3D parent to attach the arrow to. If null, creates a temporary node.
static func draw_arrow(
	from: Vector3,
	to: Vector3,
	color: Color = Color.WHITE,
	arrowhead_size: float = 0.2,
	thickness: float = 0.05,
	parent: Node3D = null
) -> MeshInstance3D:
	var direction := (to - from)
	var length := direction.length()
	
	if length < 0.001:
		# Points are too close, can't draw arrow
		return null
	
	direction = direction.normalized()
	
	# Create mesh instance
	var mesh_instance := MeshInstance3D.new()
	var immediate_mesh := ImmediateMesh.new()
	var material := StandardMaterial3D.new()
	
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.flags_unshaded = true
	material.flags_no_depth_test = false
	
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, material)
	
	# Calculate arrowhead size in world units
	var arrowhead_length := length * arrowhead_size
	var shaft_length := length - arrowhead_length
	
	# Calculate perpendicular vectors for the arrow shaft
	var up := Vector3.UP
	if abs(direction.dot(up)) > 0.9:
		up = Vector3.FORWARD
	
	var right := direction.cross(up).normalized()
	up = right.cross(direction).normalized()
	
	# Draw arrow shaft (cylinder)
	var shaft_radius := thickness * 0.5
	var shaft_start := from
	var shaft_end := from + direction * shaft_length
	
	# Draw cylinder for shaft using triangles
	var cylinder_segments := 8
	for i in range(cylinder_segments):
		var angle1 := (i * 2.0 * PI) / cylinder_segments
		var angle2 := ((i + 1) * 2.0 * PI) / cylinder_segments
		
		var offset1 := right * cos(angle1) * shaft_radius + up * sin(angle1) * shaft_radius
		var offset2 := right * cos(angle2) * shaft_radius + up * sin(angle2) * shaft_radius
		
		var p1 := shaft_start + offset1
		var p2 := shaft_start + offset2
		var p3 := shaft_end + offset1
		var p4 := shaft_end + offset2
		
		# First triangle
		immediate_mesh.surface_set_normal(direction)
		immediate_mesh.surface_add_vertex(p1)
		immediate_mesh.surface_set_normal(direction)
		immediate_mesh.surface_add_vertex(p2)
		immediate_mesh.surface_set_normal(direction)
		immediate_mesh.surface_add_vertex(p3)
		
		# Second triangle
		immediate_mesh.surface_set_normal(direction)
		immediate_mesh.surface_add_vertex(p2)
		immediate_mesh.surface_set_normal(direction)
		immediate_mesh.surface_add_vertex(p4)
		immediate_mesh.surface_set_normal(direction)
		immediate_mesh.surface_add_vertex(p3)
	
	# Draw arrowhead (cone)
	var arrowhead_base := from + direction * shaft_length
	var arrowhead_tip := to
	var arrowhead_radius := thickness * 1.5
	
	# Draw cone base
	for i in range(cylinder_segments):
		var angle1 := (i * 2.0 * PI) / cylinder_segments
		var angle2 := ((i + 1) * 2.0 * PI) / cylinder_segments
		
		var offset1 := right * cos(angle1) * arrowhead_radius + up * sin(angle1) * arrowhead_radius
		var offset2 := right * cos(angle2) * arrowhead_radius + up * sin(angle2) * arrowhead_radius
		
		var base1 := arrowhead_base + offset1
		var base2 := arrowhead_base + offset2
		
		# Triangle from base to tip
		var normal1 := (base1 - arrowhead_tip).cross(base2 - base1).normalized()
		immediate_mesh.surface_set_normal(normal1)
		immediate_mesh.surface_add_vertex(arrowhead_tip)
		immediate_mesh.surface_set_normal(normal1)
		immediate_mesh.surface_add_vertex(base1)
		immediate_mesh.surface_set_normal(normal1)
		immediate_mesh.surface_add_vertex(base2)
	
	immediate_mesh.surface_end()
	
	mesh_instance.mesh = immediate_mesh
	
	# Add to scene
	if parent:
		parent.add_child(mesh_instance)
	else:
		# Add to current scene tree
		var scene_tree := Engine.get_main_loop() as SceneTree
		if scene_tree:
			var root := scene_tree.current_scene
			if root:
				root.add_child(mesh_instance)
	
	return mesh_instance

