#import <Foundation/Foundation.h>

@interface VCDaemonClient : NSObject
+ (instancetype)shared;
+ (BOOL)isActive;
- (void)start;
- (void)stop;
@property (nonatomic, copy) void (^onFrameReceived)(NSData *jpegData);
@property (nonatomic, copy) void (^onConnected)(void);
@property (nonatomic, copy) void (^onDisconnected)(void);
@end
