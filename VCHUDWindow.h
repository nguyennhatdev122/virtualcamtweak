#import <UIKit/UIKit.h>

@interface VCHUDWindow : UIWindow
+ (instancetype)shared;
- (void)show;
- (void)hide;
- (void)updatePreviewImage:(UIImage *)image;
@property (nonatomic, assign) BOOL isStreaming;
@end
