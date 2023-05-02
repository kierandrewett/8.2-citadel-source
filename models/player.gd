extends CharacterBody3D

var speed = 10
var acceleration = 8
var deceleration = 10
var air_control = 0.3
var jump_height = 10

var vel = Vector3.ZERO

var direction = Vector3()
var input_axis = Vector2()

var current_accel

var gravity: float = Globals.sv_gravity * 3
		
@onready var camera: Camera3D = $Camera

func _ready() -> void:
	pass
	
func direction_input() -> void:
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
	
	input_axis = Input.get_vector("back", "forward", "moveleft", "moveright")
	
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
