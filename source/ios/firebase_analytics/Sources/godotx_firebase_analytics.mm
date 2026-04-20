#import "godotx_firebase_analytics.h"
#import <Foundation/Foundation.h>

@import FirebaseAnalytics;

#include "core/object/class_db.h"

GodotxFirebaseAnalytics* GodotxFirebaseAnalytics::instance = nullptr;

void GodotxFirebaseAnalytics::_bind_methods() {
    ClassDB::bind_method(D_METHOD("initialize"), &GodotxFirebaseAnalytics::initialize);
    ClassDB::bind_method(D_METHOD("log_event", "event_name", "params"), &GodotxFirebaseAnalytics::log_event);
    ClassDB::bind_method(D_METHOD("log_screen_view", "screen_name", "screen_class"), &GodotxFirebaseAnalytics::log_screen_view);
    ClassDB::bind_method(D_METHOD("set_user_property", "name", "value"), &GodotxFirebaseAnalytics::set_user_property);

    ADD_SIGNAL(MethodInfo("analytics_initialized", PropertyInfo(Variant::BOOL, "success")));
    ADD_SIGNAL(MethodInfo("analytics_event_logged", PropertyInfo(Variant::STRING, "event_name")));
    ADD_SIGNAL(MethodInfo("analytics_screen_logged", PropertyInfo(Variant::STRING, "screen_name")));
    ADD_SIGNAL(MethodInfo("analytics_property_set", PropertyInfo(Variant::STRING, "name")));
    ADD_SIGNAL(MethodInfo("analytics_error", PropertyInfo(Variant::STRING, "message")));
}

static NSDictionary* dictionary_to_nsdict(const Dictionary& dict) {
    NSMutableDictionary* nsDict = [NSMutableDictionary dictionary];
    Array keys = dict.keys();

    for (int i = 0; i < keys.size(); i++) {
        String key = keys[i];
        Variant value = dict[key];

        NSString* nsKey = [NSString stringWithUTF8String:key.utf8().get_data()];

        if (value.get_type() == Variant::STRING) {
            nsDict[nsKey] = [NSString stringWithUTF8String:String(value).utf8().get_data()];
        } else if (value.get_type() == Variant::INT) {
            nsDict[nsKey] = @((int64_t)value);
        } else if (value.get_type() == Variant::FLOAT) {
            nsDict[nsKey] = @((double)value);
        } else if (value.get_type() == Variant::BOOL) {
            // firebase analytics does NOT support boolean
            nsDict[nsKey] = @((bool)value ? 1 : 0);
        }
    }

    return nsDict;
}

GodotxFirebaseAnalytics* GodotxFirebaseAnalytics::get_singleton() {
    return instance;
}

void GodotxFirebaseAnalytics::initialize() {
    emit_signal("analytics_initialized", true);
}

void GodotxFirebaseAnalytics::log_screen_view(String screen_name, String screen_class) {
    NSLog(@"[GodotxFirebaseAnalytics] log_screen_view: %s (%s)", screen_name.utf8().get_data(), screen_class.utf8().get_data());

    @try {
        NSString* nsScreenName = [NSString stringWithUTF8String:screen_name.utf8().get_data()];
        NSString* nsScreenClass = [NSString stringWithUTF8String:screen_class.utf8().get_data()];

        [FIRAnalytics logEventWithName:kFIREventScreenView
                            parameters:@{
                                kFIRParameterScreenName: nsScreenName,
                                kFIRParameterScreenClass: nsScreenClass
                            }];

        emit_signal("analytics_screen_logged", screen_name);
    }
    @catch (NSException *exception) {
        NSLog(@"[GodotxFirebaseAnalytics] Failed to log screen view: %@", exception.reason);
        emit_signal("analytics_error", String::utf8([exception.reason UTF8String]));
    }
}

void GodotxFirebaseAnalytics::set_user_property(String name, String value) {
    NSLog(@"[GodotxFirebaseAnalytics] set_user_property: %s = %s", name.utf8().get_data(), value.utf8().get_data());

    @try {
        NSString* nsName = [NSString stringWithUTF8String:name.utf8().get_data()];
        NSString* nsValue = [NSString stringWithUTF8String:value.utf8().get_data()];

        [FIRAnalytics setUserPropertyString:nsValue forName:nsName];

        emit_signal("analytics_property_set", name);
    }
    @catch (NSException *exception) {
        NSLog(@"[GodotxFirebaseAnalytics] Failed to set user property: %@", exception.reason);
        emit_signal("analytics_error", String::utf8([exception.reason UTF8String]));
    }
}

void GodotxFirebaseAnalytics::log_event(String event_name, Dictionary params) {
    NSLog(@"[GodotxFirebaseAnalytics] log_event: %s", event_name.utf8().get_data());

    @try {
        NSString* nsEventName = [NSString stringWithUTF8String:event_name.utf8().get_data()];
        NSDictionary* nsParams = dictionary_to_nsdict(params);

        [FIRAnalytics logEventWithName:nsEventName parameters:nsParams];

        emit_signal("analytics_event_logged", event_name);
    }
    @catch (NSException *exception) {
        NSLog(@"[GodotxFirebaseAnalytics] Failed to log event: %@", exception.reason);
        emit_signal("analytics_error", String::utf8([exception.reason UTF8String]));
    }
}

GodotxFirebaseAnalytics::GodotxFirebaseAnalytics() {
    ERR_FAIL_COND(instance != NULL);
    instance = this;
    NSLog(@"[GodotxFirebaseAnalytics] Created");
}

GodotxFirebaseAnalytics::~GodotxFirebaseAnalytics() {
    if (instance == this) {
        instance = nullptr;
    }
}

