extends Node

func get_all_nodes(node = get_tree().root, list = []):
	list.append(node)
	
	for child in node.get_children():
		get_all_nodes(child, list)
		
	return list

func get_all_nodes_of_type(node = get_tree().root, type = "", list = []):
	print(node.get_class())
	if node.get_class() == type:
		list.append(node)
	
	for child in node.get_children():
		get_all_nodes_of_type(child, type, list)
		
	return list
