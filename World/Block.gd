extends KinematicBody2D
class_name Block

const DestroyEffectScene = preload("res://Effects/BlockEffects/DestroyEffect.tscn")

var on_screen: = false

onready var collider = $CollisionShape2D
# warning-ignore:unused_class_variable
onready var sprite = $Sprite


func _ready() -> void:
    set_physics_process(false)
    collider.disabled = true
    visible = false


# warning-ignore:unused_argument
func dig(throw: bool = false) -> void:
    queue_free()


func _on_VisibilityNotifier2D_screen_exited() -> void:
    collider.disabled = true
    visible = false
    on_screen = false
    set_physics_process(false)


func _on_VisibilityNotifier2D_screen_entered() -> void:
    collider.disabled = false
    visible = true
    on_screen = true
    set_physics_process(true)
