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
	file_menu.add_separator()
	file_menu.add_item("Exit")
	file_menu.id_pressed.connect(Callable(self, "_on_menu_item_pressed").bind(file_menu))
	# Create Edit menu button
	var edit_menu_btn = MenuButton.new()
	edit_menu_btn.text = "Edit"
	toolbar.add_child(edit_menu_btn)
	var edit_menu = edit_menu_btn.get_popup()
	edit_menu.add_item("Undo")
	edit_menu.add_item("Redo")
	edit_menu.add_separator()
	edit_menu.add_item("Copy")
	edit_menu.add_item("Paste")
	edit_menu.id_pressed.connect(Callable(self, "_on_menu_item_pressed").bind(edit_menu))
	
	# Create About menu button
	var about_menu_btn = MenuButton.new()
	about_menu_btn.text = "About"
	toolbar.add_child(about_menu_btn)
	var about_menu = about_menu_btn.get_popup()
	about_menu.add_item("About This App")
	about_menu.id_pressed.connect(Callable(self, "_on_menu_item_pressed").bind(about_menu))

func _on_menu_item_pressed(id, popup_menu):
	var item_text = popup_menu.get_item_text(id)
	print("Menu item selected:", item_text)
	match item_text:
		"New":
			EditorSquare.load_empty_map()
		"Open...":
			EditorSquare.load_dialog()
		"Exit":
			get_tree().quit()
		"Undo":
			print("Undo action selected")
		"Redo":
			print("Redo action selected")
		"Copy":
			print("Copy action selected")
		"Paste":
			print("Paste action selected")
		"About This App":
			print("Show About dialog")
		_:
			print("Unknown menu item")
