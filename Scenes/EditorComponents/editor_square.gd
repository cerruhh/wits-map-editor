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
@onready var new_window:Window = $NewWindow
@onready var SliderWindow:Window = $SliderWindow

var editing_button: Button = null

var FileDialogPacked:PackedScene
var FileSaveDialogPacked:PackedScene
var headers_visible: bool = true
var scaling_enabled:bool = true


var MapRulesDict:Dictionary
@onready var button_theme:Theme = preload("res://Scenes/EditorComponents/button_cell.tres")

const BASE_BTN_SIZE:Vector2 = Vector2(40, 40)  # Base size for buttons
const MIN_BTN_SIZE:Vector2 = Vector2(16, 16)   # Minimum allowed size for buttons


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
	
	var confirm_btn:Button = new_window.get_node("HBoxContainer/Confirm")
	var cancel_btn:Button = new_window.get_node("HBoxContainer/Cancel")
	confirm_btn.pressed.connect(_connect_new_map)
	cancel_btn.pressed.connect(_connect_new_map_cancel)
	
	var slider_scale:HSlider = SliderWindow.get_node("ScaleSlider")
	slider_scale.value_changed.connect(change_scale)
	
	SliderWindow.get_node("Close").pressed.connect(toggle_window)

func change_scale(val:float) -> void:
	scale = Vector2(val, val)
	
func toggle_window() -> void:
	if SliderWindow.visible:
		SliderWindow.hide()
	else:
		SliderWindow.show()

func save_map_to_csv(path: String) -> void:
	if not MapButtons:
		print("MapButtons is not assigned!")
		return

	var rows: Array = []

	var children = MapButtons.get_children()
	var total_children = children.size()

	# MapButtons columns and rows should be map_size + 1 (including headers)
	var expected_columns = map_size + 1
	var expected_rows = map_size + 1

	# Confirm children count matches expected grid size
	if total_children < expected_columns * expected_rows:
		print("Warning: Not enough children in MapButtons for full grid!")

	# The indexes in children go row-wise:
	# Index = row * columns + col
	# Col 0 and Row 0 are headers (Labels)
	# Map cells start at row 1, col 1

	for row_i in range(1, expected_rows):  # skip header row (0)
		var row: Array = []
		for col_i in range(1, expected_columns):  # skip header col (0)
			var index = row_i * expected_columns + col_i
			if index < total_children:
				var child = children[index]
				if child is Button:
					row.append(child.text)
				else:
					# Could be a Label or something else in unexpected position
					row.append("")
			else:
				row.append("")
		rows.append(row)

	# Convert rows (2D array) to CSV text
	var csv_lines: Array = []
	for row in rows:
		# If you expect special chars, implement proper CSV escaping here
		var line = ",".join(row)
		csv_lines.append(line)
	var csv_text = "\n".join(csv_lines)

	print(csv_text)

	# Save to file
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
		print(row)
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
	
	map_size = map_csv[0].size()
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
		
		

func toggle_headers_visibility() -> void:
	headers_visible = not headers_visible

	var children = MapButtons.get_children()

	if children.size() == 0:
		return

	var cols = MapButtons.columns

	# First row: index 0 through cols-1
	for i in range(cols):
		if i < children.size():
			children[i].visible = headers_visible

	# First column: every (cols)th child starting at 0, ignoring the first row already processed
	for row in range(1, int(ceil(children.size() / cols))):
		var idx = row * cols
		if idx < children.size():
			children[idx].visible = headers_visible


func get_column_label(index: int) -> String:
	var result = ""
	var n = index
	while n >= 0:
		var remainder = n % 26                      # remainder: int
		var code = remainder + 'A'.unicode_at(0)               # 'A'[0]: returns int 65
		result = char(code) + result                 # char(int) converts code to String
		n = int(n / 26) - 1
	return result



func create_header_label(text: String) -> Label:
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = VERTICAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	label.custom_minimum_size = Vector2(40, 40)  # Adjust for your button size

	# Optional: style label to look visually distinct as header
	label.add_theme_color_override("font_color", Color.YELLOW)

	return label




func populate_map(csv_map: Array) -> void:
	if not MapButtons:
		print("MapButtons GridContainer is not assigned!")
		return

	remove_node_children(MapButtons)  # Remove all previous children (buttons and labels)

	# Columns + 1 to add left header column
	MapButtons.columns = map_size + 1

	# Add top-left corner label ("x")
	var top_left_label = create_header_label("x")
	MapButtons.add_child(top_left_label)

	# Add column header labels A, B, C... AA, AB...
	for col_index in range(map_size):
		var col_label_str = get_column_label(col_index)
		var header_label = create_header_label(col_label_str)
		MapButtons.add_child(header_label)

	# Add rows
	for row_index in range(map_size):
		# Add row header first (1, 2, 3...)
		var row_label = create_header_label(str(row_index + 1))
		MapButtons.add_child(row_label)

		# Add buttons for each cell from csv_map
		if row_index >= csv_map.size():
			print("Row index out of CSV bounds:", row_index)
			break
		var row = csv_map[row_index]

		for col_index in range(map_size):
			if col_index >= row.size():
				print("Column index out of bounds at row:", row_index, "col:", col_index)
				break

			var cell_text: String = str(row[col_index])
			var btn = create_editable_button(cell_text)
			MapButtons.add_child(btn)
	var map_factor:float = calculate_scale_factor(map_size)
	print(calculate_scale_factor(map_size))
	scale = Vector2(map_factor, map_factor)


func calculate_scale_factor(map_size: int, base_cell_size: Vector2 = Vector2(40, 40), min_scale: float = 0.3) -> float:
	if map_size < 20:
		# No scaling below map size 20
		return 1.0

	# Get available size inside parent container with some padding
	var parent_size = get_size()
	var padding = Vector2(10, 10)
	var available_size = parent_size - padding * 2

	# Number of columns and rows including headers
	var total_cells = map_size + 1

	# Required size for whole grid at scale 1
	var required_width = base_cell_size.x * total_cells
	var required_height = base_cell_size.y * total_cells

	# Calculate scale factors needed to fit width and height respectively
	var scale_x = available_size.x / required_width
	var scale_y = available_size.y / required_height

	# The scale must fit both width and height, so take the minimum scale factor
	var scale1 = min(scale_x, scale_y)

	# Scale must not be bigger than 1, and not smaller than min_scale
	scale1 = clamp(scale1, min_scale, 1.0)

	return scale1



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

func _connect_new_map() -> void:
	var linetext:String = $NewWindow/LineEdit.text
	var is_valid_int = linetext.is_valid_int()
	
	if is_valid_int:
		map_size = int(linetext)
		load_empty_map()
		_connect_new_map_cancel()

func _connect_new_map_cancel() -> void:
	new_window.hide()
	$NewWindow/LineEdit.text = ""

func new_map_dialog() -> void:
	new_window.show()
