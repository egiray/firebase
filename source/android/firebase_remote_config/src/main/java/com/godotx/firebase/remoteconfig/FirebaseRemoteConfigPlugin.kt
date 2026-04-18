package com.godotx.firebase.remoteconfig

import android.util.Log
import com.google.firebase.remoteconfig.ConfigUpdate
import com.google.firebase.remoteconfig.ConfigUpdateListener
import com.google.firebase.remoteconfig.FirebaseRemoteConfig
import com.google.firebase.remoteconfig.FirebaseRemoteConfigException
import com.google.firebase.remoteconfig.FirebaseRemoteConfigFetchThrottledException
import com.google.firebase.remoteconfig.FirebaseRemoteConfigSettings
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

    companion object {
        private val TAG = FirebaseRemoteConfigPlugin::class.java.simpleName
        private const val FETCH_SUCCESS = 0
        private const val FETCH_FAILURE = 1
        private const val FETCH_THROTTLED = 2
    }

    init {
        Log.v(TAG, "Firebase Remote Config plugin loaded")
        setupRealtimeUpdates()
    }

    override fun getPluginName(): String {
        return "GodotxFirebaseRemoteConfig"
    }

    override fun getPluginSignals(): Set<SignalInfo> {
        return setOf(
            SignalInfo("fetch_completed", Int::class.javaObjectType),
            SignalInfo("config_updated", Array<String>::class.java)
        )
    }

    private fun setupRealtimeUpdates() {
        remoteConfig.addOnConfigUpdateListener(object : ConfigUpdateListener {
            override fun onUpdate(configUpdate: ConfigUpdate) {
                Log.d(TAG, "Config updated keys: " + configUpdate.updatedKeys)
                
                // Automatically activate on update to match iOS behavior
                remoteConfig.activate().addOnCompleteListener { task ->
                    if (task.isSuccessful) {
                        val updatedKeysArray = configUpdate.updatedKeys.toTypedArray()
                        emitSignal("config_updated", updatedKeysArray)
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
                emitSignal("fetch_completed", FETCH_SUCCESS)
            } else {
                val status = if (task.exception is FirebaseRemoteConfigFetchThrottledException)
                    FETCH_THROTTLED else FETCH_FAILURE
                emitSignal("fetch_completed", status)
            }
        }
    }

    @UsedByGodot
    fun get_string(key: String, defaultValue: String): String {
        val value = remoteConfig.getString(key)
        return if (value.isEmpty()) defaultValue else value
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
        val jsonStr = remoteConfig.getString(key)
        val dict = Dictionary()
        if (jsonStr.isEmpty()) return dict

        try {
            val jsonObject = JSONObject(jsonStr)
            return jsonToDictionary(jsonObject)
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing JSON for key: $key", e)
        }
        return dict
    }

    @UsedByGodot
    fun set_defaults(defaults: Dictionary) {
        val map = mutableMapOf<String, Any>()
        for (key in defaults.keys) {
            val value = defaults[key]
            if (value != null) {
                map[key] = value
            }
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

    // Helper to convert JSONObject to Godot Dictionary
    private fun jsonToDictionary(json: JSONObject): Dictionary {
        val dict = Dictionary()
        val keys = json.keys()
        while (keys.hasNext()) {
            val key = keys.next()
            val value = json.get(key)
            dict[key] = wrapValue(value)
        }
        return dict
    }

    private fun wrapValue(value: Any): Any? {
        return when (value) {
            is JSONObject -> jsonToDictionary(value)
            is JSONArray -> {
                val list = mutableListOf<Any?>()
                for (i in 0 until value.length()) {
                    list.add(wrapValue(value.get(i)))
                }
                list.toTypedArray()
            }
            JSONObject.NULL -> null
            else -> value
        }
    }
}
