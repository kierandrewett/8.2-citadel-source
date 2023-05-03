extends CharacterBody3D

var speed: float = 3 # m/s
var acceleration: float = 80 # m/s^2
var deceleration: float = 10

var jump_height: float = 0.75 # m
var mouse_sens: float = Globals.sensitivity

var jumping: bool = false
var mouse_captured: bool = false

var gravity: float = Globals.sv_gravity

var move_dir: Vector2 # Input direction for movement
var look_dir: Vector2 # Input direction for look/aim

var walk_vel: Vector3 # Walking velocity 
var grav_vel: Vector3 # Gravity velocity 
var jump_vel: Vector3 # Jumping velocity

var player_health = 0
var suit_health = 0

@onready var camera: Camera3D = $Camera

func _ready() -> void:
	capture_mouse()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion: 
		look_dir = event.relative * 0.01
	if Input.is_action_just_pressed("jump"): 
		jumping = true

func _physics_process(delta: float) -> void:
	if GameUI.visible:
		return
	
	if mouse_captured: _rotate_camera(delta)
	velocity = _walk(delta) + _gravity(delta) + _jump(delta)
	move_and_slide()

func capture_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true

func release_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false

func _rotate_camera(delta: float, sens_mod: float = 50.0) -> void:
	look_dir += Input.get_vector("left","right","up","down")
	camera.rotation.y -= look_dir.x * mouse_sens * sens_mod * delta
	camera.rotation.x = clamp(camera.rotation.x - look_dir.y * mouse_sens * sens_mod * delta, -1.567, 1.567)
	look_dir = Vector2.ZERO

func _walk(delta: float) -> Vector3:
	move_dir = Input.get_vector("moveleft", "moveright", "forward", "back")
	var _forward: Vector3 = camera.transform.basis * Vector3(move_dir.x, 0, move_dir.y)
	var walk_dir: Vector3 = Vector3(_forward.x, 0, _forward.z).normalized()
	var current_accel = 0
	
	if move_dir.length():
		current_accel = acceleration
	elif get_floor_angle() < 20:
		current_accel = deceleration
		
	print(current_accel)
	
	walk_vel = walk_vel.move_toward(walk_dir * speed * move_dir.length(), current_accel * delta)
	
	return walk_vel

func _gravity(delta: float) -> Vector3:
	grav_vel = Vector3.ZERO if is_on_floor() else grav_vel.move_toward(Vector3(0, velocity.y - gravity, 0), gravity * delta)
	return grav_vel

func _jump(delta: float) -> Vector3:
	if jumping:
		if is_on_floor(): jump_vel = Vector3(0, sqrt(4 * jump_height * gravity), 0)
		jumping = false
		return jump_vel
	jump_vel = Vector3.ZERO if is_on_floor() else jump_vel.move_toward(Vector3.ZERO, gravity * delta)
	return jump_vel

func setpos(x, y, z):
	position = Vector3(x, y, z)
