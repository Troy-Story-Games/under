extends Node2D
class_name BlockDestroyEffect

const LargeBlockParticleScene = preload("res://Effects/LargeBlockParticle.tscn")
const SmallBlockParticleScene = preload("res://Effects/SmallBlockParticle.tscn")

export(int) var NUM_LARGE = 1
export(int) var NUM_SMALL = 4


func _ready() -> void:
    for _idx in range(NUM_LARGE):
        var particle = Utils.instance_particle(LargeBlockParticleScene)
        if particle:
            add_child(particle)
            particle.position.x = rand_range(-4, 4)
            particle.position.y = rand_range(-4, 4)

    for _idx in range(NUM_SMALL):
        var particle = Utils.instance_particle(SmallBlockParticleScene)
        if particle:
            add_child(particle)
            particle.position.x = rand_range(-4, 4)
            particle.position.y = rand_range(-4, 4)
