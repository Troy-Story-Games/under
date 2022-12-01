extends Block
class_name GoalBlock

const EmeraldPhysicsParticleScene = preload("res://Effects/BlockEffects/ParticleTypes/EmeraldPhysicsParticle.tscn")
const EmeraldPhysicsParticleSmallScene = preload("res://Effects/BlockEffects/ParticleTypes/EmeraldPhysicsParticleSmall.tscn")

# How long is the player invincible after beating the level
export(float) var INVINCIBLE_FOR = 5.0

var mainInstances = Utils.get_main_instances()
var dug = false

onready var animationPlayer = $AnimationPlayer


func dig(throw: bool = false) -> void:
    if dug:
        return

    collider.disabled = true
    dug = true
    Events.emit_signal("depth_goal_reached")
    animationPlayer.play("Dig")
    if mainInstances.player and is_instance_valid(mainInstances.player):
        mainInstances.player.start_invincibility(INVINCIBLE_FOR)

    # Slowmo
    get_tree().paused = true
    SoundFx.play("level-up", 1, -15)
    yield(get_tree().create_timer(0.2), "timeout")
    Engine.time_scale = 0.2
    get_tree().paused = false

    for child in get_children():
        if child is Sprite:
            var effect: DestroyEffect = Utils.instance_scene_on_main(DestroyEffectScene, child.global_position)
            effect.create_effect(EmeraldPhysicsParticleScene, EmeraldPhysicsParticleSmallScene, throw)

    yield(get_tree().create_timer(0.2), "timeout")
    Engine.time_scale = 1.0
    queue_free()
