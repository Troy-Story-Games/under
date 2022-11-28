extends KinematicBody2D
class_name BombBlock

# The explode radius in number of blocks
export(int) var EXPLODE_RADIUS = 2
export(float) var FUSE_TIME = 1.25
export(int) var DAMAGE = 1

onready var sprite = $Sprite
onready var fuseTimer = $FuseTimer
onready var explodeArea = $ExplodeArea
onready var explodeAreaCollider = $ExplodeArea/CollisionShape2D
onready var blinkAnimationPlayer = $BlinkAnimationPlayer


func _ready():
    # Setup the explode area size based on configs
    var shape: RectangleShape2D = explodeAreaCollider.shape
    shape.extents.x = 12 + ((EXPLODE_RADIUS - 1) * Utils.BLOCK_SIZE)
    shape.extents.y = 12 + ((EXPLODE_RADIUS - 1) * Utils.BLOCK_SIZE)
    var mat: ShaderMaterial = sprite.material
    var shader: Shader = mat.shader
    shader.set("shader_param/active", false)


func in_x_range(pos: Vector2):
    var left_x = global_position.x - Utils.HALF_BLOCK_SIZE
    var right_x = global_position.x + Utils.HALF_BLOCK_SIZE
    if pos.x > left_x and pos.x < right_x:
        return true
    return false


func in_y_range(pos: Vector2):
    var top_y = global_position.y - Utils.HALF_BLOCK_SIZE
    var bottom_y = global_position.y + Utils.HALF_BLOCK_SIZE
    if pos.y < bottom_y and pos.y > top_y:
        return true
    return false


func explode():
    Events.emit_signal("add_screenshake", 0.055, 0.2)
    SoundFx.play("bomb_explode", 0.8, -15)
    var bodies: Array = explodeArea.get_overlapping_bodies()
    for body in bodies:
        if not body.is_in_group("Player") and not body.is_in_group("WorldBlocks"):
            continue
        if body == self:
            continue

        var delete = false
        if in_x_range(body.global_position):
            delete = true
        elif in_y_range(body.global_position):
            delete = true

        if not delete:
            continue

        if body.has_method("trigger"):
            body.trigger()
        elif body.has_method("dig"):
            body.dig()
        elif body.has_method("take_damage"):
            body.take_damage(DAMAGE)
        else:
            body.queue_free()

    queue_free()


func trigger():
    SoundFx.play("bomb_fuse", 0.25, -20)
    blinkAnimationPlayer.play("BlinkAnimation")
    if fuseTimer.time_left == 0:
        fuseTimer.start(FUSE_TIME)


func _on_PlayerCheckArea_body_entered(body: Node) -> void:
    if body is Player:
        trigger()


func _on_FuseTimer_timeout() -> void:
    explode()
