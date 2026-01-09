class_name Interactable extends Node

@export var physics_body: PhysicsBody3D
@export var mesh: MeshInstance3D
@export var text: String = "Grab"
@export var show_highlight: bool = true
var parent

const signal_hover: StringName = "interact_hover"
const signal_unhover: StringName = "interact_unhover"
const signal_interact: StringName = "interact"
const interaction_input_action: StringName = "interact"

const highlight_material = preload("res://interactable_highlight.tres")

func _ready() -> void:
    parent = get_parent()
    if not mesh:
        mesh = find_mesh()

        if not mesh:
            push_error("Interactable: No mesh found")
            return
    
    parent.set_collision_layer_value(3, true)

    setup_signals()

    
func find_mesh():
    var children = parent.get_children()
    print('Parent is ', parent)
    for child in children:
        print("Child is ", child)
        if child is MeshInstance3D:
            return child

func setup_signals():
    parent.add_user_signal(signal_hover)
    parent.add_user_signal(signal_unhover)
    parent.add_user_signal(signal_interact)

    parent.connect(signal_hover, _on_interact_hover)
    parent.connect(signal_unhover, _on_interact_unhover)
    parent.connect(signal_interact, _on_interact)

func _on_interact_hover():
    if not show_highlight:
        return
    print("Interactable: Hovering over ", text)
    if mesh and highlight_material:
        mesh.material_overlay = highlight_material

func _on_interact_unhover():
    print("Interactable: Unhovering from ", text)
    if mesh:
        mesh.material_overlay = null

func _on_interact():
    print("Interactable: Interacting with ", text)

static func emit_interactable_signal(signal_name: StringName, object: Object):
    if not is_instance_valid(object):
        return

    if object.has_user_signal(signal_name):
        object.emit_signal(signal_name)
