extends KinematicBody2D
class_name Block

const BlockDestroyEffect = preload("res://Effects/BlockDestroyEffect.tscn")


func dig() -> void:
    # warning-ignore:return_value_discarded
    Utils.instance_scene_on_main(BlockDestroyEffect, global_position)
    queue_free()
