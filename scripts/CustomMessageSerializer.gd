extends "res://addons/godot-rollback-netcode/MessageSerializer.gd"

const input_path_mapping := {
	'/root/Main/ServerPlayer': 1,
	'/root/Main/ClientPlayer': 2,
}

enum HeaderFlags {
	HAS_INPUT_VECTOR = 1 << 0, # Bit 0
	HAS_MOUSE_MOTION = 1 << 1, # Bit 1
	HAS_FIRING =       1 << 2, # Bit 2
	DROP_BOMB =        1 << 3, # Bit 3
}

var input_path_mapping_reverse := {}

func _init() -> void:
	for key in input_path_mapping:
		input_path_mapping_reverse[input_path_mapping[key]] = key

func serialize_input(all_input: Dictionary) -> PoolByteArray:
	var buffer := StreamPeerBuffer.new()
	buffer.resize(16)
	
	buffer.put_u32(all_input['$'])
	buffer.put_u8(all_input.size() - 1)
	for path in all_input:
		if path == '$':
			continue
		buffer.put_u8(input_path_mapping[path])
		
		var header := 0
		
		var input = all_input[path]
		if input.has('input_vector'):
			header |= HeaderFlags.HAS_INPUT_VECTOR
		if input.has('mouse_motion'):
			header |= HeaderFlags.HAS_MOUSE_MOTION
		if input.has('firing'):
			header |= HeaderFlags.HAS_FIRING
		if input.get('drop_bomb', false):
			header |= HeaderFlags.DROP_BOMB
		
		buffer.put_u8(header)
		
		if input.has('input_vector'):
			var input_vector: Vector2 = input['input_vector']
			buffer.put_float(input_vector.x)
			buffer.put_float(input_vector.y)
		
		if input.has('mouse_motion'):
			var mouse_motion_vector: Vector2 = input['mouse_motion']
			buffer.put_float(mouse_motion_vector.x)
			buffer.put_float(mouse_motion_vector.y)
			
		if input.has('firing'):
			var shot_location: Vector3 = input['firing']
			buffer.put_float(shot_location.x)
			buffer.put_float(shot_location.y)
			buffer.put_float(shot_location.z)
	
	buffer.resize(buffer.get_position())
	return buffer.data_array

func unserialize_input(serialized: PoolByteArray) -> Dictionary:
	var buffer := StreamPeerBuffer.new()
	buffer.put_data(serialized)
	buffer.seek(0)
	
	var all_input := {}
	
	all_input['$'] = buffer.get_u32()
	
	var input_count = buffer.get_u8()
	if input_count == 0:
		return all_input
	
	var path = input_path_mapping_reverse[buffer.get_u8()]
	var input := {}
	
	var header = buffer.get_u8()
	if header & HeaderFlags.HAS_INPUT_VECTOR:
		input["input_vector"] = Vector2(buffer.get_float(), buffer.get_float())
	if header & HeaderFlags.HAS_MOUSE_MOTION:
		input["mouse_motion"] = Vector2(buffer.get_float(), buffer.get_float())
	if header & HeaderFlags.HAS_FIRING:
		input["firing"] = Vector3(buffer.get_float(), buffer.get_float(), buffer.get_float())
	if header & HeaderFlags.DROP_BOMB:
		input["drop_bomb"] = true
	
	all_input[path] = input
	return all_input
