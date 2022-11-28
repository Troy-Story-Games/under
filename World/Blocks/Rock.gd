extends KinematicBody2D
class_name Rock

const DestroyEffectScene = preload("res://Effects/BlockEffects/DestroyEffect.tscn")
const RockPhysicsParticleScene = preload("res://Effects/BlockEffects/ParticleTypes/RockPhysicsParticle.tscn")
const RockPhysicsParticleSmallScene = preload("res://Effects/BlockEffects/ParticleTypes/RockPhysicsParticleSmall.tscn")

export(int) var GRAVITY = 500
export(int) var MAX_FALL_SPEED = 300
export(float) var FALL_DELAY = 0.75

var motion : Vector2 = Vector2.ZERO
var falling := false
var restore_pos : Vector2 = Vector2.ZERO
var floor_collision : KinematicCollision2D = null
var floor_collider: Node2D = null
var player: Player = null
var on_screen: = false

onready var sprite = $Sprite
onready var collider = $CollisionShape2D
onready var hitboxCollider = $Hitbox/Collider
onready var fallDelayTimer = $FallDelayTimer


func _ready() -> void:
    set_physics_process(false)
    hitboxCollider.disabled = true
    collider.disabled = true
    visible = false


func dig() -> void:
    # warning-ignore:return_value_discarded
    if on_screen:
        var effect: DestroyEffect = Utils.instance_scene_on_main(DestroyEffectScene, global_position)
        effect.create_effect(RockPhysicsParticleScene, RockPhysicsParticleSmallScene)
    SoundFx.play("digging", 1, -15)
    queue_free()


func _physics_process(delta: float) -> void:
    floor_collision = move_and_collide(Vector2.DOWN, true, true, true)
    if floor_collision:
        floor_collider = floor_collision.collider
        if floor_collider is Player:
            # warning-ignore:unsafe_property_access
            if floor_collider.hurtbox.invincible:
                dig()
        elif not floor_collider.is_in_group("WorldBlocks"):
            floor_collision = null
            floor_collider = null

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
        SoundFx.play("rockdrop_landing", 0.75, -15)
        hitboxCollider.disabled = true
        motion = Vector2.ZERO
        falling = false
        global_position.x = floor_collider.global_position.x
        global_position.y = floor_collider.global_position.y - Utils.BLOCK_SIZE
    else:
        motion = Vector2.ZERO
        hitboxCollider.disabled = true
        falling = false

    if player and not on_floor() and fallDelayTimer.time_left == 0:
        fallDelayTimer.start(FALL_DELAY)
        restore_pos = Vector2(sprite.position.x, sprite.position.y)


func on_floor():
    return floor_collision != null


func apply_gravity(delta):
    motion.y += GRAVITY * delta
    motion.y = min(motion.y, MAX_FALL_SPEED)


func _on_VisibilityNotifier2D_screen_exited() -> void:
    collider.disabled = true
    visible = false
    on_screen = false
    set_physics_process(false)


func _on_VisibilityNotifier2D_screen_entered() -> void:
    collider.disabled = false
    visible = true
    on_screen = true
    set_physics_process(true)


func _on_FallDelayTimer_timeout() -> void:
    falling = true
    sprite.position = restore_pos


func _on_FallZone_body_entered(body: Node) -> void:
    if body is Player:
        player = body


func _on_FallZone_body_exited(body):
    if body is Player:
        player = null
