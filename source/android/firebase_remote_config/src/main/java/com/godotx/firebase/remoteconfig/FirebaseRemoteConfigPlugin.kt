package com.godotx.firebase.remoteconfig

import android.util.Log
import com.google.firebase.FirebaseApp
import com.google.firebase.remoteconfig.ConfigUpdate
import com.google.firebase.remoteconfig.ConfigUpdateListener
import com.google.firebase.remoteconfig.FirebaseRemoteConfig
import com.google.firebase.remoteconfig.FirebaseRemoteConfigException
import com.google.firebase.remoteconfig.FirebaseRemoteConfigFetchThrottledException
import com.google.firebase.remoteconfig.FirebaseRemoteConfigSettings
import com.google.firebase.remoteconfig.ConfigUpdateListenerRegistration
import org.godotengine.godot.Dictionary
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.SignalInfo
import org.godotengine.godot.plugin.UsedByGodot
import org.json.JSONArray
import org.json.JSONObject

class FirebaseRemoteConfigPlugin(godot: Godot) : GodotPlugin(godot) {

    private val remoteConfig: FirebaseRemoteConfig by lazy {
        FirebaseRemoteConfig.getInstance()
    }

    private var listenerRegistration: ConfigUpdateListenerRegistration? = null

    companion object {
        private val TAG = FirebaseRemoteConfigPlugin::class.java.simpleName
        private const val FETCH_SUCCESS   = 0
        private const val FETCH_CACHED    = 1
        private const val FETCH_FAILURE   = 2
        private const val FETCH_THROTTLED = 3
    }

    init {
        Log.v(TAG, "Firebase Remote Config plugin loaded")
    }

    override fun getPluginName(): String {
        return "GodotxFirebaseRemoteConfig"
    }

    override fun getPluginSignals(): Set<SignalInfo> {
        return setOf(
            SignalInfo("remote_config_initialized", Boolean::class.javaObjectType),
            SignalInfo("fetch_completed", Int::class.javaObjectType),
            SignalInfo("config_updated", Array<String>::class.java)
        )
    }

    @UsedByGodot
    fun initialize() {
        val ctx = activity
        if (ctx == null) {
            Log.e(TAG, "initialize: activity is null")
            emitSignal("remote_config_initialized", false)
            return
        }

        if (FirebaseApp.getApps(ctx).isEmpty()) {
            Log.e(TAG, "Firebase is not initialized — call FirebaseCore.initialize() first")
            emitSignal("remote_config_initialized", false)
            return
        }

        setupRealtimeUpdates()
        Log.d(TAG, "Firebase Remote Config initialized")
        emitSignal("remote_config_initialized", true)
    }

    private fun setupRealtimeUpdates() {
        listenerRegistration = remoteConfig.addOnConfigUpdateListener(object : ConfigUpdateListener {
            override fun onUpdate(configUpdate: ConfigUpdate) {
                Log.d(TAG, "Config updated keys: " + configUpdate.updatedKeys)
                remoteConfig.activate().addOnCompleteListener { task ->
                    if (task.isSuccessful) {
                        val updatedKeysArray = configUpdate.updatedKeys.toTypedArray()
                        emitSignal("config_updated", updatedKeysArray as Any)
                    }
                }
            }

            override fun onError(error: FirebaseRemoteConfigException) {
                Log.e(TAG, "Config update error", error)
            }
        })
    }

    @UsedByGodot
    fun fetch_and_activate() {
        remoteConfig.fetchAndActivate().addOnCompleteListener { task ->
            if (task.isSuccessful) {
                val status = if (task.result) FETCH_SUCCESS else FETCH_CACHED
                emitSignal("fetch_completed", status)
            } else {
                val status = if (task.exception is FirebaseRemoteConfigFetchThrottledException)
                    FETCH_THROTTLED else FETCH_FAILURE
                emitSignal("fetch_completed", status)
            }
        }
    }

    @UsedByGodot
    fun get_string(key: String, defaultValue: String): String {
        val value = remoteConfig.getValue(key)
        return if (value.source == FirebaseRemoteConfig.VALUE_SOURCE_STATIC) defaultValue
               else value.asString()
    }

    @UsedByGodot
    fun get_int(key: String, defaultValue: Int): Int {
        val value = remoteConfig.getValue(key)
        return if (value.source == FirebaseRemoteConfig.VALUE_SOURCE_STATIC) defaultValue
               else value.asLong().toInt()
    }

    @UsedByGodot
    fun get_float(key: String, defaultValue: Float): Float {
        val value = remoteConfig.getValue(key)
        return if (value.source == FirebaseRemoteConfig.VALUE_SOURCE_STATIC) defaultValue
               else value.asDouble().toFloat()
    }

    @UsedByGodot
    fun get_bool(key: String, defaultValue: Boolean): Boolean {
        val value = remoteConfig.getValue(key)
        return if (value.source == FirebaseRemoteConfig.VALUE_SOURCE_STATIC) defaultValue
               else value.asBoolean()
    }

    @UsedByGodot
    fun get_dictionary(key: String): Dictionary {
        val value = remoteConfig.getValue(key)
        val dict = Dictionary()
        if (value.source == FirebaseRemoteConfig.VALUE_SOURCE_STATIC) return dict

        return try {
            jsonToDictionary(JSONObject(value.asString()))
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing JSON for key: $key", e)
            dict
        }
    }

    @UsedByGodot
    fun set_defaults(defaults: Dictionary) {
        val map = mutableMapOf<String, Any>()
        for (key in defaults.keys) {
            val value = defaults[key]
            if (value != null) map[key] = value
        }
        remoteConfig.setDefaultsAsync(map)
    }

    @UsedByGodot
    fun set_minimum_fetch_interval(seconds: Float) {
        val settings = FirebaseRemoteConfigSettings.Builder()
            .setMinimumFetchIntervalInSeconds(seconds.toLong())
            .build()
        remoteConfig.setConfigSettingsAsync(settings)
    }

    @UsedByGodot
    fun remove_config_update_listener() {
        listenerRegistration?.remove()
        listenerRegistration = null
        Log.d(TAG, "Config update listener removed")
    }

    private fun jsonToDictionary(json: JSONObject): Dictionary {
        val dict = Dictionary()
        val keys = json.keys()
        while (keys.hasNext()) {
            val key = keys.next()
            dict[key] = wrapValue(json.get(key))
        }
        return dict
    }

    private fun wrapValue(value: Any): Any? {
        return when (value) {
            is JSONObject -> jsonToDictionary(value)
            is JSONArray -> {
                val list = mutableListOf<Any?>()
                for (i in 0 until value.length()) list.add(wrapValue(value.get(i)))
                list.toTypedArray()
            }
            JSONObject.NULL -> null
            else -> value
        }
    }
}
