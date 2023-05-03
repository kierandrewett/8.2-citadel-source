extends CharacterBody3D

# Player speed
var speed = 3

# How fast player accelerates
var acceleration = 10

# How fast player decelerates
var deceleration = 8

# How much control player gets when flying/in air
var air_control = 0.3

# How high player can jump
var jump_height = 4

var vel = Vector3.ZERO

var direction = Vector3()
var input_axis = Vector2()

var current_accel

var gravity: float = Globals.sv_gravity * 3
		
@onready var camera: Camera3D = $Camera

func _ready() -> void:
	pass
	
# Handles camera pan using mouse/controller
func rotate_camera() -> void:
	var look_axis = Input.get_vector("down", "up", "left", "right")
	print(look_axis)
	
# Handles movement controls (WASD)
func direction_input() -> void:
	var input_axis = Input.get_vector("back", "forward", "moveleft", "moveright")
	direction = Vector3()
	var aim: Basis = get_global_transform().basis
	direction = aim.z * -input_axis.x + aim.x * input_axis.y

func accelerate(delta: float) -> void:
	# Using only the horizontal velocity, interpolate towards the input.
	var temp_vel := velocity
	temp_vel.y = 0
	
	var target: Vector3 = direction * speed
	
	if direction.dot(temp_vel) > 0:
		current_accel = acceleration
	else:
		current_accel = deceleration
	
	if not is_on_floor():
		current_accel *= air_control
	
	temp_vel = temp_vel.lerp(target, current_accel * delta)
	
	velocity.x = temp_vel.x
	velocity.z = temp_vel.z
	
# every phys frame
func _physics_process(delta):
	if GameUI.visible:
		return
	
	rotate_camera()
	direction_input()
	
	if is_on_floor():
		if Input.is_action_just_pressed(&"jump"):
			velocity.y = jump_height
	else:
		velocity.y -= gravity * delta
	
	accelerate(delta)
	
	move_and_slide()

func setpos(x, y, z):
	position = Vector3(x, y, z)
