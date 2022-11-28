extends PhysicsParticle
class_name EmeraldPhysicsParticleSmall

const EmeraldPhysicsParticlePickupSmall = preload("res://Pickup/PhysicsParticlePickups/EmeraldPhysicsParticlePickupSmall.tscn")


func get_pickup_scene() -> PackedScene:
    return EmeraldPhysicsParticlePickupSmall
