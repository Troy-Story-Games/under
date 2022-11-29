extends KinematicBody2D
class_name RockDrop

const DestroyEffectScene = preload("res://Effects/BlockEffects/DestroyEffect.tscn")
const RockPhysicsParticleScene = preload("res://Effects/BlockEffects/ParticleTypes/RockPhysicsParticle.tscn")
const RockPhysicsParticleSmallScene = preload("res://Effects/BlockEffects/ParticleTypes/RockPhysicsParticleSmall.tscn")
const RockScene = preload("res://World/Blocks/Rock.tscn")

export(int) var GRAVITY = 300
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


func handle_invincible_player_collision():
    var floor_collision = move_and_collide(Vector2.DOWN, true, true, true)
    if not floor_collision:
        return

    var floor_collider = floor_collision.collider
    # warning-ignore:unsafe_property_access
    if floor_collider is Player and floor_collider.hurtbox.invincible:
        var effect: DestroyEffect = Utils.instance_scene_on_main(DestroyEffectScene, global_position)
        effect.create_effect(RockPhysicsParticleScene, RockPhysicsParticleSmallScene)
        queue_free()


func _physics_process(delta: float) -> void:
    handle_invincible_player_collision()

    if done_falling and fix_pos:
        apply_gravity(delta)
        motion = move_and_slide(motion, Vector2.UP)
        if motion == Vector2.ZERO:
            fix_pos = false
            switch_to_rock()
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
        Events.emit_signal("add_screenshake", 0.055, 0.2)
        SoundFx.play("rockdrop_landing", 1, -15)
        done_falling = true
        hitboxCollider.disabled = true
    elif embed > 0 and global_position.y > (stop_pos * 2):
        # It's possible for the rock to end up out of bounds
        # if it falls into a cave and then passed the point
        # where we've generate more level.
        queue_free()


func apply_gravity(delta):
    motion.y += GRAVITY * delta
    motion.y = min(motion.y, MAX_FALL_SPEED)


func switch_to_rock():
    # warning-ignore:return_value_discarded
    Utils.instance_scene_on_main(RockScene, global_position)
    queue_free()


func _on_Digger_body_entered(body: Node) -> void:
    if embed > 0:
        embed -= 1
    if embed != 0:
        if body.has_method("dig"):
            # warning-ignore:unsafe_method_access
            body.call_deferred("dig")
        elif not body == self:
            body.queue_free()
