extends Area2D
class_name Hurtbox

signal take_damage(damage, area)
signal invincibility_started()
signal invincibility_ended()

var invincible : bool = false setget set_invincible

onready var invincibilityTimer : Timer = $InvinvibilityTimer


func set_invincible(value : bool):
    invincible = value
    if invincible == true:
        emit_signal("invincibility_started")
    else:
        emit_signal("invincibility_ended")


func start_invincibility(duration : float):
    self.invincible = true
    invincibilityTimer.start(duration)


func _on_Hurtbox_area_entered(area : Area2D):
    if area is Hitbox and not self.invincible:
        # warning-ignore:unsafe_property_access
        # warning-ignore:unsafe_property_access
        emit_signal("take_damage", area.DAMAGE, area)


func _on_InvinvibilityTimer_timeout():
    self.invincible = false
