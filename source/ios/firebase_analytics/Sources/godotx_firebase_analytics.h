#ifndef GODOTX_FIREBASE_ANALYTICS_H
#define GODOTX_FIREBASE_ANALYTICS_H

#include "core/object/class_db.h"

class GodotxFirebaseAnalytics : public Object {
    GDCLASS(GodotxFirebaseAnalytics, Object);

private:
    static GodotxFirebaseAnalytics* instance;

protected:
    static void _bind_methods();

public:
    static GodotxFirebaseAnalytics* get_singleton();

    void initialize();
    void log_event(String event_name, Dictionary params);
    void log_screen_view(String screen_name, String screen_class);
    void set_user_property(String name, String value);

    GodotxFirebaseAnalytics();
    ~GodotxFirebaseAnalytics();
};

#endif // GODOTX_FIREBASE_ANALYTICS_H

