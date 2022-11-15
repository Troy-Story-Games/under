extends KinematicBody2D
class_name RockDrop

export(int) var GRAVITY = 150
export(int) var MAX_FALL_SPEED = 150
export(int) var EMBED_MAX = 8
export(int) var EMBED_MIN = 2

var mainInstances: MainInstances = Utils.get_main_instances()
var motion: Vector2 = Vector2.ZERO
var done_falling := false
var fix_pos := true
var embed := -1
var stop_pos = 0

onready var hitboxCollider = $Hitbox/Collider


func _physics_process(delta: float) -> void:
    if done_falling and fix_pos:
        apply_gravity(delta)
        motion = move_and_slide(motion, Vector2.UP)
        if motion == Vector2.ZERO:
            fix_pos = false
        return
    if done_falling and not fix_pos:
        return

    # warning-ignore:unsafe_property_access
    var player: Player = mainInstances.player
    if player and is_instance_valid(player):
        stop_pos = max(stop_pos, player.global_position.y)

    apply_gravity(delta)
    position.y += motion.y * delta

    if global_position.y >= stop_pos and embed == -1:
        embed = Utils.rand_int_incl(EMBED_MIN, EMBED_MAX)
    elif embed == 0:
        done_falling = true
        hitboxCollider.disabled = true


func apply_gravity(delta):
    motion.y += GRAVITY * delta
    motion.y = min(motion.y, MAX_FALL_SPEED)


func _on_Digger_body_entered(body: Node) -> void:
    if embed > 0:
        embed -= 1
    if embed != 0:
        if body is Block or body is Rock:
            # warning-ignore:unsafe_method_access
            body.dig()
        elif not body == self:
            body.queue_free()
