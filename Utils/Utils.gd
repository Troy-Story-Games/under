extends Node

# Auto-load singleton with common utilities
# needed in most games


func instance_scene_on_main(packed_scene: PackedScene, position: Vector2 = Vector2.ZERO) -> Node2D:
    var main := get_tree().current_scene
    var instance : Node2D = packed_scene.instance()
    main.add_child(instance)
    instance.global_position = position
    return instance


func get_player_stats() -> Resource:
    return ResourceLoader.load("res://Player/PlayerStats.tres")
