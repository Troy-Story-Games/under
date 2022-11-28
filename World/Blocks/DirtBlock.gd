extends KinematicBody2D
class_name DirtBlock

const DestroyEffectScene = preload("res://Effects/BlockEffects/DestroyEffect.tscn")
const DirtPhysicsParticleScene = preload("res://Effects/BlockEffects/ParticleTypes/DirtPhysicsParticle.tscn")
const DirtPhysicsParticleSmallScene = preload("res://Effects/BlockEffects/ParticleTypes/DirtPhysicsParticleSmall.tscn")

var on_screen: = false

onready var collider = $CollisionShape2D


func _ready() -> void:
    set_physics_process(false)
    collider.disabled = true
    visible = false


func dig() -> void:
    # warning-ignore:return_value_discarded
    if on_screen:
        var effect: DestroyEffect = Utils.instance_scene_on_main(DestroyEffectScene, global_position)
        effect.create_effect(DirtPhysicsParticleScene, DirtPhysicsParticleSmallScene)
    SoundFx.play("digging", 1, -15)
    queue_free()


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
