extends Block
class_name DirtBlock

const DirtPhysicsParticleScene = preload("res://Effects/BlockEffects/ParticleTypes/DirtPhysicsParticle.tscn")
const DirtPhysicsParticleSmallScene = preload("res://Effects/BlockEffects/ParticleTypes/DirtPhysicsParticleSmall.tscn")


func dig(throw: bool = false) -> void:
    if on_screen:
        var effect: DestroyEffect = Utils.instance_scene_on_main(DestroyEffectScene, global_position)
        effect.create_effect(DirtPhysicsParticleScene, DirtPhysicsParticleSmallScene, throw)
    SoundFx.play("digging", 1, -15)
    queue_free()
