extends KinematicBody2D

signal stopped()


export(int) var SPEED = 32

var going = false


func start():
    going = true


func stop():
    going = false
    emit_signal("stopped")


func _physics_process(delta):
    if not going:
        return

    position.x += SPEED * delta
