extends RigidBody2D
class_name PhysicsDirt

export(int) var MAX_SPEED = 250
export(int) var ACCELERATION = 500

var move_towards: Sprite = null
var velocity: Vector2 = Vector2.ZERO

#onready var collider = $CollisionShape2D

#func _on_Timer_timeout():
#    set_deferred("mode", MODE_KINEMATIC)


func trigger(sprite: Sprite):
    # Can't change this state while flushing queries. Use call_deferred() or set_deferred() to change
    # monitoring state instead.
    set_deferred("mode", MODE_KINEMATIC)
    #collider.set_deferred("disabled", true)
    set_deferred("move_towards", sprite)


func _physics_process(delta):
    if move_towards != null:
        move_toward_position(move_towards.global_position, delta)


func move_toward_position(pos, delta):
    var direction = global_position.direction_to(pos)
    velocity = velocity.move_toward(direction * MAX_SPEED, ACCELERATION * delta)
    position += velocity * delta
