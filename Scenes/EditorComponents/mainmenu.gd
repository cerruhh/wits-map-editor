extends Control

@export var toolbar:HBoxContainer
@export var EditorSquare:Control

func _ready():
	# Create File menu button
	var file_menu_btn = MenuButton.new()
	file_menu_btn.text = "File"
	toolbar.add_child(file_menu_btn)
	var file_menu = file_menu_btn.get_popup()
	file_menu.add_item("New")
	file_menu.add_item("Open...")
	file_menu.add_item("Save")
	
	file_menu.add_separator()
	file_menu.add_item("Exit")
	file_menu.id_pressed.connect(Callable(self, "_on_menu_item_pressed").bind(file_menu))

func _on_menu_item_pressed(id, popup_menu):
	var item_text = popup_menu.get_item_text(id)
	print("Menu item selected:", item_text)
	match item_text:
		"New":
			EditorSquare.new_map_dialog()
		"Open...":
			EditorSquare.load_dialog()
		"Save":
			EditorSquare.save_dialog_opt()
		"Exit":
			get_tree().quit()
		_:
			print("Unknown menu item")
