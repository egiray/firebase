extends Control

# Firebase Singletons
var core: Object = null

# Navigation Elements
@onready var back_button: Button = $VBoxContainer/HeaderGroup/MarginContainer/HBoxContainer/BackButton
@onready var view_title: Label = $VBoxContainer/HeaderGroup/MarginContainer/HBoxContainer/ViewTitle

# Views
@onready var dashboard_view: ScrollContainer = $VBoxContainer/ContextGroup/Dashboard
@onready var module_container: Control = $VBoxContainer/ContextGroup/ModuleContainer

# Dashboard Buttons (to enable after init)
@onready var analytics_btn: Button = $VBoxContainer/ContextGroup/Dashboard/List/AnalyticsButton
@onready var crashlytics_btn: Button = $VBoxContainer/ContextGroup/Dashboard/List/CrashlyticsButton
@onready var messaging_btn: Button = $VBoxContainer/ContextGroup/Dashboard/List/MessagingButton

# Log Elements
@onready var log_output: TextEdit = $VBoxContainer/LogGroup/MarginContainer/VBoxContainer/LogOutput

func _ready() -> void:
	log_message("=== Firebase Test Harness ===")
	show_dashboard()
	initialize_firebase_plugins()

func initialize_firebase_plugins() -> void:
	# Firebase Core
	if Engine.has_singleton("GodotxFirebaseCore"):
		core = Engine.get_singleton("GodotxFirebaseCore")
		core.core_initialized.connect(_on_core_initialized)
		core.core_error.connect(_on_error.bind("Core"))
		log_message("✓ Firebase Core plugin found")
	else:
		log_message("✗ Firebase Core plugin not found")

# ============== NAVIGATION ==============

func show_dashboard() -> void:
	view_title.text = "Firebase Harness"
	back_button.visible = false
	dashboard_view.visible = true
	module_container.visible = false
	for module in module_container.get_children():
		module.visible = false

func show_module(module_name: String) -> void:
	# Guard: Check if the module button is enabled in the dashboard
	var btn_node_name = module_name.replace(" ", "") + "Button"
	var btn = get_node_or_null("VBoxContainer/ContextGroup/Dashboard/List/" + btn_node_name)
	if btn and btn.disabled:
		return

	dashboard_view.visible = false
	module_container.visible = true
	back_button.visible = true
	view_title.text = "Firebase " + module_name
	
	# Attempt to find the view node (e.g., "RemoteConfigView")
	var node_name = module_name.replace(" ", "") + "View"
	var view_node = module_container.get_node_or_null(node_name)
	if view_node:
		view_node.visible = true
	else:
		log_message("[System] Module view '" + node_name + "' not implemented (Check feature branches)")

# ============== HELPERS ==============

func log_message(message: String) -> void:
	print(message)
	if log_output:
		log_output.text += message + "\n"
		log_output.scroll_vertical = log_output.get_line_count()

func update_btn_status(path: String, status: int) -> void:
	var btn = get_node_or_null(path)
	if btn and btn.has_method("update_status"):
		btn.update_status(status)

func flash_status(path: String, status: int) -> void:
	# For synchronous operations that complete instantly
	update_btn_status(path, status)

func enable_service_buttons(enabled: bool) -> void:
	analytics_btn.disabled = !enabled
	crashlytics_btn.disabled = !enabled
	messaging_btn.disabled = !enabled

# ============== CORE ==============

func _on_initialize_pressed() -> void:
	if core:
		log_message("\n[Core] Initializing Firebase...")
		update_btn_status("VBoxContainer/ContextGroup/Dashboard/List/InitializeButton", TestButton.Status.PENDING)
		core.initialize()
	else:
		log_message("[Core] Plugin not available")
		update_btn_status("VBoxContainer/ContextGroup/Dashboard/List/InitializeButton", TestButton.Status.FAILURE)

func _on_core_initialized(success: bool) -> void:
	if success:
		log_message("[Core] ✓ Firebase initialized successfully!")
		update_btn_status("VBoxContainer/ContextGroup/Dashboard/List/InitializeButton", TestButton.Status.SUCCESS)
		enable_service_buttons(true)
	else:
		log_message("[Core] ✗ Firebase initialization failed")
		update_btn_status("VBoxContainer/ContextGroup/Dashboard/List/InitializeButton", TestButton.Status.FAILURE)
		enable_service_buttons(false)

# ============== GENERAL ==============

func _on_error(message: String, module: String) -> void:
	log_message("[" + module + "] ✗ Error: " + message)

func _on_clear_log_pressed() -> void:
	if log_output: log_output.text = ""
	log_message("=== Log Cleared ===")

func _on_copy_log_pressed() -> void:
	if log_output:
		DisplayServer.clipboard_set(log_output.text)
		log_message("[System] Log copied to clipboard")
