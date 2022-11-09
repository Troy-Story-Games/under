extends Node

# Auto-load singleton to play sound effects

# TODO: Uncomment and set sound path
#var sounds_path = "res://SET_THIS_TO_SOUND_PATH/"
var sounds := {
    # TODO: Load sounds here
    # Example: "Bullet": load(sounds_path + "Bullet.wav"),
}

onready var sound_players := get_children()


func play(sound_string : String, pitch_scale : float = 1, volume_db : float = 0):
    for player in sound_players:
        if not player.playing:
            player.pitch_scale = pitch_scale
            player.volume_db = volume_db
            player.stream = sounds[sound_string]
            player.play()
            return
    print("WARNING: Too many sounds playing at once!")
