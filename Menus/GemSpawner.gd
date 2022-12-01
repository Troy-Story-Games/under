extends Node2D
class_name GemSpawner

const EmeraldPhysicsParticleScene = preload("res://Effects/BlockEffects/ParticleTypes/EmeraldPhysicsParticle.tscn")
const EmeraldPhysicsParticleSmallScene = preload("res://Effects/BlockEffects/ParticleTypes/EmeraldPhysicsParticleSmall.tscn")

export(int) var MAX_BULLET_SPEED = 65
export(int) var MIN_BULLET_SPEED = 20
export(int) var SPREAD = 65
export(float) var SPAWN_RATE = 0.05

onready var fireDirection = $FireDirection
onready var dirtSpawnPoint = $DirtSpawnPoint
onready var timer = $Timer

func _ready():
    timer.start(SPAWN_RATE)


func _on_Timer_timeout():
    spawnDirt()


func start():
    timer.start()


func stop():
    timer.stop()


func spawnDirt():
    var gem: PhysicsParticle = Utils.instance_scene_on_main(EmeraldPhysicsParticleScene, dirtSpawnPoint.global_position)
    var small_gem: PhysicsParticle = Utils.instance_scene_on_main(EmeraldPhysicsParticleSmallScene, dirtSpawnPoint.global_position)
    # warning-ignore-all:unsafe_property_access
    gem.PICKUP_TIME = 5.0
    gem.SPAWN_COLLECTIBLE = false
    gem.start_timer()
    small_gem.PICKUP_TIME = 5.0
    small_gem.SPAWN_COLLECTIBLE = false
    small_gem.start_timer()

    var direction = global_position.direction_to(fireDirection.global_position)
    var speed = rand_range(MIN_BULLET_SPEED, MAX_BULLET_SPEED)
    var velocity = direction * speed
    velocity = velocity.rotated(deg2rad(rand_range(-SPREAD, SPREAD/2)))
    gem.apply_central_impulse(velocity)

    direction = global_position.direction_to(fireDirection.global_position)
    speed = rand_range(MIN_BULLET_SPEED, MAX_BULLET_SPEED)
    velocity = direction * speed
    velocity = velocity.rotated(deg2rad(rand_range(-SPREAD, SPREAD/2)))
    small_gem.apply_central_impulse(velocity)
