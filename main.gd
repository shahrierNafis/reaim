extends Node3D

var target_scene: PackedScene = preload("res://scenes/target.tscn")
@export var wall_z: float = -5.0
@export var target_count: int = 5
@export var grid_rows: int = 5
@export var grid_cols: int = 5
@export var spacing: float = .3
@export var apert: int = 3
var positions: Array[Vector3] = []

func _ready():
	initPositions()
	# Shuffle and pick random target positions
	positions.shuffle()
	spawn_targets()
	connect("target_hit", onTargetHit)

func onTargetHit():
	print("d")

	# Collect all grid positions
func initPositions():
	for row in range(grid_rows):
		for col in range(grid_cols):
			var x =  + col * spacing * apert
			var y = 1 + row * spacing * apert
			positions.append(Vector3(x, y, wall_z))
func spawn_targets():
	var target_positions = positions.slice(0, target_count)
	# Place actual targets
	for pos in target_positions:
		var target = target_scene.instantiate()
		target.position = pos
		add_child(target)
