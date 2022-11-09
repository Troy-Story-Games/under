extends KinematicBody2D
class_name Enemy

onready var stats = $EnemyStats


func _on_EnemyStats_enemy_died():
    # TODO: Consider instancing a death effect here
    queue_free()


func _on_Hurtbox_take_damage(damage : int, _area: Area2D):
    stats.health -= damage
