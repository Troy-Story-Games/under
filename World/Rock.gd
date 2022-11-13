extends KinematicBody2D
class_name Rock

export(int) var MIN_ROCK_SCALE = 1
export(int) var MAX_ROCK_SCALE = 1
export(int) var GRAVITY = 500
export(int) var MAX_FALL_SPEED = 300
export(float) var FALL_DELAY = 0.75

var motion : Vector2 = Vector2.ZERO
var falling := false
var restore_pos : Vector2 = Vector2.ZERO
var floor_collision : KinematicCollision2D = null
var floor_collider: Node2D = null

onready var sprite = $Sprite
onready var collider = $CollisionShape2D
onready var hitboxCollider = $Hitbox/Collider
onready var fallDelayTimer = $FallDelayTimer


func _ready() -> void:
    var size = Utils.rand_int_incl(MIN_ROCK_SCALE, MAX_ROCK_SCALE)
    scale = Vector2(size, size)
    set_physics_process(false)
    hitboxCollider.disabled = true
    collider.disabled = true
    visible = false


func _physics_process(delta: float) -> void:
    floor_collision = move_and_collide(Vector2.DOWN, true, true, true)
    if floor_collision:
        floor_collider = floor_collision.collider
        if not floor_collider.is_in_group("WorldBlocks"):
            floor_collision = null

    if falling and not floor_collision:
        apply_gravity(delta)
        hitboxCollider.disabled = false
        motion = move_and_slide(motion, Vector2.UP)
    elif fallDelayTimer.time_left > 0:
        var shake_x = rand_range(-0.5, 0.5)
        var shake_y = rand_range(-0.5, 0.5)
        if sprite.position.x != restore_pos.x and sprite.position.y != restore_pos.y:
            sprite.position = Vector2(restore_pos.x, restore_pos.y)
        else:
            sprite.position = Vector2(sprite.position.x + shake_x, sprite.position.y + shake_y)
    elif falling and floor_collision:
        hitboxCollider.disabled = true
        motion = Vector2.ZERO
        falling = false
        global_position.x = floor_collider.global_position.x
        global_position.y = floor_collider.global_position.y - Utils.BLOCK_SIZE
    else:
        motion = Vector2.ZERO
        hitboxCollider.disabled = true
        falling = false


func adjust_position():
    var x_pos = position.x
    var y_pos = position.y
    x_pos = floor(x_pos)
    y_pos = floor(y_pos)

    position = Vector2(x_pos, y_pos)


func on_floor():
    return floor_collision != null


func apply_gravity(delta):
    motion.y += GRAVITY * delta
    motion.y = min(motion.y, MAX_FALL_SPEED)


func _on_VisibilityNotifier2D_screen_exited() -> void:
    collider.disabled = true
    visible = false
    set_physics_process(false)


func _on_VisibilityNotifier2D_screen_entered() -> void:
    collider.disabled = false
    visible = true
    set_physics_process(true)


func _on_FallDelayTimer_timeout() -> void:
    falling = true
    sprite.position = restore_pos


func _on_FallZone_body_entered(body: Node) -> void:
    if body is Player and not on_floor():
        fallDelayTimer.start(FALL_DELAY)
        restore_pos = Vector2(sprite.position.x, sprite.position.y)
