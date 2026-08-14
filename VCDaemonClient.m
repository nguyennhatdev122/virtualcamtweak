#import "VCDaemonClient.h"
#import <CoreFoundation/CoreFoundation.h>

#define STATUS_FILE @"/tmp/virtualcam_active"
#define FRAME_FILE @"/tmp/virtualcam_frame.jpg"

@implementation VCDaemonClient {
    BOOL _isRunning;
}

+ (instancetype)shared {
    static VCDaemonClient *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[VCDaemonClient alloc] init];
    });
    return sharedInstance;
}

+ (BOOL)isActive {
    return [[NSFileManager defaultManager] fileExistsAtPath:STATUS_FILE];
}

static void newFrameCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    VCDaemonClient *client = (__bridge VCDaemonClient *)observer;
    [client handleNewFrame];
}

static void playCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    VCDaemonClient *client = (__bridge VCDaemonClient *)observer;
    if (client.onConnected) {
        client.onConnected();
    }
}

static void stopCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    VCDaemonClient *client = (__bridge VCDaemonClient *)observer;
    if (client.onDisconnected) {
        client.onDisconnected();
    }
}

- (void)start {
    if (_isRunning) return;
    _isRunning = YES;
    
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                    (__bridge const void *)(self),
                                    newFrameCallback,
                                    CFSTR("com.virtualcam.newframe"),
                                    NULL,
                                    CFNotificationSuspensionBehaviorDeliverImmediately);
                                    
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                    (__bridge const void *)(self),
                                    playCallback,
                                    CFSTR("com.virtualcam.play"),
                                    NULL,
                                    CFNotificationSuspensionBehaviorDeliverImmediately);
                                    
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                    (__bridge const void *)(self),
                                    stopCallback,
                                    CFSTR("com.virtualcam.stop"),
                                    NULL,
                                    CFNotificationSuspensionBehaviorDeliverImmediately);
                                    
    if ([VCDaemonClient isActive] && self.onConnected) {
        self.onConnected();
    }
}

- (void)stop {
    // Notify daemon to stop
    unlink([STATUS_FILE UTF8String]);
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.virtualcam.stop"), NULL, NULL, true);
    if (self.onDisconnected) {
        self.onDisconnected();
    }
}

- (void)handleNewFrame {
    if (self.onFrameReceived) {
        NSData *data = [NSData dataWithContentsOfFile:FRAME_FILE];
        if (data) {
            self.onFrameReceived(data);
        }
    }
}

- (void)dealloc {
    CFNotificationCenterRemoveEveryObserver(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge const void *)(self));
}

@end
