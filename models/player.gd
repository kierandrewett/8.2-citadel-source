extends CharacterBody3D

var speed: float = 3 # m/s
var acceleration: float = 80 # m/s^2
var deceleration: float = 10
var jump_acceleration: float = 500
var jump_deceleration: float = 1

var max_angle_steepness: float = 20

var jump_height: float = 0.5 # m
var mouse_sens: float = Globals.sensitivity * 3

var jumping: bool = false
var mouse_captured: bool = false
var current_accel: float = 0
var initial_used_aux_action = ""
var jumped_since_footstep = false

var gravity: float = Globals.sv_gravity

# Directions
var move_dir: Vector2 # Input direction for movement
var look_dir: Vector2 # Input direction for look/aim
var walk_dir: Vector3
var slide_dir: Vector3

# Velocity
var walk_vel: Vector3 # Walking velocity 
var grav_vel: Vector3 # Gravity velocity 
var jump_vel: Vector3 # Jumping velocity

# Timers
var footsteps_timer: SceneTreeTimer

# Damage
var took_fall_damage = false
var fall_damage_multiplier = 12

# Stats
var player_health = 100
var suit_health = 0
var player_dead = false
var can_respawn_yet = false

@onready var camera: Camera3D = $Camera

@onready var player_health_ui: HBoxContainer = Utils.get_node_by_name(get_tree().root, "HealthContainer")
@onready var suit_health_ui: HBoxContainer = Utils.get_node_by_name(get_tree().root, "SuitContainer")

var player_health_label: Label
var suit_health_label: Label

func _ready() -> void:
	camera.rotation = Vector3.ZERO
	
	player_health_label = player_health_ui.get_node("MarginContainer/MarginContainer/HealthBox/ValueContainer/Container/Amount")
	suit_health_label = suit_health_ui.get_node("MarginContainer/MarginContainer/SuitBox/ValueContainer/Container/Amount")
	
	capture_mouse()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion: 
		look_dir = event.relative * 0.001
	if Input.is_action_just_pressed("jump") and !jumping:
		jumping = true
	
	if player_dead and can_respawn_yet and !GameUI.visible:
		if Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("alt") or Input.is_action_just_pressed("gameui_menu") or Input.is_action_just_pressed("jump"):
			respawn_player()

func _physics_process(delta: float) -> void:
	if GameUI.visible or get_node("/root/GameUILoading").visible:
		return
		
	gravity = Globals.sv_gravity

	if camera:
		camera.fov = Globals.fov
	
	player_health_label.text = str(player_health)
	suit_health_label.text = str(suit_health)
	
	player_health_ui.visible = player_health > 0
	suit_health_ui.visible = suit_health > 0
	
	if player_health <= 0 and !player_dead:
		player_dead = true
		
		# Hide the whole map
		Maps.current_scene.visible = false
		
		# Hide the GUI
		get_node("/root/GameUIGUI").visible = false
		
		# Dump the death screen to root
		var death_screen = Maps.dump_map_to_root("res://ui/gameui_death.tscn")
		
		# Make death screen black for a moment
		death_screen.modulate = Color.BLACK
		
		get_tree().create_timer(0.01).timeout.connect(func ():
			# Make the death screen red with a slight opacity
			death_screen.modulate = Color(248, 0, 0, 0.25)
			
			Sounds.play_sound("res://resources/sounds/player/flatline.wav", get_tree().root, Globals.volume / 3, randf_range(0.95, 1))
			
			get_tree().create_timer(2).timeout.connect(func ():
				can_respawn_yet = true
			)
			
			create_tween().tween_property(death_screen, "modulate", Color.WHITE, 0.05)	
		)
		
		return
	
	if mouse_captured: 
		_rotate_camera(delta)
	
	# Block us from moving when dead
	if player_dead:
		return

	velocity = _walk(delta) + _gravity(delta) + _jump(delta)
	
	move_and_slide()
	print("slide_dir ", slide_dir.x, get_last_motion().x)
	slide_dir = get_last_motion()

func capture_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true

func release_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false

func _rotate_camera(delta: float, sens_mod: float = 50.0) -> void:
	look_dir += Input.get_vector("left", "right", "up", "down")
	camera.rotation.y -= look_dir.x * mouse_sens * sens_mod * delta
	camera.rotation.x = clamp(camera.rotation.x - look_dir.y * mouse_sens * sens_mod * delta, -1.567, 1.567)
	look_dir = Vector2.ZERO

func get_auxiliary_action():
	if Input.is_action_pressed("moveleft"):
		return "moveleft"
	elif Input.is_action_pressed("moveright"):
		return "moveright"
	elif Input.is_action_pressed("forward"):
		return "forward"
	elif Input.is_action_pressed("back"):
		return "back"
		
	return ""

func get_decelerate_speed() -> float:
	# If we are decelerating after a jump, the deceleration should be lower
	if jump_vel.length():
		return jump_deceleration
	else:
		return deceleration

func _walk(delta: float) -> Vector3:
	if is_on_floor():
		initial_used_aux_action = get_auxiliary_action()
	
	move_dir = Input.get_vector(
		"moveleft", 
		"moveright", 
		"forward", 
		"back"
	)
	
	var _forward: Vector3 = camera.transform.basis * Vector3(move_dir.x, 0, move_dir.y)
	walk_dir = Vector3(_forward.x, 0, _forward.z).normalized()
	current_accel = 0
	
	print("!!!!!!!!!!! ", look_dir.length())
	
	var resultant_vector = walk_dir * speed * move_dir.length()
	
	if move_dir.length():
		if jump_vel.length():
			current_accel = jump_acceleration / speed
		else:
			current_accel = acceleration / speed
		
		if !is_on_floor():
			if initial_used_aux_action != get_auxiliary_action():
				current_accel = 0
				
		_footstep(false)
				
		walk_vel = walk_vel.move_toward(resultant_vector, current_accel * delta)
	else:
		# If we are decelerating after a jump, the deceleration should be lower
		current_accel = get_decelerate_speed()
		
		walk_vel = walk_vel.move_toward(resultant_vector, current_accel * delta)

	return walk_vel 

func _gravity(delta: float) -> Vector3:
	grav_vel = Vector3.ZERO if is_on_floor() or Globals.noclip else grav_vel.move_toward(Vector3(0, velocity.y - gravity, 0), gravity * delta)
	
	print("GRAVITY !!!!!!!", grav_vel.length(), is_on_floor())

	if grav_vel.length() > 8 and !took_fall_damage:
		took_fall_damage = true
		event_falldamage(grav_vel.length())
	
	return grav_vel

func _jump(delta: float) -> Vector3:
	# Just started jumping
	if jumping:
		# Still on the floor as we haven't moved up yet
		if is_on_floor(): 
			_footstep(true)
			
			jump_vel = Vector3(0, sqrt(4 * jump_height * gravity), 0)
		jumping = false
		jumped_since_footstep = true
		return jump_vel
	jump_vel = Vector3.ZERO if is_on_floor() else jump_vel.move_toward(Vector3.ZERO, gravity * delta)
	return jump_vel

func _footstep(is_jumping_state):
	if !is_jumping_state:
		# If we aren't on the floor, return
		if !is_on_floor():
			return
			
		# If we're on a wall, return
		if is_on_wall():
			return
			
		# If we aren't moving, return
		if velocity.length() < 0:
			return
		
		# If a footstep is already queued, return
		if footsteps_timer:
			return
			
	var collided_with = self.get_last_slide_collision().get_collider() if self.get_last_slide_collision() else null

	if collided_with != null:
		var collider_material = "concrete"

		if collided_with.is_in_group("mat_concrete"):
			collider_material = "concrete"

		Sounds.play_sound(
			"res://resources/sounds/player/footsteps/%s%s.wav" % [collider_material, str(randi() % 3 + 1)],
		)
		
		if !is_jumping_state:
			footsteps_timer = get_tree().create_timer(1 - velocity.length() / 10)
			footsteps_timer.timeout.connect(func ():
				footsteps_timer = null
			)

func respawn_player():
	Maps.load_map(Maps.current_name)
	if get_node_or_null("/root/GameUIDeath"): 
		get_node("/root/GameUIDeath").queue_free()

func take_damage(amount: int, type_of_damage):
	var health_minimum = 0
	
	# Don't take any damage in god mode
	if Globals.god:
		return
		
	if Globals.buddha:
		health_minimum = 1
	
	var player_health_taken = clamp(player_health - amount if suit_health % 5 == 0 else player_health - 0, 0, 100)
	var suit_health_taken = clamp(suit_health - amount, 0, 100)
	
	player_health = player_health_taken
	suit_health = suit_health_taken
		
	if type_of_damage == "fall":
		pass

func event_falldamage(falling_speed = 0):
	while true:
		await get_tree().process_frame
		
		if is_on_floor():
			took_fall_damage = false
			var health_taken = clamp(floor(falling_speed), 0, 100)
			print(health_taken)
			
			if health_taken > 1:
				Sounds.play_sound("res://resources/sounds/player/fallpain%s.wav" % [randi() % 2 + 1])
				create_tween().tween_property(camera, "rotation_degrees:z", camera.rotation_degrees.z + 8, 0.05).finished.connect(func ():
					create_tween().tween_property(camera, "rotation_degrees:z", camera.rotation_degrees.z - 8, 0.1)
				)
				
				player_health -= health_taken
			
			break

func setpos(x, y, z):
	position = Vector3(x, y, z)
