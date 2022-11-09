extends Node2D

onready var player = $Player
onready var leftWall = $LeftWall
onready var rightWall = $RightWall

func _ready():
    player.connect("player_died", self, "_on_Player_player_died")


func _process(_delta: float) -> void:
    var y_pos : float = player.position.y
    leftWall.position.y = y_pos
    rightWall.position.y = y_pos


func _on_Player_player_died():
    yield(get_tree().create_timer(1.0), "timeout")
    #get_tree().change_scene("res://Menus/GameOverMenu.tscn")
