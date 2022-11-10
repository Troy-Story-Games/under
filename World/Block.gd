extends KinematicBody2D
class_name Block

const BlockDestroyEffect = preload("res://Effects/BlockDestroyEffect.tscn")


func dig() -> void:
    var particles: CPUParticles2D = Utils.instance_scene_on_main(BlockDestroyEffect, global_position)
    particles.emitting = true
    queue_free()
