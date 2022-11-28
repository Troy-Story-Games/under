extends PhysicsParticle
class_name RockPhysicsParticle

const RockPhysicsParticlePickup = preload("res://Pickup/PhysicsParticlePickups/RockPhysicsParticlePickup.tscn")


func get_pickup_scene() -> PackedScene:
    return RockPhysicsParticlePickup
