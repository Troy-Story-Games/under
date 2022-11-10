extends KinematicBody2D
class_name CollectibleItem

enum ItemState {
    STATIONARY,
    CHASE
}

export(int) var MAX_SPEED = 5
export(int) var ACCELERATION = 5
export(int) var ITEM_ID = 0  # This must be set in sub-classes to the
                             # correct item ID if IS_MONEY is false
# warning-ignore:unused_class_variable
export(bool) var IS_DIRT = false
export(ItemState) var STARTING_STATE = ItemState.STATIONARY

var velocity = Vector2.ZERO
var state = ItemState.STATIONARY
var target = Vector2.ZERO

onready var playerDetectionZone = $PlayerDetectionZone
onready var collider = $Collider


func _ready():
    state = STARTING_STATE
    target = position
    collider.disabled = true


func _physics_process(delta):
    match state:
        ItemState.STATIONARY:
            collider.disabled = false
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


func collect():
    """
    Sub-classes CAN override this (but don't have to) if they need to
    store additional information with the item in the player's inventory
    """
    return {
        item_id = ITEM_ID
    }
