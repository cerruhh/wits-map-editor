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
	
	var view_menu_btn = MenuButton.new()
	view_menu_btn.text = "View"
	toolbar.add_child(view_menu_btn)
	
	var view_menu = view_menu_btn.get_popup()
	view_menu.add_item("Toggle Scaling")
	
	view_menu.id_pressed.connect(Callable(self, "_on_view_item_pressed").bind(view_menu))

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

func _on_view_item_pressed(id, popup_menu) -> void:
	var item_text = popup_menu.get_item_text(id)
	print("Menu item selected:", item_text)
	match item_text:
		"Toggle Scaling":
			print("ViewScaling")
			EditorSquare.scaling_enabled = !EditorSquare.scaling_enabled
			if EditorSquare.scaling_enabled:
				var scale_float = EditorSquare.calculate_scale_factor(EditorSquare.map_size)
				EditorSquare.scale = Vector2(scale_float, scale_float)
			else:
				EditorSquare.scale = Vector2(1,1)
		"View Border Index":
			print("Border Index View")
			EditorSquare.toggle_headers_visibility()
		_:
			print("Unknown menu item")
