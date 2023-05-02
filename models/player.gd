extends CharacterBody3D

var default_speed = 4
var default_noclip_speed = 10
var default_acceleration = 50
var default_jump_height = 0.6

var speed: float = default_speed # m/s
var acceleration: float = default_acceleration # m/s^2

var jump_height: float = default_jump_height  # m
var mouse_sens: float = 8

var vel: Vector3

var jumping: bool = false
var sprinting: bool = false
var noclip_sprinting: bool = false
var ducking: bool = false

var move_dir: Vector2 # Input direction for movement
var look_dir: Vector2 # Input direction for look/aim

var walk_vel: Vector3 # Walking velocity 
var grav_vel: Vector3 # Gravity velocity 
var jump_vel: Vector3 # Jumping velocity
var duck_vel: Vector3 # Ducking velocity

var duck_tween: Tween
var duck_timer: Timer

var footsteps_timer: SceneTreeTimer

@onready var camera: Camera3D = $Camera

func _ready() -> void:
	jumping = false
	sprinting = false
	noclip_sprinting = false
	ducking = false
	
	duck_tween = create_tween()

	pass

func _input(event: InputEvent) -> void:
	if !GameUI.visible:
		if event is InputEventMouseMotion: 
			look_dir = event.relative * 0.01
		if Input.is_action_just_pressed("jump"): 
			jumping = true
			
		var duck_position_y = position.y * 0.8
		if Input.is_action_pressed("duck") and !ducking:
			sprinting = false
	
			if self.position.y - duck_position_y <= duck_position_y: 
				create_tween().tween_property(self, "position:y", self.position.y - duck_position_y, 0.2)
				create_tween().tween_property(self, "speed", max(default_speed / 2, default_speed / 2), 0.2)
				ducking = true
				jump_height = jump_height * 0.75
		elif Input.is_action_just_released("duck") or !Input.is_action_pressed("duck") and ducking:
			ducking = false
			create_tween().tween_property(self, "position:y", min(self.position.y + duck_position_y, position.y), 0.1)
			create_tween().tween_property(self, "speed", default_speed, 0.1)
			jump_height = default_jump_height

func _footstep():
	if is_on_floor() and velocity != Vector3.ZERO and !footsteps_timer:
		var collided_with = self.get_last_slide_collision().get_collider() if self.get_last_slide_collision() else null

		if collided_with != null:
			var collider_material = "concrete"
			
			if collided_with.is_in_group("mat_concrete"):
				collider_material = "concrete"
				
			Sounds.play_sound(
				"res://resources/sounds/player/footsteps/%s%s.wav" % [collider_material, str(randi() % 3 + 1)],
			)
			footsteps_timer = get_tree().create_timer(1 - speed / 10)
			footsteps_timer.timeout.connect(func ():
				footsteps_timer = null
			)

func _physics_process(delta: float) -> void:	
	if !GameUI.visible and get_parent().get_node_or_null("/root/GameUILoading") and !get_parent().get_node_or_null("/root/GameUILoading").visible:		
		_rotate_camera(delta)
		
		var new_speed = speed
		
		# Turns off smooth delta animation
		if Globals.noclip and !Globals.noclip_delta:
			delta = 1
			
		if Globals.noclip:
			new_speed = default_noclip_speed
		
		if !Input.is_action_pressed("duck"):
			if Globals.noclip and Input.is_action_pressed("sprint") or !Globals.noclip and Input.is_action_just_pressed("sprint"):
				new_speed = new_speed * 2
				sprinting = true
				noclip_sprinting = Globals.noclip
			elif Input.is_action_just_released("sprint") or sprinting and !Input.is_action_pressed("sprint") or !Globals.noclip and noclip_sprinting:
				if noclip_sprinting and !Globals.noclip and Input.is_action_pressed("sprint"):
					new_speed = default_speed * 2
				else:
					new_speed = default_speed if !Globals.noclip else default_noclip_speed
					
				sprinting = new_speed == default_speed
				noclip_sprinting = Globals.noclip

		speed = new_speed
		
		velocity = _walk(delta) + _gravity(delta) + _jump(delta)
		
		move_and_slide()
		_footstep()

func _rotate_camera(delta: float, sens_mod: float = 1) -> void:
	look_dir += Input.get_vector("left", "right", "up", "down")

	# left + right
	camera.rotation.y -= look_dir.x * (mouse_sens * 8) * sens_mod * delta
	
	# up + down
	camera.rotation.x = clamp(camera.rotation.x - look_dir.y * (mouse_sens * 8) * sens_mod * delta, -1.57, 1.57)
	
	look_dir = Vector2.ZERO

func _sprint(state):
	print("sprinting")
	sprinting = !sprinting

func _walk(delta: float) -> Vector3:
	move_dir = Input.get_vector("moveleft", "moveright", "forward", "back")
	var _forward: Vector3 = camera.transform.basis * Vector3(move_dir.x, 0, move_dir.y)
	var walk_dir: Vector3
	
	if Globals.noclip:
		if Input.is_action_pressed("forward"):
			walk_dir += -camera.transform.basis.z
		elif Input.is_action_pressed("back"):
			walk_dir += camera.transform.basis.z
	
	walk_dir = Vector3(_forward.x, walk_dir.y, _forward.z).normalized()

	if jumping or is_on_wall():
		acceleration = max(acceleration * 3, 0)
	else:
		acceleration = default_acceleration

	if walk_dir != Vector3.ZERO and Input.get_last_mouse_velocity() != Vector2.ZERO and jumping:
		if Input.get_last_mouse_velocity().x < 0 and Input.get_last_mouse_velocity().x <= Globals.sv_flick_deceleration_velocity / -1:
			speed = max(default_speed * 2 if sprinting else default_speed, speed * 0.95 * delta)
			print("bhop: too harsh mouse flick velocity, slowing down...", Input.get_last_mouse_velocity().x)
		elif Input.get_last_mouse_velocity().x > 0 and Input.get_last_mouse_velocity().x >= Globals.sv_flick_deceleration_velocity:
			speed = max(default_speed * 2 if sprinting else default_speed, speed * 0.95 * delta)
			print("bhop: too harsh mouse flick velocity, slowing down...", Input.get_last_mouse_velocity().x)
		else:
			speed = default_speed

	walk_vel = walk_vel.move_toward(walk_dir * speed, acceleration * delta)
	return walk_vel

func _gravity(delta: float) -> Vector3:
	grav_vel = Vector3.ZERO if is_on_floor() or Globals.noclip else grav_vel.move_toward(Vector3(0, velocity.y - Globals.sv_gravity, 0), Globals.sv_gravity * delta)
	return grav_vel

func _jump(delta: float) -> Vector3:
	if Globals.noclip:
		return Vector3.ZERO
	
	if jumping:
		var collided_with = self.get_last_slide_collision().get_collider() if self.get_last_slide_collision() else null
		print(collided_with, is_on_wall(), is_on_floor())
			
		if is_on_floor(): 
			jump_vel = duck_vel + Vector3(0, sqrt(4 * jump_height * Globals.sv_gravity), 0)
		jumping = false
		return jump_vel
	jump_vel = jump_vel.move_toward(Vector3.ZERO, Globals.sv_gravity * delta)
	return jump_vel

func setpos(x, y, z):
	position = Vector3(x, y, z)
