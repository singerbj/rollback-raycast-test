extends StaticBody

const Bomb = preload("res://scenes/Bomb.tscn")

var input_prefix := "player1_"

var speed := 0.0
var last_input_vector := Vector3.ZERO
var is_offline_master := false
var health := 100
var head_angle : float

const MAX_HEALTH := 100
const SHOT_DISTANCE := 1000
const SENS_MULTIPLIER := 0.03
const MAX_SPEED := 0.1 * 2
const ACCELERATION_SPEED := 0.01
const FLOATING_TOLERANCE := 0.00000000001

var total_mouse_motion := Vector2(0, 0)
#var total_mouse_motion := Vector2(0, 0)
#var network_rotation_degrees := Vector3()
#var head_angle := 0.0

onready var lines := []

func _get_local_input() -> Dictionary:
	var input := {}
	if is_master():
		var input_vector = Input.get_vector(input_prefix + "left", input_prefix + "right", input_prefix + "up", input_prefix + "down")
		if input_vector != Vector2.ZERO:
			input["input_vector"] = input_vector
#		if Input.is_action_pressed("firing"):
#			var angle = get_tree().get_root().get_angle_to(get_tree().get_root().get_global_mouse_position())
#			var shot_destination = Vector2()
#			shot_destination.x = position.x + (SHOT_DISTANCE * cos(angle)) 
#			shot_destination.y = position.y + (SHOT_DISTANCE * sin(angle))
#			input["firing"] = shot_destination
		if Input.is_action_just_pressed(input_prefix + "bomb"):
			input["drop_bomb"] = true
		
		input["mouse_motion"] = total_mouse_motion
		total_mouse_motion = Vector2(0, 0)
	
	return input

func _predict_remote_input(previous_input: Dictionary, ticks_since_real_input: int) -> Dictionary:
	var input = previous_input.duplicate()
	input.erase("drop_bomb")
	return input

func _network_process(input: Dictionary) -> void:
	var mouse_motion = input.get("mouse_motion", Vector2.ZERO);
	# Rotate body
	rotation_degrees.y -= SENS_MULTIPLIER * mouse_motion.x
	# Rotate head
	head_angle -= SENS_MULTIPLIER * mouse_motion.y
	head_angle = clamp(head_angle, -80, 80)
	
	$Camera.rotation_degrees.x = head_angle
#	rotation_degrees = network_rotation_degrees
		
	var input_vector = input.get("input_vector", Vector2.ZERO)
	var converted_input_vector = Vector3(input_vector.x, 0, input_vector.y).rotated(Vector3.UP, transform.basis.get_euler().y)
	if input_vector != Vector2.ZERO:
		if speed < MAX_SPEED:
			if speed + ACCELERATION_SPEED <=  MAX_SPEED:
				speed += ACCELERATION_SPEED
			else:
				speed =  MAX_SPEED
		transform.origin += converted_input_vector * speed
		last_input_vector = converted_input_vector
	else:
		if speed > 0.0:
			if speed - ACCELERATION_SPEED >= 0.0:
				speed -= ACCELERATION_SPEED
			else:
				speed = 0.0
			
		transform.origin += last_input_vector * speed
	
	if input.get("drop_bomb", false):
		SyncManager.spawn("Bomb", get_parent(), Bomb, { position = transform.origin })
	
#	var shot_location = input.get("firing", false)
#	if shot_location:
#		var space_state = get_world().direct_space_state
#		var result = space_state.intersect_ray(global_position, shot_location, [self])
#		if result.get("collider", false):
#			result.collider.health -= 1
#		if !SyncManager.is_in_rollback():
#			_draw_line(result.get("position", false), OS.get_system_time_msecs())
	
#func _fix_floating_point():
#	# Fix the floating point math - or try
#	rotation_degrees.x = stepify(rotation_degrees.x, 0.001)
#	rotation_degrees.y = stepify(rotation_degrees.y, 0.001)
#	rotation_degrees.z = stepify(rotation_degrees.z, 0.001)
#	last_input_vector.x = stepify(last_input_vector.x, 0.001)
#	last_input_vector.y = stepify(last_input_vector.y, 0.001)
#	last_input_vector.z = stepify(last_input_vector.z, 0.001)
#	transform.origin.x = stepify(transform.origin.x, 0.001)
#	transform.origin.y = stepify(transform.origin.y, 0.001)
#	transform.origin.z = stepify(transform.origin.z, 0.001)
#	speed = stepify(speed, 0.001)

func stepify_vector3(v):
	if v != null:
		v.x = stepify(v.x, FLOATING_TOLERANCE)
		v.y = stepify(v.y, FLOATING_TOLERANCE)
		v.z = stepify(v.z, FLOATING_TOLERANCE)
	return v
	
func stepify_number(n):
	if n != null:
		n = stepify(n, FLOATING_TOLERANCE)
	return n

func _save_state() -> Dictionary:
#	return {
#		position = stepify_vector3(transform.origin),
#		speed = stepify_number(speed),
#		last_input_vector = stepify_vector3(last_input_vector),
#		health = stepify_number(health),
#		rotation_degrees = stepify_vector3(rotation_degrees),
#		head_angle = stepify_number(head_angle)
#	}
	return {
		position = transform.origin,
		speed = speed,
		last_input_vector = last_input_vector,
		health = health,
		rotation_degrees = rotation_degrees,
		head_angle = head_angle
	}

func _load_state(state: Dictionary) -> void:
#	transform.origin = stepify_vector3(state['position'])
#	speed = stepify_number(state['speed'])
#	last_input_vector = stepify_vector3(state['last_input_vector'])
#	health = stepify_number(state['health'])
#	rotation_degrees = stepify_vector3(state['rotation_degrees'])
#	head_angle = stepify_number(state['head_angle'])

	transform.origin = state['position']
	speed = state['speed']
	last_input_vector = state['last_input_vector']
	health =state['health']
	rotation_degrees = state['rotation_degrees']
	head_angle = state['head_angle']

func _interpolate_state(old_state: Dictionary, new_state: Dictionary, weight: float) -> void:
	transform.origin = stepify_vector3(lerp(old_state['position'], new_state['position'], weight))
	
func _input(event) -> void:
	if event is InputEventMouseMotion && Input.get_mouse_mode() != Input.MOUSE_MODE_VISIBLE:
		total_mouse_motion += event.relative
#		network_total_mouse_motion += event.relative

func _process(delta):
	if is_master():
#		# Rotate body
#		rotation_degrees.y -= SENS_MULTIPLIER * total_mouse_motion.x
#		# Rotate head
#		head_angle -= SENS_MULTIPLIER * total_mouse_motion.y
#		head_angle = clamp(head_angle, -80, 80)
#		$Camera.rotation_degrees.x = head_angle
#		# Reset total_mouse_motion
#		total_mouse_motion = Vector2(0, 0)
		
		$Camera.current = true
		get_parent().active_camera = $Camera
		
	var new_lines = []
	for line in lines:
		if OS.get_system_time_msecs() - line[1] < 50:
			line.queue_free()
		else:
			new_lines.append(line)
	lines = new_lines
	
	if health > 0:
		$HealthBar.value = health
	else:
		$HealthBar.value = 0
		
	var pos = get_translation()
	var screen_pos
	if get_parent().active_camera:
		screen_pos = get_parent().active_camera.unproject_position(pos)
	else:
		screen_pos = $Camera.unproject_position(pos)
	$HealthBar.set_position(Vector2(screen_pos.x - ($HealthBar.get_rect().size.x / 2), screen_pos.y - 50))
	
	
func _draw_line(hit_location, time):
#	for line in lines:
#		if !line[2]:
#			draw_line(line[0] - position, line[1] - position, Color(255, 255, 255), 1)
#		else:
#			draw_line(line[0] - position, line[2] - position, Color(255, 0, 0), 1)
#			draw_circle(line[2] - position, 10, Color(255, 0, 0))

	var from = $Camera.project_ray_origin(get_viewport().get_mouse_position())
	var to = from + $Camera.project_ray_normal(get_viewport().get_mouse_position()) * 1000

	var color = Color(0.5, 0.5, 0.5)

	var line = ImmediateGeometry.new()
	var mat = SpatialMaterial.new()
	mat.flags_unshaded = true
	mat.vertex_color_use_as_albedo = true
	line.material_override = mat

	get_node('/root').add_child(line)
	line.clear()
	line.begin(Mesh.PRIMITIVE_LINE_STRIP)
	line.set_color(color)
	line.add_vertex(from)
	line.add_vertex(to)
	line.end()
	
	lines.append([line, time])	
	
func is_master():
	return is_offline_master || (get_tree().network_peer != null && is_network_master())
