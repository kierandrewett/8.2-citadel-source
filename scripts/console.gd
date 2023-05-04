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

func is_open():
	return get_parent().get_node("/root/GameUI/Console").visible

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
		
	var i = 0
	for item in args:
		if item.length() == 0:
			args.remove_at(i)
		i = i + 1
		
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
			
	if command == "ent_fire":
		if args.size() < 1:
			self.log("Usage:\n    ent_fire <target> [action] [value] ")
		
		var target = args[0]
		var action = null
		var values = []

		if args.size() > 1:
			action = args[1]
		
		values = args.slice(2)
			
		var targeted_node = Maps.current_scene.get_node(target)
		
		if targeted_node == null:
			var matched = Utils.get_node_by_name(get_tree().root, target)
			
			if matched != null:
				targeted_node = matched
		
		if targeted_node == null and instance_from_id(int(target)):
			targeted_node = instance_from_id(int(target))
				
		if targeted_node == null:
			self.log("No target found by '%s'." % [target])
			return 1
		
		if action != null:
			if action in targeted_node:
				var typeof = typeof(targeted_node[action])
				
				# Function
				if typeof(typeof) == TYPE_STRING and typeof.ends_with("::%s" % [action]):
					self.log(targeted_node[action].call(values if values else []))
				else:
					if values.size() >= 1 and values[0] != null:
						var parsed
						
						if values[0].is_valid_int():
							parsed = int(values[0])
						elif values[0].is_valid_float():
							parsed = float(values[0])
						else:
							parsed = values[0]
						targeted_node[action] = parsed
						self.log("\"%s.%s\" = \"%s\"" % [targeted_node, action, parsed])
					else:
						self.log(targeted_node[action])
			else:
				self.log("No index '%s' on %s" % [action, targeted_node])
				return 1
			return 0
		else:
			self.log(targeted_node)
			return 0
		
	if command in Globals and Globals[command] != null:
		if args.size() == 0:
			self.log("\"%s\" = \"%s\"" % [command, Globals[command]])
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
			
