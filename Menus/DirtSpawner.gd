extends Node2D
class_name DirtSpawner

const PhysicsDirtScene = preload("res://Effects/PhysicsDirt.tscn")

export(int) var MAX_BULLET_SPEED = 80
export(int) var MIN_BULLET_SPEED = 20
export(int) var SPREAD = 90

onready var fireDirection = $FireDirection
onready var dirtSpawnPoint = $DirtSpawnPoint


func _on_Timer_timeout():
    spawnDirt()


func spawnDirt():
    var dirt: RigidBody2D = Utils.instance_scene_on_main(PhysicsDirtScene, dirtSpawnPoint.global_position)
    var direction = global_position.direction_to(fireDirection.global_position)
    var speed = rand_range(MIN_BULLET_SPEED, MAX_BULLET_SPEED)
    var velocity = direction * speed
    velocity = velocity.rotated(deg2rad(rand_range(-SPREAD, SPREAD/2)))
    dirt.apply_central_impulse(velocity)
