#import "godotx_apn_delegate.h"
#include "godotx_firebase_messaging.h"

@implementation GodotxAPNDelegate

- (instancetype)init {
    self = [super init];
    if (self) {
        NSLog(@"[GodotxAPNDelegate] Initialized");
    }
    return self;
}

- (void)activateNotificationCenterDelegate {
    [UNUserNotificationCenter currentNotificationCenter].delegate = self;
    NSLog(@"[GodotxAPNDelegate] UNUserNotificationCenter delegate activated");
}

+ (instancetype)shared {
    static GodotxAPNDelegate *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[GodotxAPNDelegate alloc] init];
    });
    return sharedInstance;
}

// Helper: convert userInfo to Godot Dictionary, excluding APNs/FCM internal keys
static Dictionary userInfoToGodotDictionary(NSDictionary *userInfo) {
    Dictionary dict;
    NSSet *reservedKeys = [NSSet setWithArray:@[
        @"aps", @"gcm.message_id", @"google.c.a.e", @"google.c.fid",
        @"google.c.sender.id", @"gcm.notification.sound"
    ]];
    for (NSString *key in userInfo) {
        if ([reservedKeys containsObject:key]) continue;
        id val = userInfo[key];
        if ([val isKindOfClass:[NSString class]]) {
            dict[String::utf8([key UTF8String])] = String::utf8([(NSString*)val UTF8String]);
        } else if ([val isKindOfClass:[NSNumber class]]) {
            dict[String::utf8([key UTF8String])] = String::utf8([[val stringValue] UTF8String]);
        }
    }
    return dict;
}

#pragma mark - UNUserNotificationCenterDelegate

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {

    NSDictionary *userInfo = notification.request.content.userInfo;
    NSLog(@"[GodotxAPNDelegate] Received notification in foreground: %@", userInfo);
    self.lastNotificationInfo = userInfo;

    NSString *title = notification.request.content.title ?: @"";
    NSString *body = notification.request.content.body ?: @"";
    Dictionary data = userInfoToGodotDictionary(userInfo);

    dispatch_async(dispatch_get_main_queue(), ^{
        if (GodotxFirebaseMessaging::instance) {
            GodotxFirebaseMessaging::instance->emit_signal("messaging_message_received",
                String::utf8([title UTF8String]),
                String::utf8([body UTF8String]),
                data);
        }
    });

    if (@available(iOS 14.0, *)) {
        completionHandler(UNNotificationPresentationOptionBanner | UNNotificationPresentationOptionSound | UNNotificationPresentationOptionBadge);
    } else {
        completionHandler(UNNotificationPresentationOptionAlert | UNNotificationPresentationOptionSound | UNNotificationPresentationOptionBadge);
    }
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
didReceiveNotificationResponse:(UNNotificationResponse *)response
         withCompletionHandler:(void (^)(void))completionHandler {

    NSDictionary *userInfo = response.notification.request.content.userInfo;
    NSLog(@"[GodotxAPNDelegate] User tapped notification: %@", userInfo);
    self.lastNotificationInfo = userInfo;

    NSString *title = response.notification.request.content.title ?: @"";
    NSString *body = response.notification.request.content.body ?: @"";
    Dictionary data = userInfoToGodotDictionary(userInfo);

    dispatch_async(dispatch_get_main_queue(), ^{
        if (GodotxFirebaseMessaging::instance) {
            GodotxFirebaseMessaging::instance->emit_signal("messaging_message_received",
                String::utf8([title UTF8String]),
                String::utf8([body UTF8String]),
                data);
        }
    });

    completionHandler();
}

@end
