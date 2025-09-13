extends Node3D

var target_scene: PackedScene = preload("res://scenes/target.tscn")
var empty_target_scene: PackedScene = preload("res://scenes/empty_target.tscn")

@export var wall_z: float = -5.0
@export var target_count: int = 10
@export var grid_rows: int = 2
@export var grid_cols: int = 15
@export var spacing: float = .3
@export var apart: int = 3
@export var time: int = 5

var positions: Array[Vector3] = []
var timer := Timer.new()

var targets_destroyed: int = 0
var total_score: float = 0.0

@onready var timer_label: Label = $CanvasLayer/TimerLabel
@onready var status_label: Label = $CanvasLayer/StatusLabel
@onready var score_label: Label = $CanvasLayer/ScoreLabel

func _ready():
	_load_score()
	_update_score_label()

	initPositions()
	positions.shuffle()
	spawn_targets()

	timer.wait_time = time
	timer.one_shot = true
	timer.timeout.connect(_on_timeout)
	add_child(timer)

	$player.connect("target_hit", onTargetHit)

func _process(delta: float) -> void:
	if timer.is_stopped():
		timer_label.text = ""
	else:
		timer_label.text = str(round(timer.time_left))

func onTargetHit():
	targets_destroyed += 1

	var targets = get_tree().get_nodes_in_group("target")
	print(targets.size())

	if targets.size() == target_count:
		status_label.text = ""
		timer.start()

	if targets.size() == 1:
		# All targets destroyed -> success
		print("All targets hit! Respawning...")
		_calc_score(true)
		status_label.text = "Success!"
		status_label.add_theme_color_override("font_color", Color.GREEN)
		positions.shuffle()
		spawn_targets()
		targets_destroyed = 0

func _on_timeout():
	# Timer ran out -> failure
	print("Timeout! Failure.")
	spawn_targets()
	_calc_score(false)
	status_label.text = "Failure!"
	status_label.add_theme_color_override("font_color", Color.RED)
	targets_destroyed = 0

func _calc_score(success: bool):
	if targets_destroyed == 0:
		return
	var base = (grid_cols * grid_rows * apart * targets_destroyed / spacing)
	var exponent = float(targets_destroyed) / float(time)
	var score = pow(base, exponent)

	total_score += score
	_save_score()
	_update_score_label()

	print("Round Score:", score, " | Total Score:", total_score)

func _save_score():
	var file = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	if file:
		file.store_line(str(total_score))
		file.close()

func _load_score():
	if FileAccess.file_exists("user://savegame.save"):
		var file = FileAccess.open("user://savegame.save", FileAccess.READ)
		if file:
			total_score = float(file.get_line())
			file.close()

func _update_score_label():
	score_label.text = "Score: " + str(round(total_score))

# Collect all grid positions
func initPositions():
	positions.clear()
	for row in range(grid_rows):
		for col in range(grid_cols):
			var x = (col - (grid_cols - 1) / 2.0) * spacing * apart
			var y = 2.5 + (row - (grid_rows - 1) / 2.0) * spacing * apart
			positions.append(Vector3(x, y, wall_z))

func spawn_targets():
	clear_targets()

	var target_positions = positions.slice(0, target_count)
	var empty_positions = positions.slice(target_count)

	for pos in target_positions:
		var target = target_scene.instantiate()
		target.position = pos
		add_child(target)

	for pos in empty_positions:
		var empty_target = empty_target_scene.instantiate()
		empty_target.position = pos
		add_child(empty_target)

func clear_targets():
	for target in get_tree().get_nodes_in_group("target"):
		target.queue_free()
	for empty_target in get_tree().get_nodes_in_group("empty_target"):
		empty_target.queue_free()
