extends Node2D

const BlockDestroyEffect = preload("res://Effects/LargeBlockParticle.tscn")

export(int) var BULLET_SPEED = 30
export(int) var SPREAD = 90

onready var fireDirection = $FireDirection
onready var dirtSpawnPoint = $DirtSpawnPoint

func _on_Timer_timeout():
    spawnDirt()
    
func spawnDirt():
    var dirt = Utils.instance_scene_on_main(BlockDestroyEffect, dirtSpawnPoint.global_position)
    var velocity = (fireDirection.global_position - global_position).normalized() * BULLET_SPEED
    velocity = velocity.rotated(deg2rad(rand_range(-SPREAD, SPREAD/2)))
    dirt.apply_central_impulse(velocity)
