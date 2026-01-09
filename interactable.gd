class_name Interactable extends Node

@export var physics_body: PhysicsBody3D
@export var mesh: MeshInstance3D
@export var text: String = "Grab"
var parent

func _ready() -> void:
    parent = get_parent()
    if not mesh:
        mesh = find_mesh()

        if not mesh:
            push_error("Interactable: No mesh found")
            return
    
    physics_body.set_collision_layer_value(3, true)

    
func find_mesh():
    var children = parent.get_children()
    for child in children:
        if child is MeshInstance3D:
            return child

func setup_signals():
    add_user_signal("interact_hover")
    add_user_signal("interact_unhover")
    add_user_signal("interact")

    parent.interact_hover.connect(_on_interact_hover)
    parent.interact_unhover.connect(_on_interact_unhover)
    parent.interact.connect(_on_interact)

func _on_interact_hover():
    print("Interactable: Hovering over ", text)

func _on_interact_unhover():
    print("Interactable: Unhovering from ", text)

func _on_interact():
    print("Interactable: Interacting with ", text)