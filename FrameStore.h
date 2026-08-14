#import <UIKit/UIKit.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreVideo/CoreVideo.h>

@interface FrameStore : NSObject
+ (instancetype)shared;
- (void)updateWithJPEGData:(NSData *)jpegData;
- (CMSampleBufferRef)latestSampleBuffer; // Returns retained buffer, caller releases
- (UIImage *)latestUIImage;
- (BOOL)hasFrames;
- (void)clear;
@end
