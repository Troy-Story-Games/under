extends KinematicBody2D
class_name Block

const BlockDestroyEffect = preload("res://Effects/BlockDestroyEffect.tscn")

onready var collider = $CollisionShape2D


func _ready() -> void:
    set_physics_process(false)
    collider.disabled = true
    visible = false


func dig() -> void:
    # warning-ignore:return_value_discarded
    Utils.instance_scene_on_main(BlockDestroyEffect, global_position)
    queue_free()


func _on_VisibilityNotifier2D_screen_exited() -> void:
    collider.disabled = true
    visible = false
    set_physics_process(false)


func _on_VisibilityNotifier2D_screen_entered() -> void:
    collider.disabled = false
    visible = true
    set_physics_process(true)
