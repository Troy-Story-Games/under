extends RigidBody2D
class_name PhysicsParticle

export(float) var PICKUP_TIME = 2.0
export(bool) var SPAWN_COLLECTIBLE = true

onready var timer = $Timer


func start_timer():
    timer.start(PICKUP_TIME)


func _on_Timer_timeout() -> void:
    if SPAWN_COLLECTIBLE:
        var pickup_scene: PackedScene = get_pickup_scene()

        # warning-ignore:return_value_discarded
        var dirt_pickup: CollectibleItem = Utils.instance_scene_on_main(pickup_scene, global_position)
        dirt_pickup.rotation = rotation
    queue_free()


func get_pickup_scene() -> PackedScene:
    # This must be implemented by child nodes
    assert(false)
    return null
