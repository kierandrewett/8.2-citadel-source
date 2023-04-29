extends CharacterBody3D

var default_speed = 5
var default_noclip_speed = 10

var speed: float = default_speed # m/s
var acceleration: float = 40 # m/s^2

var jump_height: float = 0.5  # m
var mouse_sens: float = 3

var vel: Vector3

var jumping: bool = false
var sprinting: bool = false
var noclip_sprinting: bool = false

var move_dir: Vector2 # Input direction for movement
var look_dir: Vector2 # Input direction for look/aim

var walk_vel: Vector3 # Walking velocity 
var grav_vel: Vector3 # Gravity velocity 
var jump_vel: Vector3 # Jumping velocity

@onready var camera: Camera3D = $Camera

func _ready() -> void:
	pass

func _input(event: InputEvent) -> void:
	if !GameUI.visible:
		if event is InputEventMouseMotion: 
			look_dir = event.relative * 0.01
		if Input.is_action_just_pressed("jump"): 
			jumping = true

func _physics_process(delta: float) -> void:	
	if !GameUI.visible:		
		_rotate_camera(delta)
		
		var new_speed = speed
		
		# Turns off smooth delta animation
		if Globals.noclip and !Globals.noclip_delta:
			delta = 1
			
		if Globals.noclip:
			new_speed = default_noclip_speed
		
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

func _rotate_camera(delta: float, sens_mod: float = 1.0) -> void:
	look_dir += Input.get_vector("left", "right", "up", "down")
	camera.rotation.y -= look_dir.x * (mouse_sens * 8) * sens_mod * delta
	camera.rotation.x = clamp(camera.rotation.x - look_dir.y * (mouse_sens * 8) * sens_mod * delta, -1.5, 1.5)
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

	walk_vel = walk_vel.move_toward(walk_dir * speed * move_dir.length(), acceleration * delta)
	return walk_vel

func _gravity(delta: float) -> Vector3:
	grav_vel = Vector3.ZERO if is_on_floor() or Globals.noclip else grav_vel.move_toward(Vector3(0, velocity.y - Globals.sv_gravity, 0), Globals.sv_gravity * delta)
	return grav_vel

func _jump(delta: float) -> Vector3:
	if Globals.noclip:
		return Vector3.ZERO
	
	if jumping:
		if is_on_floor(): 
			jump_vel = Vector3(0, sqrt(4 * jump_height * Globals.sv_gravity), 0)
		jumping = false
		return jump_vel
	jump_vel = jump_vel.move_toward(Vector3.ZERO, Globals.sv_gravity * delta)
	return jump_vel
