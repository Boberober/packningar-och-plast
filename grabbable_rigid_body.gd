extends RigidBody3D
var interactable: Interactable

func _ready() -> void:
    interactable = Interactable.new()
    interactable.physics_body = self
    interactable.text = "Grab " + self.name
    self.add_child(interactable)

func interact(from_position: Vector3):
    print("Interacting with ", interactable.text)
    self.apply_central_force((self.global_position - from_position).normalized() * 100)
