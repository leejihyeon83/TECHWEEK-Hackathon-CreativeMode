extends Control

func _ready():
	# 'VBox'는 대문자 'V'로 시작하고, 'startBtn'은 소문자 's'로 시작합니다.
	# 씬 트리의 이름과 정확히 일치시켜야 합니다.
	$center/VBox/startBtn.pressed.connect(_on_start_pressed)

func _on_start_pressed():
	# 'click' 노드는 소문자로 시작합니다.
	$click.play()
	
	get_tree().change_scene_to_file("res://scenes/GameScene.tscn")
