extends Control
@export_category("Map")
@export var map_size:int = 8
@export var map_path:String = ""
@export var map_format:String = "csv"
@export var map_loaded:bool = false

@export_category("Components")
@export var MapButtons:GridContainer
@export var MapRules:MapRulesResource
@export var ToolBar:Control


@onready var bottom_line_edit: LineEdit = LineEdit.new()
var editing_button: Button = null

var FileDialogPacked:PackedScene
var FileSaveDialogPacked:PackedScene

var MapRulesDict:Dictionary
@onready var button_theme:Theme = preload("res://Scenes/EditorComponents/button_cell.tres")

func _ready() -> void:
	FileDialogPacked = preload("res://Scenes/EditorComponents/Dialogs/LoadMap.tscn")
	FileSaveDialogPacked = preload("res://Scenes/EditorComponents/Dialogs/SaveMap.tscn")
	
	MapRulesDict = MapRules.create_dict()
	if MapButtons:
		MapButtons.columns = map_size  # Set columns to map_size
	
	# Add bottom LineEdit to the scene, hidden initially
	add_child(bottom_line_edit)
	bottom_line_edit.anchor_left = 0
	bottom_line_edit.anchor_right = 1
	bottom_line_edit.anchor_top = 1
	bottom_line_edit.anchor_bottom = 1
	
	bottom_line_edit.position = Vector2(10, -30)  # x=10 px from left, y=30 px above bottom anchor
	bottom_line_edit.size = Vector2(get_viewport_rect().size.x - 20, 30)  # width minus 10 + 10 px margins, height 30 px
	
	bottom_line_edit.visible = false
	
	
	bottom_line_edit.text_submitted.connect(Callable(self, "_on_bottom_edit_entered"))
	bottom_line_edit.connect("focus_exited", Callable(self, "_on_bottom_edit_focus_exited"))
	
	var toolbar_width = ToolBar.size.x
	var parent_width = get_parent().size.x
	var target_width = parent_width - toolbar_width
	MapButtons.custom_minimum_size.x = target_width


func save_map_to_csv(path: String) -> void:
	if not MapButtons:
		print("MapButtons is not assigned!")
		return

	var rows: Array = []

	# Assume MapButtons' children are buttons added row-wise in order
	var children = MapButtons.get_children()
	var total_buttons = children.size()

	# Make sure we have enough buttons for a full map_size x map_size grid
	if total_buttons < map_size * map_size:
		print("Warning: Not enough buttons to fill the map grid!")
	
	for row_i in range(map_size):
		var row: Array = []
		for col_i in range(map_size):
			var index = row_i * map_size + col_i
			if index < total_buttons:
				var btn = children[index]
				if btn is Button:
					row.append(btn.text)
				else:
					row.append("")  # Fallback if not a Button for some reason
			else:
				row.append("")  # Fallback if out of bounds
		rows.append(row)

	# Convert 2D array to CSV string
	var csv_lines: Array = []
	for row in rows:
		# Escape commas or quotes if necessary, here simple join assuming no commas
		var line = ",".join(row)
		csv_lines.append(line)
	var csv_text = "\n".join(csv_lines)

	# Save CSV string to file
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		print("Failed to open file for writing: ", path)
		return
	file.store_string(csv_text)
	file.close()

	print("Map saved to: ", path)


func create_empty_array(arrsize: int) -> Array:
	var map_array: Array = []
	for i in arrsize:
		var row: Array = []
		for j in arrsize:
			row.append("")  # Empty string represents an empty cell
		map_array.append(row)
	return map_array

#func start_editing(btn: Button) -> void:
	## Create the LineEdit which will replace the button while editing
	#var le:LineEdit = LineEdit.new()
	#le.text = btn.text
	#
	#le.size = btn.size
	#le.position = btn.position
	#
	##le.rect_min_size = btn.rect_size
	#le.size_flags_horizontal = Control.SIZE_FILL
	#le.size_flags_vertical = Control.SIZE_FILL
	##le.anchor_preset = btn.get_anchor_preset()  # kneep anchors if needed
	##le.margin_left = btn.margin_left
	##le.margin_top = btn.margin_top
	##le.margin_right = btn.margin_right
	##le.margin_bottom = btn.margin_bottom
#
	## Add it as sibling or to the same container
	#btn.get_parent().add_child(le)
	#le.global_position = btn.global_position
	#le.grab_focus()
	#
	## Hide the button while editing
	#btn.visible = false
#
	## Connect signals for finishing edit
	#le.connect("text_entered", Callable(self, "_on_edit_finished").bind(btn, le))
	#le.connect("focus_exited", Callable(self, "_on_edit_finished").bind(btn, le))

func _on_bottom_edit_focus_exited() -> void:
	# Cancel editing if the input loses focus
	editing_button = null
	bottom_line_edit.visible = false
	bottom_line_edit.text = ""

func _on_bottom_edit_entered(new_text: String) -> void:
	if editing_button:
		editing_button.text = new_text
	editing_button = null
	bottom_line_edit.visible = false
	bottom_line_edit.text = ""

func start_editing(btn: Button) -> void:
	editing_button = btn
	bottom_line_edit.text = btn.text
	bottom_line_edit.visible = true
	bottom_line_edit.grab_focus()

func _on_edit_finished(btn: Button, le: LineEdit, new_text: String = "") -> void:
	if new_text != "":
		btn.text = new_text
	else:
		# fallback to whatever text in lineedit (if focus exited without pressing enter)
		btn.text = le.text

	btn.visible = true
	le.queue_free()


func create_editable_button(text: String) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.focus_mode = Control.FocusMode.FOCUS_NONE
	btn.size_flags_horizontal = Control.SIZE_FILL
	btn.size_flags_vertical = Control.SIZE_FILL
	btn.custom_minimum_size = Vector2(40, 40)
	btn.theme = button_theme
	# Connect the right-click
	btn.gui_input.connect(_on_button_gui_input.bind(btn))
	
	return btn


func _on_button_gui_input(event: InputEvent, btn: Button) -> void:
	if event is InputEventMouseButton and btn is Button and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			print("Start editing")
			start_editing(btn)

		elif event.button_index == MOUSE_BUTTON_LEFT:
			if ToolBar.move_mode_active:
				ToolBar._handle_move_click(btn)
				return

			# Handle brush row and column actions
			ToolBar._apply_brush_to_button(btn)


func apply_brush_to_button(btn: Button) -> void:
	if ToolBar.brush_selected and ToolBar.current_brush != "":
		if ToolBar.current_brush == "!ERASE_ACTION":
			btn.text = ""
		else:
			btn.text = ToolBar.current_brush

func brush_entire_row(clicked_btn: Button) -> void:
	if not ToolBar.brush_selected or ToolBar.current_brush == "":
		return

	# Assuming buttons are children of a GridContainer named "CellsContainer"
	# and arranged row-wise.

	var cells_container:GridContainer = clicked_btn.get_parent()  # Change to your actual parent container
	if not cells_container:
		print("Cannot find cells container for the button!")
		return

	# Identify index of the clicked button
	var buttons:Array = cells_container.get_children()
	var index:int = buttons.find(clicked_btn)
	if index == -1:
		print("Button not found in parent container children!")
		return

	# Assume grid size from your map_size or container columns count

	# Calculate the row number (integer division)
	var row:int = index / map_size

	# Iterate over all buttons in that row
	for col:int in range(map_size):
		var button_index:int = row * map_size + col
		if button_index < buttons.size():
			var row_btn:Button = buttons[button_index]
			if row_btn is Button:
				if ToolBar.current_brush == "!ERASE_ACTION":
					row_btn.text = ""
				else:
					row_btn.text = ToolBar.current_brush

func brush_entire_column(clicked_btn: Button) -> void:
	if not ToolBar.brush_selected or ToolBar.current_brush == "":
		return

	var cells_container = clicked_btn.get_parent()
	if not cells_container:
		print("Cannot find cells container for the button!")
		return

	var buttons = cells_container.get_children()
	var index = buttons.find(clicked_btn)
	if index == -1:
		print("Button not found in parent container children!")
		return

	var col = index % map_size  # Modulo for column number
	var total_buttons = buttons.size()
	var total_rows = int(total_buttons / map_size)  # Assuming full rows

	for row in range(total_rows):
		var button_index = row * map_size + col
		if button_index < total_buttons:
			var col_btn = buttons[button_index]
			if col_btn is Button:
				if ToolBar.current_brush == "!ERASE_ACTION":
					col_btn.text = ""
				else:
					col_btn.text = ToolBar.current_brush


func read_csv_file(path: String) -> Array:
	var result: Array = []
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		print("Cannot open file: ", path)
		return result  # return empty array on error

	while !file.eof_reached():
		var row: Array = file.get_csv_line()
		if row.size() == 0:
			continue
		result.append(row)
	file.close()
	return result


func load_map(map: String = "") -> void:
	if map == "":
		print("Invalid map")
		return

	var map_csv: Array = read_csv_file(map)

	if map_csv.size() == 0:
		print("Empty or invalid CSV")
		return

	populate_map(map_csv)
	map_loaded = true

func load_empty_map() -> void:
	var map_csv: Array = create_empty_array(map_size)
	
	if map_csv.size() == 0:
		print("Empty or invalid CSV")
		return
	
	populate_map(map_csv)
	
	var toolbar_width = ToolBar.size.x
	var parent_width = get_parent().size.x
	var target_width = parent_width - toolbar_width
	MapButtons.custom_minimum_size.x = target_width
	
	map_loaded = false

func remove_node_children(node:Node) -> void:
	for n in node.get_children():
		node.remove_child(n)
		n.queue_free() 

func populate_map(csv_map: Array) -> void:
	if not MapButtons:
		print("MapButtons GridContainer is not assigned!")
		return

	remove_node_children(MapButtons) # Remove any existing buttons

	# Optionally, ensure GridContainer columns matches map_size
	MapButtons.columns = map_size

	# We iterate rows and columns to create buttons for each cell
	for row_index in range(map_size):
		if row_index >= csv_map.size():
			print("Row index out of CSV bounds:", row_index)
			break
		var row = csv_map[row_index]
		for col_index in range(map_size):
			if col_index >= row.size():
				print("Column index out of bounds at row:", row_index, "col:", col_index)
				break

			var cell_text: String = str(row[col_index])
			
			# Create a new button for this cell
			var btn = create_editable_button(cell_text)
			MapButtons.add_child(btn)

func load_dialog() -> void:
	print("Load Connect")
	var open_dialog:FileDialog = FileDialogPacked.instantiate()
	add_child(open_dialog)
	open_dialog.file_selected.connect(load_map)
	open_dialog.show()

func save_dialog_opt() -> void:
	print("Save connected")
	var save_dialog:FileDialog = FileSaveDialogPacked.instantiate()
	add_child(save_dialog)
	save_dialog.file_selected.connect(save_map_to_csv)
	save_dialog.show()
