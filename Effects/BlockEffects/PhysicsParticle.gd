extends RigidBody2D
class_name PhysicsParticle

onready var timer = $Timer


func _ready() -> void:
    timer.start(rand_range(2,4))


func _on_Timer_timeout() -> void:
    var pickup_scene: PackedScene = get_pickup_scene()

    # warning-ignore:return_value_discarded
    var dirt_pickup: CollectibleItem = Utils.instance_scene_on_main(pickup_scene, global_position)
    dirt_pickup.rotation = rotation
    queue_free()


func get_pickup_scene() -> PackedScene:
    # This must be implemented by child nodes
    assert(false)
    return null
