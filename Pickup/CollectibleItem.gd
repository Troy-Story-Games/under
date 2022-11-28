extends KinematicBody2D
class_name CollectibleItem

enum ItemState {
    STATIONARY,
    CHASE
}

export(int) var MAX_SPEED = 5
export(int) var ACCELERATION = 5

# warning-ignore:unused_class_variable
export(int) var VALUE = 1

export(ItemState) var STARTING_STATE = ItemState.STATIONARY

var velocity = Vector2.ZERO
var state = ItemState.STATIONARY
var target = Vector2.ZERO

onready var playerDetectionZone = $PlayerDetectionZone


func _ready():
    state = STARTING_STATE
    target = position


func _physics_process(delta):
    match state:
        ItemState.STATIONARY:
            velocity = Vector2.ZERO
            seek_player()
        ItemState.CHASE:
            var player = playerDetectionZone.player
            if player != null:
                move_toward_position(player.global_position, delta)
            else:
                state = ItemState.STATIONARY


func seek_player():
    if playerDetectionZone.can_see_player():
        state = ItemState.CHASE


func move_toward_position(pos, delta):
    var direction = global_position.direction_to(pos)
    velocity = velocity.move_toward(direction * MAX_SPEED, ACCELERATION * delta)
    # warning-ignore:return_value_discarded
    move_and_collide(velocity)
