extends Node

var sounds_path = "res://SoundFX/sounds/"
var sounds := {}


func _ready():
    load_sound_fx()


func load_sound_fx():
    if len(sounds.keys()) != 0:
        return

    var dir := Directory.new()

    # warning-ignore:return_value_discarded
    dir.open(sounds_path)
    # warning-ignore:return_value_discarded
    dir.list_dir_begin(true, true)

    var check = dir.get_next()
    while check != "":
        var full_path = sounds_path + check
        if check.ends_with(".ogg") or check.ends_with(".wav") or check.ends_with(".mp3"):
            var fx_name: String = check.split(".", false, 1)[0]
            print("Found Sound effect: ", check)
            print("Access by name: ", fx_name)
            sounds[fx_name] = load(full_path)
        check = dir.get_next()


func play(sound_string : String, pitch_scale : float = 1, volume_db : float = 0):
        var player: AudioStreamPlayer = AudioStreamPlayer.new()
        player.pitch_scale = pitch_scale
        player.volume_db = volume_db
        player.stream = sounds[sound_string]
        player.bus = "SoundFX"
        var main := get_tree().current_scene
        main.add_child(player)
        player.play()
