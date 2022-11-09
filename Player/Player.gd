extends KinematicBody2D
class_name Player

signal player_died()

export(int) var ACCELERATION = 512
export(int) var MAX_SPEED = 64
export(float) var FRICTION = 0.25
export(int) var GRAVITY = 200
export(int) var JUMP_FORCE = 128
export(int) var WALL_SLIDE_SPEED = 48
export(int) var MAX_WALL_SLIDE_SPEED = 128

enum {
    MOVE,
    WALL_SLIDE
}

var state = MOVE
var motion = Vector2.ZERO
var just_jumped = false
var double_jump = true
var playerStats : PlayerStats = Utils.get_player_stats()

onready var sprite = $Sprite
onready var coyoteJumpTimer = $CoyoteJumpTimer
onready var animationPlayer = $AnimationPlayer


func _ready():
    # warning-ignore:return_value_discarded
    playerStats.connect("player_died", self, "_on_died")


func _physics_process(delta):
    just_jumped = false

    match state:
        MOVE:
            var input_vector = get_input_vector()
            apply_horizontal_force(input_vector, delta)
            apply_friction(input_vector)
            jump_check()
            apply_gravity(delta)
            update_animations(input_vector)
            move()
            wall_slide_check()

        WALL_SLIDE:
            var wall_axis = get_wall_axis()
            if wall_axis != 0:
                sprite.scale.x = wall_axis  # Face the correct direction

            # Check for wall jump
            wall_slide_jump_check(wall_axis)

            # Check for falling off wall
            wall_slide_drop(delta)

            move()  # We gotta move

            # Switch back to move state if we aren't on wall anymore
            wall_detach(delta, wall_axis)


func get_input_vector():
    var input_vector = Vector2.ZERO
    input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
    return input_vector


func apply_horizontal_force(input_vector, delta):
    if input_vector.x != 0:
        motion.x += input_vector.x * ACCELERATION * delta
        motion.x = clamp(motion.x, -MAX_SPEED, MAX_SPEED)


func apply_friction(input_vector):
    if input_vector.x == 0 and is_on_floor():
        motion.x = lerp(motion.x, 0, FRICTION)


func jump_check():
    if is_on_floor() or coyoteJumpTimer.time_left > 0:
        if Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("jump"):
            jump(JUMP_FORCE)
            just_jumped = true
    else:
        if (Input.is_action_just_released("ui_up") or Input.is_action_just_released("jump")) and motion.y < -JUMP_FORCE / 2:
            motion.y = -JUMP_FORCE / 2

        if (Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("jump")) and double_jump == true:
            # Handle double jump
            jump(JUMP_FORCE * 0.75)
            double_jump = false


func jump(force):
    motion.y = -force


func apply_gravity(delta):
    if not is_on_floor():
        motion.y += GRAVITY * delta
        motion.y = min(motion.y, JUMP_FORCE)


func update_animations(input_vector):

    if input_vector.x != 0:
        sprite.scale.x = sign(input_vector.x)
        animationPlayer.play("Run")
    else:
        animationPlayer.play("Idle")

    # Override run/idle if we're in the air
    if not is_on_floor():
        pass  # TODO: Play jump animation


func move():
    var was_in_air = not is_on_floor()
    var was_on_floor = is_on_floor()
    var last_motion = motion
    var last_position = position

    motion = move_and_slide(motion, Vector2.UP)

    # Happens on landing
    if was_in_air and is_on_floor():
        # Fix for move_and_slide_with_snap causing us to
        # lose momentum when landing on a slope
        motion.x = last_motion.x

        # On landing we get double jump back
        double_jump = true

    # Just left the ground
    if was_on_floor and not is_on_floor() and not just_jumped:
        # Fix for little hop if you fall off a ledge after
        # climbing a slope
        motion.y = 0
        position.y = last_position.y
        coyoteJumpTimer.start()


func wall_slide_check():
    if not is_on_floor() and is_on_wall():
        state = WALL_SLIDE
        double_jump = true


func get_wall_axis():
    var is_right_wall = test_move(transform, Vector2.RIGHT)
    var is_left_wall = test_move(transform, Vector2.LEFT)
    return int(is_left_wall) - int(is_right_wall)


func wall_slide_jump_check(wall_axis):
    if (Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("jump")):
        motion.x = wall_axis * MAX_SPEED
        motion.y = -JUMP_FORCE/1.25
        state = MOVE


func wall_slide_drop(delta):
    var max_slide_speed = WALL_SLIDE_SPEED
    if Input.is_action_pressed("ui_down"):
        max_slide_speed = MAX_WALL_SLIDE_SPEED
    motion.y = min(motion.y + GRAVITY * delta, max_slide_speed)


func wall_detach(delta, wall_axis):
    if Input.is_action_just_pressed("ui_right"):
        motion.x = ACCELERATION * delta
        state = MOVE

    if Input.is_action_just_pressed("ui_left"):
        motion.x = -ACCELERATION * delta
        state = MOVE

    if wall_axis == 0 or is_on_floor():
        state = MOVE


func _on_died():
    emit_signal("player_died")
    queue_free()


func _on_Hurtbox_take_damage(damage : int, _area : Area2D):
    # TODO: Consider playing a sound effect
    playerStats.health -= damage
    # TODO: Consider playing a flash or damage animation
