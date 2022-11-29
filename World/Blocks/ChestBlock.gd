extends Block
class_name ChestBlock

const EmeraldPhysicsParticleScene = preload("res://Effects/BlockEffects/ParticleTypes/EmeraldPhysicsParticle.tscn")
const EmeraldPhysicsParticleSmallScene = preload("res://Effects/BlockEffects/ParticleTypes/EmeraldPhysicsParticleSmall.tscn")
const RockPhysicsParticleScene = preload("res://Effects/BlockEffects/ParticleTypes/RockPhysicsParticle.tscn")
const RockPhysicsParticleSmallScene = preload("res://Effects/BlockEffects/ParticleTypes/RockPhysicsParticleSmall.tscn")

onready var timer = $Timer
onready var animationPlayer = $BlinkAnimationPlayer


func spawn_emeralds(throw: bool = false):
    var effect: DestroyEffect = Utils.instance_scene_on_main(DestroyEffectScene, global_position)
    effect.create_effect(EmeraldPhysicsParticleScene, EmeraldPhysicsParticleSmallScene, throw)


func dig(throw: bool = false) -> void:
    if not throw:
        # Broken by falling rock or bomb
        spawn_emeralds()
        SoundFx.play("pickup_emerald", 1, -15)
        queue_free()
        return

    if timer.time_left > 0:
        return

    # Switch to open and spawn emeralds
    sprite.frame = 3
    SoundFx.play("chest_open", 1, -15)
    spawn_emeralds(throw)
    collider.disabled = true
    timer.start(3)


func _on_Timer_timeout() -> void:
    animationPlayer.play("Blink")
