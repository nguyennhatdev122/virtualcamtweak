#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "FrameStore.h"
#import "VCHUDWindow.h"
#import "VCDaemonClient.h"

%group SpringBoard

%hook SpringBoard
- (void)applicationDidFinishLaunching:(id)application {
    %orig;
    [[VCDaemonClient shared] start];
    [VCDaemonClient shared].onConnected = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [[VCHUDWindow shared] show];
        });
    };
    [VCDaemonClient shared].onDisconnected = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [[VCHUDWindow shared] hide];
        });
    };
    [VCDaemonClient shared].onFrameReceived = ^(NSData *jpegData) {
        [[FrameStore shared] updateWithJPEGData:jpegData];
        UIImage *img = [[FrameStore shared] latestUIImage];
        if (img) {
            [[VCHUDWindow shared] updatePreviewImage:img];
        }
    };
}
%end

%end // group SpringBoard

%group AVFoundation

%hook NSObject
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if ([VCDaemonClient isActive] && [[FrameStore shared] hasFrames]) {
        CMSampleBufferRef fakeBuf = [[FrameStore shared] latestSampleBuffer];
        if (fakeBuf) {
            %orig(output, fakeBuf, connection);
            CFRelease(fakeBuf);
            return;
        }
    }
    %orig;
}
%end

%end // group AVFoundation

%ctor {
    NSString *processName = [NSProcessInfo processInfo].processName;
    if ([processName isEqualToString:@"SpringBoard"]) {
        %init(SpringBoard);
    }
    %init(AVFoundation);
}
