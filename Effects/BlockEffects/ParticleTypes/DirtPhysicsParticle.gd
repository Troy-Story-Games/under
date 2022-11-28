extends PhysicsParticle
class_name DirtPhysicsParticle

const DirtPhysicsParticlePickup = preload("res://Pickup/PhysicsParticlePickups/DirtPhysicsParticlePickup.tscn")


func get_pickup_scene() -> PackedScene:
    return DirtPhysicsParticlePickup
