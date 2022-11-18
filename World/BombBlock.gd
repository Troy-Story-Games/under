extends KinematicBody2D
class_name BombBlock

enum ExplodeShape {
    CIRCLE,
    PLUS,
    DIAG
}

# The explode radius in number of blocks
export(int) var EXPLODE_RADIUS = 2
export(float) var FUSE_TIME = 1.25
export(ExplodeShape) var EXPLODE_SHAPE = ExplodeShape.PLUS

onready var fuseTimer = $FuseTimer
onready var explodeArea = $ExplodeArea
onready var explodeAreaCollider = $ExplodeArea/CollisionShape2D


func _ready():
    var shape: RectangleShape2D = explodeAreaCollider.shape
    shape.extents.x = 12 + ((EXPLODE_RADIUS - 1) * Utils.BLOCK_SIZE)
    shape.extents.y = 12 + ((EXPLODE_RADIUS - 1) * Utils.BLOCK_SIZE)


func explode():
    var bodies: Array = explodeArea.get_overlapping_bodies()
    for body in bodies:
        if not body.is_in_group("WorldBlocks"):
            continue
        if body == self:
            continue

        var delete = false
        match EXPLODE_SHAPE:
            ExplodeShape.CIRCLE:
                delete = true
            ExplodeShape.PLUS:
                if body.global_position.x == self.global_position.x:
                    delete = true
                elif body.global_position.y == self.global_position.y:
                    delete = true
            ExplodeShape.DIAG:
                if body.global_position.x != self.global_position.x and body.global_position.y != self.global_position.y:
                    delete = true

        if not delete:
            continue

        if body.has_method("trigger"):
            body.trigger()
        else:
            body.queue_free()

    queue_free()


func trigger():
    if fuseTimer.time_left == 0:
        fuseTimer.start(FUSE_TIME)


func _on_PlayerCheckArea_body_entered(body: Node) -> void:
    if body is Player:
        trigger()


func _on_FuseTimer_timeout() -> void:
    explode()
