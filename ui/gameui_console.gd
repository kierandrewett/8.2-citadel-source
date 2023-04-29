extends LineEdit

var history = [self.text]
var history_index = 0

func eval(input):
	Console.eval(input)
	history.append(self.text)
	history_index = len(history)
	self.text = ""

func on_input(event):
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_UP and history_index > 0: # If up arrow is pressed
				history_index = (history_index - 1) % len(history) # Cycle through commands
				self.text = history[history_index]
			elif event.keycode == KEY_DOWN: # If down arrow is pressed
				history_index = (history_index + 1) % len(history) # Cycle through commands
				self.text = history[history_index]
			elif event.keycode == KEY_ENTER:
				history_index = len(history)
