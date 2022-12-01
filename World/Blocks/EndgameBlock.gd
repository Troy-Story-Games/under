extends Block
class_name EndgameBlock

const EmeraldPhysicsParticleScene = preload("res://Effects/BlockEffects/ParticleTypes/EmeraldPhysicsParticle.tscn")
const EmeraldPhysicsParticleSmallScene = preload("res://Effects/BlockEffects/ParticleTypes/EmeraldPhysicsParticleSmall.tscn")

var dug := false


func dig(throw: bool = false) -> void:
    if dug:
        return

    Events.emit_signal("win_game")
    collider.disabled = true
    dug = true

    # Slowmo
    get_tree().paused = true
    SoundFx.play("level-up", 1, -15)
    yield(get_tree().create_timer(0.2), "timeout")
    Engine.time_scale = 0.2
    get_tree().paused = false

    var children = get_children()
    children.shuffle()
    for child in children:
        if child is Sprite:
            var effect: DestroyEffect = Utils.instance_scene_on_main(DestroyEffectScene, child.global_position)
            effect.create_effect(EmeraldPhysicsParticleScene, EmeraldPhysicsParticleSmallScene, throw)
            child.visible = false
            yield(get_tree().create_timer(0.01), "timeout")

    yield(get_tree().create_timer(0.2), "timeout")
    Engine.time_scale = 1.0
    queue_free()
