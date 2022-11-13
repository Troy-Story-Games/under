extends Node

const NUM_COLS = 12
const BLOCK_SIZE = 8
const BLOCK_SIZE_IN_METERS = 2


func instance_scene_on_main(packed_scene: PackedScene, position: Vector2 = Vector2.ZERO) -> Node2D:
    var main := get_tree().current_scene
    var instance : Node2D = packed_scene.instance()
    main.add_child(instance)
    instance.global_position = position
    return instance


func get_player_stats() -> Resource:
    return ResourceLoader.load("res://Player/PlayerStats.tres")


func rand_int_incl(to: int, from: int) -> int:
    # Random int b/w to and from inclusive
    return int(rand_range(to, from + 1))
