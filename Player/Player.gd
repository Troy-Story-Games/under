extends KinematicBody2D
class_name Player

const JumpEffectScene = preload("res://Effects/JumpEffect.tscn")
const WallJumpEffectScene = preload("res://Effects/WallJumpEffect.tscn")

export(int) var ACCELERATION = 150
export(int) var MAX_SPEED = 32
export(float) var FRICTION = 0.65
export(int) var GRAVITY = 200
export(int) var JUMP_FORCE = 85
export(int) var WALL_SLIDE_SPEED = 15
export(int) var MAX_WALL_SLIDE_SPEED = 30
export(int) var CLOSE_CEILING_DISTANCE = 4
export(float) var DOUBLE_PRESS_TIMEOUT = 0.5
export(int) var GROUND_POUND_MAX_SPEED = 250
export(int) var GROUND_POUND_ACCELERATION = 600
export(int) var GROUND_POUND_MAX_EMBED = 8

enum {
    MOVE,
    WALL_SLIDE,
    DIG,
    GROUND_POUND
}

enum WallAxis {
    RIGHT = -1,
    NONE = 0,
    LEFT = 1
}

var wall_collision: KinematicCollision2D = null
var floor_collision: KinematicCollision2D = null
var ceiling_collision: KinematicCollision2D = null
var dig_block = null
var state = MOVE
var motion = Vector2.ZERO
var just_jumped = false
var double_jump = true
var just_spawned = true
var playerStats : PlayerStats = Utils.get_player_stats()
var embed = -1
var ground_pound_start_pos = 0
var double_press_horizontal = null
var double_press_down = null

onready var sprite = $Sprite
onready var cameraFollow = $CameraFollow
onready var footstepPlayer = $FootstepAudioStreamPlayer2D
onready var coyoteJumpTimer = $CoyoteJumpTimer
onready var animationPlayer = $AnimationPlayer
onready var blinkAnimationPlayer = $BlinkAnimationPlayer
onready var safeSpawnArea = $SafeSpawnArea
onready var groundPoundDiggerCollider = $GroundPoundDigger/CollisionShape2D
onready var fallTimer = $FallTimer
onready var hurtbox = $Hurtbox


func _ready():
    just_spawned = true
    groundPoundDiggerCollider.disabled = true
    hurtbox.connect("invincibility_ended", self, "_on_Hurtbox_invincibility_ended")
    start_invincibility(3)


func start_invincibility(duration: float):
    blinkAnimationPlayer.play("Blink")
    hurtbox.start_invincibility(duration)


func _on_Hurtbox_invincibility_ended():
    blinkAnimationPlayer.play("RESET")


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
            double_press_check()
            dig_check()

        WALL_SLIDE:
            var wall_axis = get_wall_axis()
            if wall_axis != 0:
                sprite.scale.x = wall_axis  # Face the correct direction

            # Check for wall jump
            jump_check()

            # Check for falling off wall
            wall_slide_drop(delta)

            move()  # We gotta move

            # This can switch the state to something else (ground pound or dig)
            double_press_check()

            # If we switched state with double_press_check() don't detach, b/c we already did
            if state == WALL_SLIDE:
                # Switch back to move state if we aren't on wall anymore
                wall_detach(delta, wall_axis)

        DIG:
            if not dig_block or not is_instance_valid(dig_block):
                dig_block = null
                state = MOVE
            else:
                dig_block.dig(true)

            if Input.is_action_just_released("ui_down") or Input.is_action_just_released("ui_left") or Input.is_action_just_released("ui_right"):
                state = MOVE

        GROUND_POUND:
            if embed == -1 and ground_pound_start_pos == 0:
                animationPlayer.play("GroundPoundStart")
                groundPoundDiggerCollider.disabled = false
                ground_pound_start_pos = global_position.y

            if embed == 0:
                embed = -1
                groundPoundDiggerCollider.disabled = true
                ground_pound_start_pos = 0
                state = MOVE
                Events.emit_signal("add_screenshake", 0.055, 0.2)
            else:
                motion.y += GROUND_POUND_ACCELERATION * delta
                motion.y = min(motion.y, GROUND_POUND_MAX_SPEED)
                position.y += motion.y * delta

    if just_spawned:
        # If we just spawned, set to false, then make a safe spawn spot
        just_spawned = false
        var spawn_pos = Vector2(global_position.x, global_position.y)
        while true:
            # We busy loop, yielding execution once per frame until we've moved
            # at least 4 pixels. During this time any block (including rocks)
            # will be deleted to make sure the player spawns back in and is not
            # stuck
            yield(get_tree(), "idle_frame")
            make_safe_spawn()

            if spawn_pos.distance_to(global_position) >= 4:
                break


func make_safe_spawn():
    var bodies = safeSpawnArea.get_overlapping_bodies()
    for body in bodies:
        if not body or not is_instance_valid(body):
            continue
        if not body.is_queued_for_deletion() and body.is_in_group("WorldBlocks"):
            body.queue_free()



func get_input_vector():
    var input_vector = Vector2.ZERO
    input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
    return input_vector


func apply_horizontal_force(input_vector, delta):
    if input_vector.x != 0:
        motion.x += input_vector.x * ACCELERATION * delta
        motion.x = clamp(motion.x, -MAX_SPEED, MAX_SPEED)


func apply_friction(input_vector):
    if input_vector.x == 0 and on_floor():
        motion.x = lerp(motion.x, 0, FRICTION)


func jump_check():
    var jump_just_pressed: bool = (Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("jump"))
    var jump_just_released: bool = (Input.is_action_just_released("ui_up") or Input.is_action_just_released("jump"))
    var wall_axis = get_wall_axis()
    if not on_floor() and wall_axis != WallAxis.NONE and jump_just_pressed:
        # Wall jump
        motion.x = wall_axis * MAX_SPEED

        var wall_jump_effect = Utils.instance_scene_on_main(WallJumpEffectScene, global_position)
        wall_jump_effect.scale.x *= wall_axis

        jump(JUMP_FORCE/1.25)
        just_jumped = true
    elif (on_floor() or coyoteJumpTimer.time_left > 0) and not ceiling_close() and jump_just_pressed:
        # Regular jump

        # warning-ignore:return_value_discarded
        Utils.instance_scene_on_main(JumpEffectScene, global_position)

        jump(JUMP_FORCE)
        just_jumped = true
    else:
        if jump_just_released and motion.y < -JUMP_FORCE / 2:
            motion.y = -JUMP_FORCE / 2

        if jump_just_pressed and double_jump == true:
            # Handle double jump

            # warning-ignore:return_value_discarded
            Utils.instance_scene_on_main(JumpEffectScene, global_position)

            jump(JUMP_FORCE * 0.75)
            double_jump = false


func ground_pound_check():
    if not on_floor():
        state = GROUND_POUND


func jump(force):
    SoundFx.play("jump", 1, -8)
    motion.y = -force


func apply_gravity(delta):
    motion.y += GRAVITY * delta
    motion.y = min(motion.y, JUMP_FORCE)


func update_animations(input_vector):
    if input_vector.x != 0:
        sprite.scale.x = sign(input_vector.x)
        animationPlayer.play("Run")
        if not footstepPlayer.playing and on_floor():
            footstepPlayer.play()
    else:
        animationPlayer.play("Idle")
        footstepPlayer.stop()

    # Override run/idle if we're in the air
    if not on_floor():
        footstepPlayer.stop()
        animationPlayer.play("Jump")


func on_floor():
    return floor_collision != null and is_instance_valid(floor_collision) and not floor_collision.is_queued_for_deletion()


func on_wall():
    return wall_collision != null and is_instance_valid(wall_collision) and not wall_collision.is_queued_for_deletion()


func ceiling_close():
    return ceiling_collision != null and is_instance_valid(ceiling_collision) and not ceiling_collision.is_queued_for_deletion()


func double_press_dig():
    if state != WALL_SLIDE:
        return

    var right_wall: KinematicCollision2D = move_and_collide(Vector2.RIGHT, true, true, true)
    var left_wall: KinematicCollision2D = move_and_collide(Vector2.LEFT, true, true, true)
    var collider = null

    if right_wall:
        collider = right_wall.collider
    elif left_wall:
        collider = left_wall.collider

    if collider == null or (not collider is DirtBlock and not collider is ChestBlock):
        return

    dig_block = collider
    state = DIG


func double_press_check():
    if Input.is_action_just_pressed("ui_right") and double_press_horizontal == null:
        double_press_horizontal = "ui_right"
        yield(get_tree().create_timer(DOUBLE_PRESS_TIMEOUT), "timeout")
        double_press_horizontal = null
    if Input.is_action_just_pressed("ui_right") and double_press_horizontal == "ui_right":
        double_press_dig()
        double_press_horizontal = null

    if Input.is_action_just_pressed("ui_left") and double_press_horizontal == null:
        double_press_horizontal = "ui_left"
        yield(get_tree().create_timer(DOUBLE_PRESS_TIMEOUT), "timeout")
        double_press_horizontal = null
    if Input.is_action_just_pressed("ui_left") and double_press_horizontal == "ui_left":
        double_press_dig()
        double_press_horizontal = null

    if Input.is_action_just_pressed("ui_down") and double_press_down == null:
        double_press_down = "ui_down"
        yield(get_tree().create_timer(DOUBLE_PRESS_TIMEOUT), "timeout")
        double_press_down = null
    if Input.is_action_just_pressed("ui_down") and double_press_down == "ui_down":
        ground_pound_check()
        double_press_down = null


func move():
    var was_in_air = not on_floor()
    var was_on_floor = on_floor()
    var last_motion = motion
    var last_position = position

    motion = move_and_slide(motion, Vector2.UP)

    var test_floor: Vector2 = Vector2(0, 1)
    floor_collision = move_and_collide(test_floor, true, true, true)

    var test_wall: Vector2 = Vector2(sign(last_motion.x), 0)
    wall_collision = move_and_collide(test_wall, true, true, true)

    var test_ceiling: Vector2 = Vector2(0, CLOSE_CEILING_DISTANCE * -1)
    ceiling_collision = move_and_collide(test_ceiling, true, true, true)

    # Happens on landing
    if was_in_air and on_floor():
        if fallTimer.time_left == 0:
            SoundFx.play("playerland", 1, -20)
        fallTimer.stop()

        # Fix for move_and_slide_with_snap causing us to
        # lose momentum when landing on a slope
        motion.x = last_motion.x

        # On landing we get double jump back
        double_jump = true

    # Just left the ground
    if was_on_floor and not on_floor() and not just_jumped:
        # Fix for little hop if you fall off a ledge after
        # climbing a slope
        fallTimer.start()
        motion.y = 0
        position.y = last_position.y
        coyoteJumpTimer.start()


func wall_slide_check():
    if not on_floor() and on_wall():
        var wall_axis = get_wall_axis()
        if wall_axis == WallAxis.LEFT and Input.is_action_pressed("ui_left"):
            state = WALL_SLIDE
            double_jump = true
        if wall_axis == WallAxis.RIGHT and Input.is_action_pressed("ui_right"):
            state = WALL_SLIDE
            double_jump = true


func get_wall_axis():
    var is_right_wall = test_move(transform, Vector2.RIGHT)
    var is_left_wall = test_move(transform, Vector2.LEFT)
    return int(is_left_wall) - int(is_right_wall)


func wall_slide_drop(delta):
    var max_slide_speed = WALL_SLIDE_SPEED
    if Input.is_action_pressed("ui_down"):
        max_slide_speed = MAX_WALL_SLIDE_SPEED
    motion.y = min(motion.y + GRAVITY * delta, max_slide_speed)


func wall_detach(delta, wall_axis):
    if wall_axis == WallAxis.LEFT and Input.is_action_just_released("ui_left"):
        motion.x = -ACCELERATION * delta
        state = MOVE
    if wall_axis == WallAxis.RIGHT and Input.is_action_just_released("ui_right"):
        motion.x = ACCELERATION * delta
        state = MOVE

    if wall_axis == 0 or on_floor():
        state = MOVE


func assign_camera_follow(remote_path: String):
    cameraFollow.remote_path = remote_path


func dig_check():
    if (Input.is_action_pressed("ui_right") or Input.is_action_pressed("ui_left")) and wall_collision and on_floor():
        var wall_collider: Node = wall_collision.collider
        if wall_collider is DirtBlock or wall_collider is ChestBlock:
            dig_block = wall_collider
            state = DIG

    if Input.is_action_pressed("ui_down") and floor_collision:
        var floor_collider: Node = floor_collision.collider
        if floor_collider is DirtBlock or floor_collider is ChestBlock:
            dig_block = floor_collider
            state = DIG

    if (Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("ui_up")) and ceiling_collision and ceiling_close():
        var ceiling_collider: Node = ceiling_collision.collider
        if ceiling_collider is DirtBlock or ceiling_collider is ChestBlock:
            dig_block = ceiling_collider
            state = DIG


func take_damage(damage: int) -> void:
    if hurtbox.invincible:
        return

    # TODO: Consider playing a sound effect
    playerStats.health -= damage
    # TODO: Consider playing a flash or damage animation


func _on_Hurtbox_take_damage(damage : int, _area : Area2D):
    take_damage(damage)


func _on_ItemCollector_body_entered(body):
    if body is CollectibleItem:
        if body.VALUE >= 10:
            SoundFx.play("pickup_emerald", 1, -15)
        playerStats.dirt += body.VALUE
    body.queue_free()


func _on_GroundPoundDigger_body_entered(body: Node) -> void:
    if embed == -1:
        embed = clamp(int(ceil((global_position.y - ground_pound_start_pos) / float(Utils.BLOCK_SIZE))), 1, GROUND_POUND_MAX_EMBED)
    if embed > 0:
        embed -= 1

    if embed != 0:
        if body.has_method("dig"):
            body.call_deferred("dig")
            # Can't check is Rock b/c Godot is bad (or maybe I am)
            if body.is_in_group("Rock") or body is ChestBlock:
                embed = 0
        elif body.has_method("explode"):
            body.call_deferred("explode")
        elif not body == self:
            body.queue_free()


func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
    if anim_name == "GroundPoundStart":
        animationPlayer.play("GroundPound")
