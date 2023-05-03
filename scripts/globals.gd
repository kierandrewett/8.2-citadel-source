extends Node

@export var cl_showpos = 1
@export var cl_showfps = 1

@export var cl_pitchdown = 150
@export var cl_pitchup = 150

@export var noclip = 0
@export var noclip_delta = 1

@export var sv_gravity = 0
@export var sv_flick_deceleration_velocity = 1200

@export var sensitivity = 3

func _ready():
	sv_gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
