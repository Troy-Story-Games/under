extends PhysicsParticle
class_name DirtPhysicsParticleSmall

const DirtPhysicsParticlePickupSmall = preload("res://Pickup/PhysicsParticlePickups/DirtPhysicsParticlePickupSmall.tscn")


func get_pickup_scene() -> PackedScene:
    return DirtPhysicsParticlePickupSmall
