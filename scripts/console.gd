extends Node

var raw_console_text = null
var console_input = null

func _ready():
	raw_console_text = get_parent().get_node("/root/GameUI/Console/ConsoleContainer/ConsoleTextContainer/ConsoleText")
	console_input = get_parent().get_node("/root/GameUI/Console/ConsoleContainer/ConsoleInput")
	raw_console_text.text = ""
	console_input.text = ""
	self.close()

func open():
	get_parent().get_node("/root/GameUI/Console").visible = true
	console_input.grab_focus()

func close():
	get_parent().get_node("/root/GameUI/Console").visible = false

func log(msg):
	print(msg)
	raw_console_text.text = raw_console_text.text + str(msg) + "\n"

func eval(input):
	self.log("] %s" % [input])
	
	var command = input
	var args = []
	
	if input.find(" "):
		command = input.split(" ")[0]
		args = input.split(" ").slice(1)
		
	if command == "map":
		if args.size():
			Maps.load_map(args[0])
		else:
			self.log("No map name provided. For a list of maps do 'maps *'.")
	
	if command == "maps":
		if args.size():
			if args[0] == "*":
				self.log("\n".join(Maps.get_maps()))
		else:
			self.log("usage: maps [<filter>]")
			
	var collision_nodes = []
	Utils.get_all_nodes_of_type(get_tree().root, "CollisionShape3D", collision_nodes)
			
	if command == "noclip":
		Globals.noclip = !Globals.noclip
		if Globals.noclip:
			self.log("noclip ON")
			Globals.sv_gravity = -1
			for c in collision_nodes:
				c.disabled = true
		else:
			self.log("noclip OFF")
			Globals.sv_gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
			for c in collision_nodes:
				c.disabled = false
		return 0
			
	if command in Globals and Globals[command] != null:
		if args.size() == 0:
			self.log("No value provided to convar!")
		elif args.size() == 1:
			if args[0].is_valid_int():
				Globals[command] = int(args[0])
			elif args[0].is_valid_float():
				Globals[command] = float(args[0])
			else:
				Globals[command] = str(args[0])
		else:
			Globals[command] = args
			
