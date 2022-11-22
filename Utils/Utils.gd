extends Node

const NUM_COLS = 12
const BLOCK_SIZE = 8
const HALF_BLOCK_SIZE = 4
const BLOCK_SIZE_IN_METERS = 2
const MAX_PARTICLES = 256

var current_particles = 0 setget set_current_particles


func instance_scene_on_main(packed_scene: PackedScene, position: Vector2 = Vector2.ZERO) -> Node2D:
    var main := get_tree().current_scene
    var instance : Node2D = packed_scene.instance()
    main.add_child(instance)
    instance.global_position = position
    return instance


func instance_particle(packed_scene: PackedScene) -> RigidBody2D:
    if current_particles == MAX_PARTICLES:
        return null

    var instance = packed_scene.instance()
    instance.connect("tree_exited", self, "_on_Particle_tree_exited")
    current_particles += 1
    return instance


func set_current_particles(value: int) -> void:
    current_particles = clamp(value, 0, MAX_PARTICLES)


func _on_Particle_tree_exited():
    current_particles -= 1


func get_player_stats() -> Resource:
    return ResourceLoader.load("res://Player/PlayerStats.tres")


func get_main_instances() -> Resource:
    return ResourceLoader.load("res://Utils/MainInstances.tres")


func rand_int_incl(to: int, from: int) -> int:
    # Random int b/w to and from inclusive
    return int(rand_range(to, from + 1))
