extends Node3D

var target_scene: PackedScene = preload("res://scenes/target.tscn")
var empty_target_scene: PackedScene = preload("res://scenes/empty_target.tscn")

@export var radius: float = 5
@export var angle_x: float = 90  # horizontal arc in degrees
@export var angle_y: float = 45   # vertical arc in degrees
@export var spacing: float = 0.3

@export var target_count: int = 2
@export var time: int = 5

var positions: Array[Vector3] = []
var timer := Timer.new()
var start_time: float = 0.0

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
	add_child(timer)

	$player.connect("target_hit", onTargetHit)

func _process(delta: float) -> void:
	if timer.is_stopped():
		timer_label.text = ""
	else:
		timer_label.text = str(int(round(timer.time_left)))

func onTargetHit():
	targets_destroyed += 1

	var targets = get_tree().get_nodes_in_group("target")
	print(targets.size())

	if targets.size() == target_count:
		status_label.text = ""
		timer.start()
		start_time = Time.get_ticks_msec() / 1000.0  # store start in seconds


	if targets.size() == 1:
		# All targets destroyed -> success
		print("All targets hit! Respawning...")
		status_label.text = _calc_score()
		if (timer.time_left==0):
				status_label.add_theme_color_override("font_color", Color.ORANGE)
		else:		
			status_label.add_theme_color_override("font_color", Color.GREEN)
			positions.shuffle()
		spawn_targets()
		timer.stop()
		targets_destroyed = 0

func _calc_score():
	if targets_destroyed == 0:
		return
	var target_positions = positions.slice(0, target_count)
	
	var base = 0.0
	for i in range(target_positions.size() - 1):
		base += target_positions[i].distance_to(target_positions[i + 1])
		
	var elapsed_time=float((Time.get_ticks_msec() / 1000.0) - start_time)
	var exponent = float(targets_destroyed) / elapsed_time
	var score = pow(base, exponent)

	total_score += score
	_save_score()
	_update_score_label()

	print("Round Score:", score, " | Total Score:", total_score)
	return "{0}^{1} = {2}".format([round_to_dec(base),round_to_dec(exponent),round_to_dec(score)])
	
func round_to_dec(num, digit=2):
	return round(num * pow(10.0, digit)) / pow(10.0, digit)

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
	score_label.text = "Score: " + str(round_to_dec(total_score))

func initPositions():
	positions.clear()
	
	# Convert angles to radians
	var angle_x_rad = deg_to_rad(angle_x)
	var angle_y_rad = deg_to_rad(angle_y)
	
	# Calculate vertical angular step
	var step_y = spacing / radius
	var steps_y = int(angle_y_rad / step_y) + 1
	
	for iy in range(steps_y):
		# Vertical angle: from -angle_y/2 to +angle_y/2
		var phi = (iy / float(steps_y - 1) - 0.5) * angle_y_rad
		
		# Calculate horizontal step adjusted for this latitude
		# At higher latitudes (near poles), cos(phi) gets smaller, 
		# so we need fewer horizontal points to maintain spacing
		var cos_phi = cos(phi)
		
		# Skip points too close to poles to avoid coordinate issues
		if abs(cos_phi) < 0.05:
			continue
		
		var step_x_adjusted = step_y / cos_phi  # adjust horizontal step for latitude
		var steps_x = max(1, int(angle_x_rad / step_x_adjusted) + 1)
		
		# For 360° horizontal coverage, exclude the last point to avoid overlap
		var actual_steps_x = steps_x
		if abs(angle_x - 360.0) < 0.001:  # Check if it's essentially 360°
			actual_steps_x = steps_x - 1
		
		for ix in range(actual_steps_x):
			var theta: float
			if actual_steps_x == 1:
				# Single point on this latitude ring - place at center
				theta = 0.0
			elif abs(angle_x - 360.0) < 0.001:
				# Full 360° circle: distribute evenly from 0 to 360° (excluding 360°)
				theta = (ix / float(actual_steps_x)) * angle_x_rad - PI
			else:
				# Partial arc: from -angle_x/2 to +angle_x/2
				theta = (ix / float(actual_steps_x - 1) - 0.5) * angle_x_rad
			
			# Spherical to Cartesian conversion
			var x = radius * cos_phi * sin(theta)
			var y = radius * sin(phi) + 1
			var z = -radius * cos_phi * cos(theta)
			
			positions.append(Vector3(x, y, z))

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
