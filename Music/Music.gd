extends Node

# Auto-load singleton to play game music

export(Array, AudioStream) var music_list := []

var music_list_index := 0

onready var musicPlayer : AudioStreamPlayer = $AudioStreamPlayer


func _ready():
    music_list.shuffle()


func list_play():
    assert(music_list.size() > 0)
    musicPlayer.stream = music_list[music_list_index]
    musicPlayer.play()
    music_list_index += 1
    if music_list_index == music_list.size():
        music_list.shuffle()
        music_list_index = 0


func list_stop():
    musicPlayer.stop()


func _on_AudioStreamPlayer_finished():
    list_play()
