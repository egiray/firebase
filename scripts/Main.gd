extends Control



# Firebase Singletons
var core: Object = null
var analytics: Object = null
var crashlytics: Object = null
var messaging: Object = null

# Navigation Elements
@onready var back_button: Button = $VBoxContainer/HeaderGroup/MarginContainer/HBoxContainer/BackButton
@onready var view_title: Label = $VBoxContainer/HeaderGroup/MarginContainer/HBoxContainer/ViewTitle

# Views
@onready var dashboard_view: ScrollContainer = $VBoxContainer/ContextGroup/Dashboard
@onready var module_container: Control = $VBoxContainer/ContextGroup/ModuleContainer

# Dashboard Buttons
@onready var init_btn: Button = $VBoxContainer/ContextGroup/Dashboard/List/InitializeButton
@onready var analytics_btn: Button = $VBoxContainer/ContextGroup/Dashboard/List/AnalyticsButton
@onready var crashlytics_btn: Button = $VBoxContainer/ContextGroup/Dashboard/List/CrashlyticsButton
@onready var messaging_btn: Button = $VBoxContainer/ContextGroup/Dashboard/List/MessagingButton

# Log Elements
@onready var log_output: TextEdit = $VBoxContainer/LogGroup/MarginContainer/VBoxContainer/LogOutput

# Dashboard button paths (used by flash_status / update_btn_status)
const INIT_PATH := "VBoxContainer/ContextGroup/Dashboard/List/InitializeButton"
const ANALYTICS_PATH := "VBoxContainer/ContextGroup/Dashboard/List/AnalyticsButton"
const CRASHLYTICS_PATH := "VBoxContainer/ContextGroup/Dashboard/List/CrashlyticsButton"
const MESSAGING_PATH := "VBoxContainer/ContextGroup/Dashboard/List/MessagingButton"

# Tracks the module-view button currently awaiting an async signal, per module.
# The harness only permits one in-flight call per module at a time.
var _pending_call: Dictionary = {
	"Analytics": "",
	"Crashlytics": "",
	"Messaging": "",
}

func _ready() -> void:
	get_viewport().size_changed.connect(_apply_safe_area)
	_apply_safe_area()
	log_message("=== Firebase Test Harness ===")
	show_dashboard()
	enable_service_buttons(false)
	initialize_firebase_plugins()

func _apply_safe_area() -> void:
	var safe_area = DisplayServer.get_display_safe_area()
	var window_size = DisplayServer.window_get_size()
	if safe_area.size != Vector2i.ZERO and safe_area.size != window_size:
		var top_margin = safe_area.position.y
		var bottom_margin = window_size.y - (safe_area.position.y + safe_area.size.y)
		var left_margin = safe_area.position.x
		var right_margin = window_size.x - (safe_area.position.x + safe_area.size.x)
		
		if has_node("VBoxContainer"):
			var vbox = $VBoxContainer
			vbox.offset_top = top_margin
			vbox.offset_bottom = -bottom_margin
			vbox.offset_left = left_margin
			vbox.offset_right = -right_margin

func initialize_firebase_plugins() -> void:
	# Core
	if Engine.has_singleton("GodotxFirebaseCore"):
		core = Engine.get_singleton("GodotxFirebaseCore")
		core.core_initialized.connect(_on_core_initialized)
		core.core_error.connect(_on_error.bind("Core"))
		log_message("✓ Firebase Core plugin found")
	else:
		log_message("✗ Firebase Core plugin not found")

	# Analytics
	if Engine.has_singleton("GodotxFirebaseAnalytics"):
		analytics = Engine.get_singleton("GodotxFirebaseAnalytics")
		analytics.analytics_initialized.connect(_on_module_init_done.bind("Analytics"))
		analytics.analytics_event_logged.connect(_on_analytics_event_logged)
		analytics.analytics_screen_logged.connect(_on_analytics_screen_logged)
		analytics.analytics_property_set.connect(_on_analytics_property_set)
		analytics.analytics_error.connect(_on_module_error.bind("Analytics"))
		log_message("✓ Firebase Analytics plugin found")
	else:
		log_message("✗ Firebase Analytics plugin not found")

	# Crashlytics
	if Engine.has_singleton("GodotxFirebaseCrashlytics"):
		crashlytics = Engine.get_singleton("GodotxFirebaseCrashlytics")
		crashlytics.crashlytics_initialized.connect(_on_module_init_done.bind("Crashlytics"))
		crashlytics.crashlytics_non_fatal_logged.connect(_on_crashlytics_non_fatal_logged)
		crashlytics.crashlytics_message_logged.connect(_on_crashlytics_message_logged)
		crashlytics.crashlytics_value_set.connect(_on_crashlytics_value_set)
		crashlytics.crashlytics_error.connect(_on_module_error.bind("Crashlytics"))
		log_message("✓ Firebase Crashlytics plugin found")
	else:
		log_message("✗ Firebase Crashlytics plugin not found")

	# Messaging
	if Engine.has_singleton("GodotxFirebaseMessaging"):
		messaging = Engine.get_singleton("GodotxFirebaseMessaging")
		messaging.messaging_initialized.connect(_on_module_init_done.bind("Messaging"))
		messaging.messaging_permission_granted.connect(_on_messaging_permission_granted)
		messaging.messaging_permission_denied.connect(_on_messaging_permission_denied)
		messaging.messaging_token_received.connect(_on_messaging_token_received)
		messaging.messaging_message_received.connect(_on_messaging_message_received)
		messaging.messaging_topic_subscribed.connect(_on_messaging_topic_subscribed)
		messaging.messaging_topic_unsubscribed.connect(_on_messaging_topic_unsubscribed)
		messaging.messaging_error.connect(_on_module_error.bind("Messaging"))
		log_message("✓ Firebase Messaging plugin found")
	else:
		log_message("✗ Firebase Messaging plugin not found")

# ============== NAVIGATION ==============

func show_dashboard() -> void:
	view_title.text = "Firebase Harness"
	back_button.visible = false
	dashboard_view.visible = true
	module_container.visible = false
	for module in module_container.get_children():
		module.visible = false

func show_module(module_name: String) -> void:
	dashboard_view.visible = false
	module_container.visible = true
	back_button.visible = true
	view_title.text = "Firebase " + module_name

	for child in module_container.get_children():
		child.queue_free()

	var node_name = module_name.replace(" ", "") + "View"
	var scene_path = "res://scenes/view_stack/" + node_name + ".tscn"

	if ResourceLoader.exists(scene_path):
		var scene = load(scene_path)
		var instance = scene.instantiate()
		module_container.add_child(instance)
		instance.name = node_name
		_connect_module_buttons(module_name, instance)
	else:
		log_message("[System] Module view '" + node_name + "' not implemented")

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
	update_btn_status(path, status)

func enable_service_buttons(enabled: bool) -> void:
	analytics_btn.disabled = !enabled
	crashlytics_btn.disabled = !enabled
	messaging_btn.disabled = !enabled

func _module_btn_path(module_name: String, btn_name: String) -> String:
	return "VBoxContainer/ContextGroup/ModuleContainer/" + module_name + "View/" + btn_name

func _connect_module_buttons(module_name: String, instance: Node) -> void:
	if module_name == "Analytics":
		_connect_btn(instance, "LogEventButton", _on_log_event_pressed)
		_connect_btn(instance, "LogScreenButton", _on_log_screen_pressed)
		_connect_btn(instance, "UserPropsButton", _on_set_user_property_pressed)
	elif module_name == "Messaging":
		_connect_btn(instance, "PermissionButton", _on_request_messaging_permission_pressed)
		_connect_btn(instance, "SubscribeButton", _on_subscribe_topic_pressed)
		_connect_btn(instance, "UnsubscribeButton", _on_unsubscribe_topic_pressed)
	elif module_name == "Crashlytics":
		_connect_btn(instance, "FatalButton", _on_crash_pressed)
		_connect_btn(instance, "NonFatalButton", _on_non_fatal_pressed)
		_connect_btn(instance, "CustomValueButton", _on_set_custom_value_pressed)

func _connect_btn(instance: Node, btn_name: String, method: Callable) -> void:
	var btn = instance.get_node_or_null(btn_name)
	if btn: btn.pressed.connect(method)

# ============== CORE ==============

func _on_initialize_pressed() -> void:
	if not core:
		log_message("[Core] Plugin not available")
		flash_status(INIT_PATH, TestButton.Status.FAILURE)
		return
	log_message("\n[Core] Initializing Firebase...")
	flash_status(INIT_PATH, TestButton.Status.PENDING)
	core.initialize()

func _on_core_initialized(success: bool) -> void:
	if not success:
		log_message("[Core] ✗ Firebase initialization failed")
		flash_status(INIT_PATH, TestButton.Status.FAILURE)
		enable_service_buttons(false)
		return

	log_message("[Core] ✓ Firebase initialized successfully!")
	flash_status(INIT_PATH, TestButton.Status.SUCCESS)
	_start_module_init_cascade()

func _start_module_init_cascade() -> void:
	if analytics:
		log_message("[Analytics] Initializing...")
		flash_status(ANALYTICS_PATH, TestButton.Status.PENDING)
		analytics.initialize()
	if crashlytics:
		log_message("[Crashlytics] Initializing...")
		flash_status(CRASHLYTICS_PATH, TestButton.Status.PENDING)
		crashlytics.initialize()
	if messaging:
		log_message("[Messaging] Initializing...")
		flash_status(MESSAGING_PATH, TestButton.Status.PENDING)
		messaging.initialize()

func _on_module_init_done(success: bool, module_name: String) -> void:
	var path := ""
	var module_btn: Button = null
	match module_name:
		"Analytics":
			path = ANALYTICS_PATH
			module_btn = analytics_btn
		"Crashlytics":
			path = CRASHLYTICS_PATH
			module_btn = crashlytics_btn
		"Messaging":
			path = MESSAGING_PATH
			module_btn = messaging_btn

	if success:
		log_message("[%s] ✓ Initialized" % module_name)
		flash_status(path, TestButton.Status.SUCCESS)
		if module_btn: module_btn.disabled = false
	else:
		log_message("[%s] ✗ Initialization failed" % module_name)
		flash_status(path, TestButton.Status.FAILURE)
		if module_btn: module_btn.disabled = true

# ============== ANALYTICS ==============

func _on_log_event_pressed() -> void:
	var btn_path = _module_btn_path("Analytics", "LogEventButton")
	if not analytics:
		log_message("[Analytics] Plugin not available")
		flash_status(btn_path, TestButton.Status.FAILURE)
		return
	log_message("\n[Analytics] Logging event: test_event")
	flash_status(btn_path, TestButton.Status.PENDING)
	_pending_call["Analytics"] = btn_path
	analytics.log_event("test_event", {"p1": "v1", "p2": 123})

func _on_log_screen_pressed() -> void:
	var btn_path = _module_btn_path("Analytics", "LogScreenButton")
	if not analytics:
		log_message("[Analytics] Plugin not available")
		flash_status(btn_path, TestButton.Status.FAILURE)
		return
	log_message("\n[Analytics] Logging screen: MainScene")
	flash_status(btn_path, TestButton.Status.PENDING)
	_pending_call["Analytics"] = btn_path
	analytics.log_screen_view("MainScene", "GodotSampleActivity")

func _on_analytics_event_logged(event_name: String) -> void:
	log_message("[Analytics] ✓ Event logged: " + event_name)
	_clear_pending("Analytics")

func _on_analytics_screen_logged(screen_name: String) -> void:
	log_message("[Analytics] ✓ Screen logged: " + screen_name)
	_clear_pending("Analytics")

func _on_set_user_property_pressed() -> void:
	var btn_path = _module_btn_path("Analytics", "UserPropsButton")
	if not analytics:
		log_message("[Analytics] Plugin not available")
		flash_status(btn_path, TestButton.Status.FAILURE)
		return
	log_message("\n[Analytics] Setting user property: test_prop = test_value")
	flash_status(btn_path, TestButton.Status.PENDING)
	_pending_call["Analytics"] = btn_path
	analytics.set_user_property("test_prop", "test_value")

func _on_analytics_property_set(prop_name: String) -> void:
	log_message("[Analytics] ✓ Property set: " + prop_name)
	_clear_pending("Analytics")

# ============== MESSAGING ==============

func _on_request_messaging_permission_pressed() -> void:
	var btn_path = _module_btn_path("Messaging", "PermissionButton")
	if not messaging:
		log_message("[Messaging] Plugin not available")
		flash_status(btn_path, TestButton.Status.FAILURE)
		return
	log_message("\n[Messaging] Requesting permissions...")
	flash_status(btn_path, TestButton.Status.PENDING)
	_pending_call["Messaging"] = btn_path
	messaging.request_permission()

func _on_subscribe_topic_pressed() -> void:
	var btn_path = _module_btn_path("Messaging", "SubscribeButton")
	if not messaging:
		log_message("[Messaging] Plugin not available")
		flash_status(btn_path, TestButton.Status.FAILURE)
		return
	log_message("\n[Messaging] Subscribing to: test_topic")
	flash_status(btn_path, TestButton.Status.PENDING)
	messaging.subscribe_to_topic("test_topic")
	_pending_call["Messaging"] = btn_path

func _on_unsubscribe_topic_pressed() -> void:
	var btn_path = _module_btn_path("Messaging", "UnsubscribeButton")
	if not messaging:
		log_message("[Messaging] Plugin not available")
		flash_status(btn_path, TestButton.Status.FAILURE)
		return
	log_message("\n[Messaging] Unsubscribing from: test_topic")
	flash_status(btn_path, TestButton.Status.PENDING)
	messaging.unsubscribe_from_topic("test_topic")
	_pending_call["Messaging"] = btn_path

func _on_messaging_permission_granted() -> void:
	log_message("[Messaging] ✓ Permission granted")
	_clear_pending("Messaging")

func _on_messaging_permission_denied() -> void:
	log_message("[Messaging] ✗ Permission denied")
	_clear_pending("Messaging")

func _on_messaging_topic_subscribed(topic: String) -> void:
	log_message("[Messaging] ✓ Subscribed to: " + topic)
	_clear_pending("Messaging")

func _on_messaging_topic_unsubscribed(topic: String) -> void:
	log_message("[Messaging] ✓ Unsubscribed from: " + topic)
	_clear_pending("Messaging")

func _on_messaging_token_received(token: String) -> void:
	log_message("[Messaging] Token: " + token)

func _on_messaging_message_received(title: String, body: String) -> void:
	log_message("[Messaging] Message received: " + title + " — " + body)

# ============== CRASHLYTICS ==============

func _on_crash_pressed() -> void:
	var btn_path = _module_btn_path("Crashlytics", "FatalButton")
	if not crashlytics:
		log_message("[Crashlytics] Plugin not available")
		flash_status(btn_path, TestButton.Status.FAILURE)
		return
	log_message("\n[Crashlytics] !!! FORCING FATAL CRASH !!!")
	flash_status(btn_path, TestButton.Status.PENDING)
	# If the crash truly propagates, the app terminates and the yellow state is lost.
	# If the exception is caught by Godot's dispatcher, the button stays yellow — a
	# visible hint that the crash did not actually take down the process.
	crashlytics.crash()

func _on_non_fatal_pressed() -> void:
	var btn_path = _module_btn_path("Crashlytics", "NonFatalButton")
	if not crashlytics:
		log_message("[Crashlytics] Plugin not available")
		flash_status(btn_path, TestButton.Status.FAILURE)
		return
	log_message("\n[Crashlytics] Logging non-fatal error")
	flash_status(btn_path, TestButton.Status.PENDING)
	_pending_call["Crashlytics"] = btn_path
	crashlytics.log_non_fatal_exception("This is a test non-fatal error")

func _on_set_custom_value_pressed() -> void:
	var btn_path = _module_btn_path("Crashlytics", "CustomValueButton")
	if not crashlytics:
		log_message("[Crashlytics] Plugin not available")
		flash_status(btn_path, TestButton.Status.FAILURE)
		return
	log_message("\n[Crashlytics] Setting custom value")
	flash_status(btn_path, TestButton.Status.PENDING)
	crashlytics.set_custom_value_string("test_key", "test_value")
	_pending_call["Crashlytics"] = btn_path

func _on_crashlytics_non_fatal_logged(message: String) -> void:
	log_message("[Crashlytics] ✓ Non-fatal logged: " + message)
	_clear_pending("Crashlytics")

func _on_crashlytics_message_logged(message: String) -> void:
	log_message("[Crashlytics] ✓ Message logged: " + message)
	_clear_pending("Crashlytics")

func _on_crashlytics_value_set(key: String) -> void:
	log_message("[Crashlytics] ✓ Value set for: " + key)
	_clear_pending("Crashlytics")

# ============== ERRORS ==============

func _on_error(message: String, module: String) -> void:
	log_message("[" + module + "] ✗ Error: " + message)

func _on_module_error(message: String, module_name: String) -> void:
	log_message("[%s] ✗ Error: %s" % [module_name, message])
	var path: String = _pending_call.get(module_name, "")
	if path != "":
		flash_status(path, TestButton.Status.FAILURE)
		_pending_call[module_name] = ""

func _clear_pending(module_name: String) -> void:
	var path: String = _pending_call.get(module_name, "")
	if path != "":
		flash_status(path, TestButton.Status.SUCCESS)
		_pending_call[module_name] = ""

# ============== LOG CONTROLS ==============

func _on_clear_log_pressed() -> void:
	if log_output: log_output.text = ""
	log_message("=== Log Cleared ===")

func _on_copy_log_pressed() -> void:
	if log_output:
		DisplayServer.clipboard_set(log_output.text)
		log_message("[System] Log copied to clipboard")
