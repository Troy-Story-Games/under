extends RigidBody2D
class_name RockParticle

const LargeDirtPickup = preload("res://Pickup/LargeDirtPickup.tscn")
const SmallDirtPickup = preload("res://Pickup/SmallDirtPickup.tscn")

var instance_pickup = null

onready var sprite = $RockParticleSprite
onready var timer = $Timer


func _ready() -> void:
    timer.start(rand_range(2,4))

    if sprite.frame == 0:
        instance_pickup = LargeDirtPickup
    else:
        instance_pickup = SmallDirtPickup


func _on_Timer_timeout() -> void:
    # warning-ignore:return_value_discarded
    var dirt_pickup: CollectibleItem = Utils.instance_scene_on_main(instance_pickup, global_position)
    dirt_pickup.rotation = rotation
    queue_free()
