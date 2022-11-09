extends Node2D
class_name Projectile

var velocity := Vector2.ZERO


func _process(delta):
    position += velocity * delta


func _on_VisibilityNotifier2D_viewport_exited(_viewport : Viewport):
    queue_free()


func _on_Hitbox_body_entered(_body : Node):
    # TODO: Consider instancing an explosion effect
    queue_free()  # Destroy projectile when it hits a wall


func _on_Hitbox_area_entered(_area : Area2D):
    # TODO: Consider instancing an explosion effect
    queue_free()  # When a projectile hits a hurtbox it will destroy itself
