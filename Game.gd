extends Node2D
class_name MainGame

const Block = preload("res://World/Block.tscn")
const NUM_COLS = 12
const BLOCK_SIZE = 8

export(int) var REGENERATE_BLOCK_THRESHOLD = 80
export(int) var ROW_BUFFER = 18

onready var player = $Player
onready var leftWall = $LeftWall
onready var rightWall = $RightWall
onready var newRowSpawn = $NewRowSpawn


func _ready():
    player.connect("player_died", self, "_on_Player_player_died")
    generate_more_blocks()


func _process(_delta: float) -> void:
    var y_pos : float = player.position.y
    leftWall.position.y = y_pos
    rightWall.position.y = y_pos

    if abs(newRowSpawn.global_position.y - player.global_position.y) < REGENERATE_BLOCK_THRESHOLD:
        generate_more_blocks(true)


func _on_Player_player_died():
    yield(get_tree().create_timer(1.0), "timeout")
    # warning-ignore:return_value_discarded
    get_tree().change_scene("res://Menus/GameOverMenu.tscn")


func generate_more_blocks(slow: bool = false):
    print("DEBUG: Generating more blocks!")

    # Get position
    var pos: Vector2 = newRowSpawn.position

    # Update the row spawn position
    newRowSpawn.position.y += (ROW_BUFFER * BLOCK_SIZE)

    for row in range(ROW_BUFFER):
        for col in range(NUM_COLS):
            var x : float = pos.x + (col * BLOCK_SIZE) + (BLOCK_SIZE / 2.0)
            var y : float = pos.y + (row * BLOCK_SIZE) + (BLOCK_SIZE / 2.0)
            # warning-ignore:return_value_discarded
            Utils.instance_scene_on_main(Block, Vector2(x, y))
            if slow:
                yield(get_tree(), "idle_frame")


