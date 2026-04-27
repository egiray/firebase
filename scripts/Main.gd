extends Control


# Firebase Singletons
var core: Object = null
var analytics: Object = null
var crashlytics: Object = null
var messaging: Object = null
var remote_config: Object = null

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
@onready var remote_config_btn: Button = $VBoxContainer/ContextGroup/Dashboard/List/RemoteConfigButton

# Log Elements
@onready var log_output: TextEdit = $VBoxContainer/LogGroup/MarginContainer/VBoxContainer/LogOutput

# Dashboard button paths (used by flash_status / update_btn_status)
const INIT_PATH := "VBoxContainer/ContextGroup/Dashboard/List/InitializeButton"
const ANALYTICS_PATH := "VBoxContainer/ContextGroup/Dashboard/List/AnalyticsButton"
const CRASHLYTICS_PATH := "VBoxContainer/ContextGroup/Dashboard/List/CrashlyticsButton"
const MESSAGING_PATH := "VBoxContainer/ContextGroup/Dashboard/List/MessagingButton"
const REMOTE_CONFIG_PATH := "VBoxContainer/ContextGroup/Dashboard/List/RemoteConfigButton"

# Action Registry for Test Harness
var ACTIONS := {
	"Analytics": {
		"LogEventButton": {"method": "log_event", "args": ["test_event", {"p1": "v1", "p2": 123}], "signal": "analytics_event_logged", "desc": "Logging event: test_event"},
		"LogScreenButton": {"method": "log_screen_view", "args": ["MainScene", "GodotSampleActivity"], "signal": "analytics_screen_logged", "desc": "Logging screen: MainScene"},
		"UserPropsButton": {"method": "set_user_property", "args": ["test_prop", "test_value"], "signal": "analytics_property_set", "desc": "Setting user property: test_prop = test_value"},
		"SetUserIdButton": {"method": "set_user_id", "args": ["player_123"], "signal": "analytics_user_id_set", "desc": "Setting User ID: player_123"},
		"SetDefaultParamsButton": {"method": "set_default_event_parameters", "args": [ {"app_version": "1.0.0"}], "signal": "analytics_default_params_set", "desc": "Setting default params: app_version=1.0.0"},
		"SetConsentButton": {"method": "set_consent", "args": [ {"analytics_storage": false}], "signal": "analytics_consent_set", "desc": "Setting Consent: analytics_storage=false"},
		"SetCollectionEnabledButton": {"method": "set_collection_enabled", "args": [false], "signal": "analytics_collection_enabled_set", "desc": "Toggling Collection Enabled: false"},
		"ResetDataButton": {"method": "reset_analytics_data", "args": [], "signal": "analytics_data_reset", "desc": "Resetting Analytics Data"},
		"LogLevelStartButton": {"method": "log_level_start", "args": ["level_1"], "signal": "analytics_event_logged", "desc": "Logging level_start: level_1"},
		"LogLevelEndButton": {"method": "log_level_end", "args": ["level_1", true], "signal": "analytics_event_logged", "desc": "Logging level_end: level_1 (Success)"},
		"LogEarnButton": {"method": "log_earn_currency", "args": ["gold", 100.0], "signal": "analytics_event_logged", "desc": "Logging earn_currency: 100 gold"},
		"LogSpendButton": {"method": "log_spend_currency", "args": ["gold", 50.0, "sword"], "signal": "analytics_event_logged", "desc": "Logging spend_currency: 50 gold for sword"},
		"LogTutorialBeginButton": {"method": "log_tutorial_begin", "args": [], "signal": "analytics_event_logged", "desc": "Logging tutorial_begin"},
		"LogTutorialCompleteButton": {"method": "log_tutorial_complete", "args": [], "signal": "analytics_event_logged", "desc": "Logging tutorial_complete"},
		"LogPostScoreButton": {"method": "log_post_score", "args": [5000, "hall_of_fame", "ninja"], "signal": "analytics_event_logged", "desc": "Logging post_score: 5000"},
		"LogUnlockAchievementButton": {"method": "log_unlock_achievement", "args": ["master_of_gemini"], "signal": "analytics_event_logged", "desc": "Logging unlock_achievement: master_of_gemini"}
	},
	"Crashlytics": {
		"FatalButton": {"method": "crash", "args": [], "mode": "manual", "desc": "!!! FORCING FATAL CRASH !!!"},
		"NonFatalButton": {"method": "log_non_fatal_exception", "args": ["This is a test non-fatal error"], "signal": "crashlytics_non_fatal_logged", "desc": "Logging non-fatal error"},
		"CustomValueButton": {"method": "set_custom_value_string", "args": ["test_key", "test_value"], "signal": "crashlytics_value_set", "desc": "Setting custom value"}
	},
	"RemoteConfig": {
		"FetchButton": {"method": "fetch_and_activate", "args": [], "signal": "remote_config_fetch_completed", "desc": "Fetching and Activating..."},
		"GetStringButton": {
			"method": "get_string",
			"args": ["welcome_message", "DEFAULT"],
			"mode": "getter",
			"desc": "Getting 'welcome_message'",
			"validator": func(res): return typeof(res) == TYPE_STRING,
			"failure_log": "Expected String, but received invalid type"
		},
		"GetIntButton": {
			"method": "get_int",
			"args": ["min_version", -1],
			"mode": "getter",
			"desc": "Getting 'min_version'",
			"validator": func(res): return typeof(res) == TYPE_INT,
			"failure_log": "Expected Int, but received invalid type"
		},
		"GetFloatButton": {
			"method": "get_float",
			"args": ["drop_rate", 0.0],
			"mode": "getter",
			"desc": "Getting 'drop_rate'",
			"validator": func(res): return typeof(res) == TYPE_FLOAT,
			"failure_log": "Expected Float, but received invalid type"
		},
		"GetBoolButton": {
			"method": "get_bool",
			"args": ["feature_enabled", false],
			"mode": "getter",
			"desc": "Getting 'feature_enabled'",
			"validator": func(res): return typeof(res) == TYPE_INT and (res == 0 or res == 1),
			"failure_log": "Expected Int (1 or 0), but received invalid type"
		},
		"GetDictButton": {
			"method": "get_dictionary",
			"args": ["game_config"],
			"mode": "getter",
			"desc": "Getting 'game_config'",
			"validator": func(res): return typeof(res) == TYPE_DICTIONARY,
			"failure_log": "Expected Dictionary, but received invalid type"
		},
		"SetDefaultsButton": {"method": "set_defaults", "args": [ {"welcome_message": "Hello from Defaults!", "min_version": 10, "drop_rate": 0.05, "feature_enabled": true}], "signal": "remote_config_defaults_set", "desc": "Setting local defaults"},
		"SetIntervalButton": {"method": "set_minimum_fetch_interval", "args": [0.0], "signal": "remote_config_settings_updated", "desc": "Setting fetch interval to 0s (Dev Mode)"},
		"ListenerButton": {
			"method": "setup_realtime_updates",
			"args": [],
			"mode": "getter",
			"desc": "Enabling Real-time updates listener",
			"validator": func(res): return res == true or res == 1,
			"failure_log": "Failed to setup listener (method missing or returned false)"
		}
	},
	"Messaging": {
		"GetTokenButton": {"method": "get_token", "args": [], "signal": "messaging_token_received", "desc": "Requesting FCM token..."},
		"PermissionButton": {"method": "request_permission", "args": [], "signal": "messaging_permission_granted", "desc": "Requesting permissions..."},
		"SubscribeButton": {"method": "subscribe_to_topic", "args": ["test_topic"], "signal": "messaging_topic_subscribed", "desc": "Subscribing to: test_topic"},
		"UnsubscribeButton": {"method": "unsubscribe_from_topic", "args": ["test_topic"], "signal": "messaging_topic_unsubscribed", "desc": "Unsubscribing from: test_topic"},
		"GetLastNotificationButton": {
			"method": "get_last_notification",
			"args": [],
			"mode": "getter",
			"desc": "Getting last notification...",
			"validator": func(res): return typeof(res) == TYPE_DICTIONARY and not res.is_empty(),
			"failure_log": "No previous notification data found"
		}
	}
}

# Tracks the module-view button currently awaiting an async signal, per module.
# The harness only permits one in-flight call per module at a time.
var _pending_call: Dictionary = {
	"Analytics": "",
	"Crashlytics": "",
	"Messaging": "",
	"RemoteConfig": "",
}

var _fcm_token: String = ""
var _messaging_permission_granted: bool = false
var _apns_ready: bool = false

func _ready() -> void:
	get_viewport().size_changed.connect(_apply_safe_area)
	_apply_safe_area()
	log_message("=== Firebase Test Harness ===")
	show_dashboard()
	enable_service_buttons(false)
	initialize_firebase_plugins()

func _apply_safe_area() -> void:
	var os_name = OS.get_name()
	if os_name != "iOS" and os_name != "Android":
		return
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
			vbox.offset_bottom = - bottom_margin
			vbox.offset_left = left_margin
			vbox.offset_right = - right_margin

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
		
		# Connect all async signals to generic success handler with validation
		analytics.analytics_event_logged.connect(func(event_name):
			var success = not event_name.is_empty()
			if success: log_message("[Analytics] ✓ Event logged: " + event_name)
			else: log_message("[Analytics] ✗ Event log returned empty name")
			_clear_pending("Analytics", success))

		analytics.analytics_screen_logged.connect(func(screen_name):
			var success = not screen_name.is_empty()
			if success: log_message("[Analytics] ✓ Screen logged: " + screen_name)
			else: log_message("[Analytics] ✗ Screen log returned empty name")
			_clear_pending("Analytics", success))

		analytics.analytics_property_set.connect(func(prop_name):
			var success = not prop_name.is_empty()
			if success: log_message("[Analytics] ✓ Property set: " + prop_name)
			else: log_message("[Analytics] ✗ Property set returned empty name")
			_clear_pending("Analytics", success))

		analytics.analytics_user_id_set.connect(func(id):
			# Note: User ID could intentionally be empty if resetting
			log_message("[Analytics] ✓ User ID set: " + id); _clear_pending("Analytics", true))

		analytics.analytics_default_params_set.connect(func(): log_message("[Analytics] ✓ Default params set"); _clear_pending("Analytics"))
		analytics.analytics_collection_enabled_set.connect(func(enabled): log_message("[Analytics] ✓ Collection enabled: " + str(enabled)); _clear_pending("Analytics"))
		analytics.analytics_data_reset.connect(func(): log_message("[Analytics] ✓ Analytics data reset"); _clear_pending("Analytics"))
		analytics.analytics_consent_set.connect(func(): log_message("[Analytics] ✓ Consent updated"); _clear_pending("Analytics"))
		
		analytics.analytics_error.connect(_on_module_error.bind("Analytics"))
		log_message("✓ Firebase Analytics plugin found")
	else:
		log_message("✗ Firebase Analytics plugin not found")

	# Crashlytics
	if Engine.has_singleton("GodotxFirebaseCrashlytics"):
		crashlytics = Engine.get_singleton("GodotxFirebaseCrashlytics")
		crashlytics.crashlytics_initialized.connect(_on_module_init_done.bind("Crashlytics"))
		
		# Connect async signals
		crashlytics.crashlytics_non_fatal_logged.connect(func(msg): log_message("[Crashlytics] ✓ Non-fatal logged: " + msg); _clear_pending("Crashlytics"))
		crashlytics.crashlytics_message_logged.connect(func(msg): log_message("[Crashlytics] ✓ Message logged: " + msg); _clear_pending("Crashlytics"))
		crashlytics.crashlytics_value_set.connect(func(key): log_message("[Crashlytics] ✓ Value set for: " + key); _clear_pending("Crashlytics"))
		
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
		if OS.get_name() == "iOS":
			messaging.messaging_apn_token_received.connect(_on_messaging_apn_token_received)
		messaging.messaging_message_received.connect(_on_messaging_message_received)
		messaging.messaging_topic_subscribed.connect(_on_messaging_topic_subscribed)
		messaging.messaging_topic_unsubscribed.connect(_on_messaging_topic_unsubscribed)
		messaging.messaging_error.connect(_on_module_error.bind("Messaging"))
		log_message("✓ Firebase Messaging plugin found")
	else:
		log_message("✗ Firebase Messaging plugin not found")
	
	# Remote Config
	if Engine.has_singleton("GodotxFirebaseRemoteConfig"):
		remote_config = Engine.get_singleton("GodotxFirebaseRemoteConfig")
		remote_config.remote_config_initialized.connect(_on_module_init_done.bind("RemoteConfig"))
		
		# Connect async signals (with validation where needed)
		remote_config.remote_config_fetch_completed.connect(func(status):
			var _status_map = {0: "SUCCESS", 1: "CACHED", 2: "FAILURE", 3: "THROTTLED"}
			log_message("[Remote Config] Fetch result: " + _status_map.get(status, "UNKNOWN"))
			_clear_pending("RemoteConfig", status == 0 or status == 1)
		)
		remote_config.remote_config_defaults_set.connect(func(): _clear_pending("RemoteConfig"))
		remote_config.remote_config_settings_updated.connect(func(): _clear_pending("RemoteConfig"))
		remote_config.remote_config_updated.connect(_on_config_updated)
		
		remote_config.remote_config_error.connect(_on_module_error.bind("RemoteConfig"))
		log_message("✓ Firebase Remote Config plugin found")
	else:
		log_message("✗ Firebase Remote Config plugin not found")

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
	remote_config_btn.disabled = !enabled

func _module_btn_path(module_name: String, btn_name: String) -> String:
	var base_path = "VBoxContainer/ContextGroup/ModuleContainer/" + module_name.replace(" ", "") + "View/"
	if module_name in ["Remote Config", "RemoteConfig"]:
		return base_path + "List/" + btn_name
	elif module_name == "Analytics":
		return base_path + "ScrollContainer/List/" + btn_name
	return base_path + btn_name

func _connect_module_buttons(module_name: String, instance: Node) -> void:
	if module_name == "Analytics":
		var list = instance.get_node("ScrollContainer/List")
		for btn_name in ACTIONS["Analytics"].keys():
			_connect_btn(list, btn_name, _run_action.bind("Analytics", btn_name))
	elif module_name == "Messaging":
		for btn_name in ACTIONS["Messaging"].keys():
			_connect_btn(instance, btn_name, _run_action.bind("Messaging", btn_name))
		_update_messaging_view_state(instance)
	elif module_name == "Crashlytics":
		for btn_name in ACTIONS["Crashlytics"].keys():
			_connect_btn(instance, btn_name, _run_action.bind("Crashlytics", btn_name))
	elif module_name == "Remote Config":
		var list = instance.get_node("List")
		for btn_name in ACTIONS["RemoteConfig"].keys():
			_connect_btn(list, btn_name, _run_action.bind("RemoteConfig", btn_name))

func _connect_btn(instance: Node, btn_name: String, method: Callable) -> void:
	var btn = instance.get_node_or_null(btn_name)
	if btn: btn.pressed.connect(method)

# ============== ACTION RUNNER ==============

func _run_action(module_name: String, action_id: String) -> void:
	var log_name = "Remote Config" if module_name == "RemoteConfig" else module_name
	var config: Dictionary = ACTIONS.get(module_name, {}).get(action_id, {})
	if config.is_empty():
		log_message("[System] Error: No config for %s:%s" % [module_name, action_id])
		return

	var plugin = null
	match module_name:
		"Analytics": plugin = analytics
		"Crashlytics": plugin = crashlytics
		"Messaging": plugin = messaging
		"RemoteConfig": plugin = remote_config

	var btn_path = _module_btn_path(module_name, action_id)
	if not plugin:
		log_message("[%s] Plugin not available" % log_name)
		flash_status(btn_path, TestButton.Status.FAILURE)
		return

	log_message("\n[%s] %s" % [log_name, config.get("desc", "Running...")])
	flash_status(btn_path, TestButton.Status.PENDING)

	# Mark as pending for async signals
	if config.get("signal", "") != "":
		_pending_call[module_name] = btn_path

	# Execute the call
	var method = config["method"]
	var args = config.get("args", [])
	var result = plugin.callv(method, args)

	# If it's a getter, log the result and validate
	if config.get("mode", "") == "getter":
		var _key_prefix = "'%s' = " % args[0] if args.size() > 0 and typeof(args[0]) == TYPE_STRING else ""
		log_message("[%s] %s%s" % [log_name, _key_prefix, str(result)])
		var is_valid = true
		if config.has("validator"):
			is_valid = config["validator"].call(result)
		if not is_valid and config.has("failure_log"):
			log_message("[%s] ✗ %s" % [log_name, config["failure_log"]])
		flash_status(btn_path, TestButton.Status.SUCCESS if is_valid else TestButton.Status.FAILURE)

	# If it's a sync call (no signal and not manual mode), set success immediately
	if config.get("signal", "") == "" and config.get("mode", "") != "manual" and config.get("mode", "") != "getter":
		flash_status(btn_path, TestButton.Status.SUCCESS)

# ============== CORE ==============

func _on_initialize_pressed() -> void:
	if not core:
		log_message("[Core] Plugin not available")
		flash_status(INIT_PATH, TestButton.Status.FAILURE)
		return
	log_message("\n[Core] Initializing Firebase...")
	flash_status(INIT_PATH, TestButton.Status.PENDING)
	init_btn.disabled = true
	core.initialize()

func _on_core_initialized(success: bool) -> void:
	init_btn.disabled = false
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
		analytics.initialize()
	if crashlytics:
		log_message("[Crashlytics] Initializing...")
		crashlytics.initialize()
	if messaging:
		log_message("[Messaging] Initializing...")
		messaging.initialize()
	if remote_config:
		log_message("[Remote Config] Initializing...")
		remote_config.initialize()

func _on_module_init_done(success: bool, module_name: String) -> void:
	var module_btn: Button = null
	match module_name:
		"Analytics":
			module_btn = analytics_btn
		"Crashlytics":
			module_btn = crashlytics_btn
		"Messaging":
			module_btn = messaging_btn
		"RemoteConfig":
			module_btn = remote_config_btn

	if success:
		log_message("[%s] ✓ Initialized" % module_name)
		if module_btn: module_btn.disabled = false
	else:
		log_message("[%s] ✗ Initialization failed" % module_name)
		if module_btn: module_btn.disabled = true

# (Analytics Handlers removed - now using _run_action)

# (Messaging pressed handlers removed - now using _run_action)

func _on_messaging_permission_granted() -> void:
	log_message("[Messaging] ✓ Permission granted")
	_messaging_permission_granted = true
	_clear_pending("Messaging")

	var view = module_container.get_node_or_null("MessagingView")
	if view:
		_update_messaging_view_state(view)

func _on_messaging_permission_denied() -> void:
	log_message("[Messaging] ✗ Permission denied")
	var path: String = _pending_call.get("Messaging", "")
	if path != "":
		flash_status(path, TestButton.Status.FAILURE)
		_pending_call["Messaging"] = ""

func _on_messaging_topic_subscribed(topic: String) -> void:
	log_message("[Messaging] ✓ Subscribed to: " + topic)
	_clear_pending("Messaging")

func _on_messaging_topic_unsubscribed(topic: String) -> void:
	log_message("[Messaging] ✓ Unsubscribed from: " + topic)
	_clear_pending("Messaging")

func _on_messaging_token_received(token: String) -> void:
	if token.is_empty():
		log_message("[Messaging] ✗ Token received but it is EMPTY")
		_clear_pending("Messaging", false)
		return
		
	_fcm_token = token
	log_message("[Messaging] Token received: " + token)
	_clear_pending("Messaging", true)
	
	var view = module_container.get_node_or_null("MessagingView")
	if view:
		_update_messaging_view_state(view)

func _on_messaging_apn_token_received(_token: String) -> void:
	_apns_ready = true
	log_message("[Messaging] APNs Token received (Ready for FCM)")

func _update_messaging_view_state(view: Node) -> void:
	var has_token = !_fcm_token.is_empty()
	var permission_ok = _messaging_permission_granted
	
	var perm_btn = view.get_node_or_null("PermissionButton")
	var token_btn = view.get_node_or_null("GetTokenButton")
	var sub_btn = view.get_node_or_null("SubscribeButton")
	var unsub_btn = view.get_node_or_null("UnsubscribeButton")
	var last_notification_btn = view.get_node_or_null("GetLastNotificationButton")
	
	# Step 1: Permission button is always enabled
	if perm_btn: perm_btn.disabled = false

	# Step 2: Get Token only enabled after permission is granted
	if token_btn: token_btn.disabled = !permission_ok

	# Step 3: Topic operations and Get Last Notification only enabled after both permission and token are obtained
	if sub_btn: sub_btn.disabled = !(permission_ok and has_token)
	if unsub_btn: unsub_btn.disabled = !(permission_ok and has_token)
	if last_notification_btn: last_notification_btn.disabled = !(permission_ok and has_token)

func _on_messaging_message_received(title: String, body: String, data: Dictionary = {}) -> void:
	log_message("[Messaging] Message received: " + title + " — " + body)
	if not data.is_empty():
		log_message("[Messaging] Data payload: " + str(data))

func _on_get_last_notification_pressed() -> void:
	# Keep this as a separate handler if it needs complex return logic, 
	# but for now we've moved the basic call to _run_action.
	pass

# (Crashlytics Handlers removed - now using _run_action)

# ============== ERRORS ==============

func _on_error(message: String, module: String) -> void:
	log_message("[" + module + "] ✗ Error: " + message)

func _on_module_error(message: String, module_name: String) -> void:
	log_message("[%s] ✗ Error: %s" % [module_name, message])
	var path: String = _pending_call.get(module_name, "")
	if path != "":
		flash_status(path, TestButton.Status.FAILURE)
		_pending_call[module_name] = ""

func _clear_pending(module_name: String, success: bool = true) -> void:
	var path: String = _pending_call.get(module_name, "")
	if path != "":
		flash_status(path, TestButton.Status.SUCCESS if success else TestButton.Status.FAILURE)
		_pending_call[module_name] = ""

# ============== LOG CONTROLS ==============

func _on_clear_log_pressed() -> void:
	if log_output: log_output.text = ""
	log_message("=== Log Cleared ===")

func _on_copy_log_pressed() -> void:
	if log_output:
		DisplayServer.clipboard_set(log_output.text)
		log_message("[System] Log copied to clipboard")


# (Remote Config Handlers removed - now using _run_action)

func _on_config_updated(keys: Array) -> void:
	log_message("[Remote Config] 📡 Config updated: " + str(keys))
