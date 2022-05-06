extends StaticBody2D

const Bomb = preload("res://scenes/Bomb.tscn")

var input_prefix := "player1_"

var speed := 0.0
var last_input_vector = Vector2.ZERO
var is_offline_master = false
var health = 100
const MAX_HEALTH = 100
const SHOT_DISTANCE = 1000

onready var lines = []

func _get_local_input() -> Dictionary:
	var input := {}
	if is_network_master() || is_offline_master:
		var input_vector = Input.get_vector(input_prefix + "left", input_prefix + "right", input_prefix + "up", input_prefix + "down")
		if input_vector != Vector2.ZERO:
			input["input_vector"] = input_vector
		if Input.is_action_pressed("firing"):
			var angle = get_angle_to(get_global_mouse_position())
			var shot_destination = Vector2()
			shot_destination.x = position.x + (SHOT_DISTANCE * cos(angle))
			shot_destination.y = position.y + (SHOT_DISTANCE * sin(angle))
			input["firing"] = shot_destination
		if Input.is_action_just_pressed(input_prefix + "bomb"):
			input["drop_bomb"] = true
	
	return input

func _predict_remote_input(previous_input: Dictionary, ticks_since_real_input: int) -> Dictionary:
	var input = previous_input.duplicate()
	input.erase("drop_bomb")
	return input

func _network_process(input: Dictionary) -> void:
	var input_vector = input.get("input_vector", Vector2.ZERO)
	if input_vector != Vector2.ZERO:
		if speed < 16.0:
			if speed + 1.0 <= 16.0:
				speed += 1.0
			else:
				speed = 16.0
		position += input_vector * speed
		last_input_vector = input_vector
	else:
		if speed > 0.0:
			if speed - 4.0 >= 0.0:
				speed -= 4.0
			else:
				speed = 0.0
			
		position += last_input_vector * speed
	
	if input.get("drop_bomb", false):
		SyncManager.spawn("Bomb", get_parent(), Bomb, { position = global_position })
	
	var shot_location = input.get("firing", false)
	if shot_location:
		var space_state = get_world_2d().direct_space_state
		var result = space_state.intersect_ray(global_position, shot_location, [self])
		if result.get("collider", false):
			result.collider.health -= 1
		if !SyncManager.is_in_rollback():
			lines.append([global_position, shot_location, result.get("position", false), OS.get_system_time_msecs()])

func _save_state() -> Dictionary:
	return {
		position = position,
		speed = speed,
		last_input_vector = last_input_vector,
		health = health,
	}

func _load_state(state: Dictionary) -> void:
	position = state['position']
	speed = state['speed']
	last_input_vector = state['last_input_vector']
	health = state['health']

func _interpolate_state(old_state: Dictionary, new_state: Dictionary, weight: float) -> void:
	position = lerp(old_state['position'], new_state['position'], weight)
	
func _process(delta):
	update()
	
	var new_lines = []
	for line in lines:
		if OS.get_system_time_msecs() - line[3] < 50:
			new_lines.append(line)
	lines = new_lines
	
	if health > 0:
		$HealthBar.value = health
	else:
		$HealthBar.value = 0
	
	
func _draw():
	for line in lines:
		if !line[2]:
			draw_line(line[0] - position, line[1] - position, Color(255, 255, 255), 1)
		else:
			draw_line(line[0] - position, line[2] - position, Color(255, 0, 0), 1)
			draw_circle(line[2] - position, 10, Color(255, 0, 0))
			
