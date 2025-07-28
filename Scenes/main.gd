extends Control
@export_category("Key binds")
@export var LOAD_DIALOGUE:String = "load_map_dialog"
@export var NEW_MAP:String = "create_blank_map"
@export var SAVE_MAP:String = "save_map_dialog"

@export_category("Components")
@export var EditorSquare:Control

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_released(LOAD_DIALOGUE):
		EditorSquare.load_dialog()
	elif event.is_action_released(NEW_MAP):
		EditorSquare.load_empty_map()
	elif event.is_action_released(SAVE_MAP):
		EditorSquare.save_dialog_opt()
