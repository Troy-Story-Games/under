extends Node2D
class_name DestroyEffect

const PHYSICS_PARTICLE_LIFE_MAX = 4
const NUM_LARGE = 1
const NUM_SMALL = 3

onready var timer = $Timer


func add_particle_to_scene(particle):
    add_child(particle)
    particle.position.x = rand_range(-Utils.HALF_BLOCK_SIZE, Utils.HALF_BLOCK_SIZE)
    particle.position.y = rand_range(-Utils.HALF_BLOCK_SIZE, Utils.HALF_BLOCK_SIZE)


func create_effect(large_packed_scene, small_packed_scene):
    for _idx in range(NUM_LARGE):
        var particle: RigidBody2D = Utils.instance_particle(large_packed_scene)
        if particle:
            add_particle_to_scene(particle)

    for _idx in range(NUM_SMALL):
        var particle: RigidBody2D = Utils.instance_particle(small_packed_scene)
        if particle:
            add_particle_to_scene(particle)

    # Delete ourself right after the physics particles swap to be pickups
    timer.start(PHYSICS_PARTICLE_LIFE_MAX + 1)
