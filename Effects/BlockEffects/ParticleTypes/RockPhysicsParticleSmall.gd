extends PhysicsParticle
class_name RockPhysicsParticleSmall

const RockPhysicsParticlePickupSmall = preload("res://Pickup/PhysicsParticlePickups/RockPhysicsParticlePickupSmall.tscn")


func get_pickup_scene() -> PackedScene:
    return RockPhysicsParticlePickupSmall
