class_name Interactable extends Node

@export var physics_body: PhysicsBody3D
@export var text: String = "Grab"

func _ready() -> void:
    if not physics_body:
        if get_parent() is PhysicsBody3D:
            physics_body = get_parent()
        else:
            push_error("Interactable: No physics body found")
            return

    physics_body.set_collision_layer_value(3, true)