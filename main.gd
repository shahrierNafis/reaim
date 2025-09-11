extends Node3D

var target_scene: PackedScene = preload("res://scenes/target.tscn")
var empty_target_scene: PackedScene = preload("res://scenes/empty_target.tscn")

@export var wall_z: float = -5.0
@export var target_count: int = 5
@export var grid_rows: int = 5
@export var grid_cols: int = 5
@export var spacing: float = .3
@export var apart: int = 3
var positions: Array[Vector3] = []

func _ready():
	initPositions()
	# Shuffle and pick random target positions
	positions.shuffle()
	spawn_targets()
	$player.connect("target_hit", onTargetHit)

func onTargetHit():
	var targets = get_tree().get_nodes_in_group("target")
	print(targets.size())
	if targets.size() == 1:
		print("All targets hit! Respawning...")
		positions.shuffle()
		spawn_targets()

# Collect all grid positions
func initPositions():
	positions.clear()  # FIX: Clear existing positions first!
	
	for row in range(grid_rows):
		for col in range(grid_cols):
			var x = (col - (grid_cols - 1) / 2.0) * spacing * apart
			var y = 2.5 + (row - (grid_rows - 1) / 2.0) * spacing * apart
			positions.append(Vector3(x, y, wall_z))
func spawn_targets():
	# Clear existing targets first
	clear_targets()
	# Split positions into target and empty target sets
	var target_positions = positions.slice(0, target_count)
	var empty_positions = positions.slice(target_count)
	
	# Place actual targets
	for pos in target_positions:
		var target = target_scene.instantiate()
		target.position = pos
		add_child(target)
	
	# Place empty targets
	for pos in empty_positions:
		var empty_target = empty_target_scene.instantiate()
		empty_target.position = pos
		add_child(empty_target)

func clear_targets():
	# Remove all existing targets
	var targets = get_tree().get_nodes_in_group("target")
	var empty_targets = get_tree().get_nodes_in_group("empty_target")
	
	for target in targets:
		target.queue_free()
	for empty_target in empty_targets:
		empty_target.queue_free()
