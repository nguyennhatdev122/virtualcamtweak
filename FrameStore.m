#import "FrameStore.h"
#import <Accelerate/Accelerate.h>

@implementation FrameStore {
    NSData *_latestJPEGData;
    dispatch_semaphore_t _lock;
    CMSampleBufferRef _latestSampleBuffer;
}

+ (instancetype)shared {
    static FrameStore *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[FrameStore alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _lock = dispatch_semaphore_create(1);
        _latestJPEGData = nil;
        _latestSampleBuffer = NULL;
    }
    return self;
}

- (void)updateWithJPEGData:(NSData *)jpegData {
    if (!jpegData) return;
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    _latestJPEGData = [jpegData copy];
    
    if (_latestSampleBuffer) {
        CFRelease(_latestSampleBuffer);
        _latestSampleBuffer = NULL;
    }
    
    // Create new CMSampleBuffer from JPEG
    UIImage *image = [UIImage imageWithData:_latestJPEGData];
    if (image && image.CGImage) {
        CGImageRef cgImage = image.CGImage;
        size_t width = CGImageGetWidth(cgImage);
        size_t height = CGImageGetHeight(cgImage);
        
        NSDictionary *options = @{
            (id)kCVPixelBufferCGImageCompatibilityKey: @YES,
            (id)kCVPixelBufferCGBitmapContextCompatibilityKey: @YES
        };
        
        CVPixelBufferRef pixelBuffer = NULL;
        CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,
                                              width,
                                              height,
                                              kCVPixelFormatType_32ARGB,
                                              (__bridge CFDictionaryRef)options,
                                              &pixelBuffer);
        
        if (status == kCVReturnSuccess && pixelBuffer != NULL) {
            CVPixelBufferLockBaseAddress(pixelBuffer, 0);
            void *pxdata = CVPixelBufferGetBaseAddress(pixelBuffer);
            
            CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
            CGContextRef context = CGBitmapContextCreate(pxdata,
                                                         width,
                                                         height,
                                                         8,
                                                         CVPixelBufferGetBytesPerRow(pixelBuffer),
                                                         colorSpace,
                                                         (CGBitmapInfo)kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host);
            
            CGContextDrawImage(context, CGRectMake(0, 0, width, height), cgImage);
            
            CGColorSpaceRelease(colorSpace);
            CGContextRelease(context);
            CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
            
            CMVideoFormatDescriptionRef formatDesc = NULL;
            CMVideoFormatDescriptionCreateForImageBuffer(kCFAllocatorDefault, pixelBuffer, &formatDesc);
            
            CMSampleTimingInfo timingInfo;
            timingInfo.duration = kCMTimeInvalid;
            timingInfo.presentationTimeStamp = CMClockGetTime(CMClockGetHostTimeClock());
            timingInfo.decodeTimeStamp = kCMTimeInvalid;
            
            CMSampleBufferCreateReadyWithImageBuffer(kCFAllocatorDefault,
                                                     pixelBuffer,
                                                     formatDesc,
                                                     &timingInfo,
                                                     &_latestSampleBuffer);
            
            if (formatDesc) {
                CFRelease(formatDesc);
            }
            CVPixelBufferRelease(pixelBuffer);
        }
    }
    
    dispatch_semaphore_signal(_lock);
}

- (CMSampleBufferRef)latestSampleBuffer {
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    CMSampleBufferRef buf = NULL;
    if (_latestSampleBuffer) {
        buf = _latestSampleBuffer;
        CFRetain(buf); // Retain before returning
    }
    dispatch_semaphore_signal(_lock);
    return buf;
}

- (UIImage *)latestUIImage {
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    UIImage *img = nil;
    if (_latestJPEGData) {
        img = [UIImage imageWithData:_latestJPEGData];
    }
    dispatch_semaphore_signal(_lock);
    return img;
}

- (BOOL)hasFrames {
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    BOOL has = (_latestJPEGData != nil);
    dispatch_semaphore_signal(_lock);
    return has;
}

- (void)clear {
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    _latestJPEGData = nil;
    if (_latestSampleBuffer) {
        CFRelease(_latestSampleBuffer);
        _latestSampleBuffer = NULL;
    }
    dispatch_semaphore_signal(_lock);
}

@end
