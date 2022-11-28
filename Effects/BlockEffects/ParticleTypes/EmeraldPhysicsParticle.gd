extends PhysicsParticle
class_name EmeraldPhysicsParticle

const EmeraldPhysicsParticlePickup = preload("res://Pickup/PhysicsParticlePickups/EmeraldPhysicsParticlePickup.tscn")


func get_pickup_scene() -> PackedScene:
    return EmeraldPhysicsParticlePickup
