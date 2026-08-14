#import "VCHUDWindow.h"
#import "VCDaemonClient.h"

@interface VCHUDViewController : UIViewController
@property (nonatomic, strong) UIImageView *previewImageView;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIView *statusDot;
@end

@implementation VCHUDViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor clearColor];
    self.view.layer.cornerRadius = 20;
    self.view.clipsToBounds = YES;
    
    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blur];
    blurView.frame = self.view.bounds;
    blurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:blurView];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 15, self.view.bounds.size.width, 25)];
    titleLabel.text = @"VirtualCam";
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont boldSystemFontOfSize:18];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:titleLabel];
    
    self.statusDot = [[UIView alloc] initWithFrame:CGRectMake(50, 50, 10, 10)];
    self.statusDot.layer.cornerRadius = 5;
    self.statusDot.backgroundColor = [UIColor greenColor];
    [self.view addSubview:self.statusDot];
    
    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(65, 45, 100, 20)];
    self.statusLabel.text = @"LIVE";
    self.statusLabel.textColor = [UIColor whiteColor];
    self.statusLabel.font = [UIFont systemFontOfSize:14];
    [self.view addSubview:self.statusLabel];
    
    self.previewImageView = [[UIImageView alloc] initWithFrame:CGRectMake(20, 80, 180, 135)];
    self.previewImageView.backgroundColor = [UIColor blackColor];
    self.previewImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.previewImageView.layer.cornerRadius = 10;
    self.previewImageView.clipsToBounds = YES;
    [self.view addSubview:self.previewImageView];
    
    UIButton *stopBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    stopBtn.frame = CGRectMake(20, 230, 80, 35);
    [stopBtn setTitle:@"STOP" forState:UIControlStateNormal];
    [stopBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    stopBtn.backgroundColor = [UIColor systemRedColor];
    stopBtn.layer.cornerRadius = 8;
    [stopBtn addTarget:self action:@selector(stopAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:stopBtn];
    
    UIButton *hideBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    hideBtn.frame = CGRectMake(120, 230, 80, 35);
    [hideBtn setTitle:@"HIDE" forState:UIControlStateNormal];
    [hideBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    hideBtn.backgroundColor = [UIColor darkGrayColor];
    hideBtn.layer.cornerRadius = 8;
    [hideBtn addTarget:self action:@selector(hideAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:hideBtn];
}

- (void)stopAction {
    [[VCDaemonClient shared] stop];
    self.statusLabel.text = @"STOPPED";
    self.statusDot.backgroundColor = [UIColor redColor];
}

- (void)hideAction {
    [(VCHUDWindow *)self.view.window hide];
}
@end

@implementation VCHUDWindow {
    VCHUDViewController *_vc;
}

+ (instancetype)shared {
    static VCHUDWindow *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (@available(iOS 13.0, *)) {
            NSSet *scenes = [[UIApplication sharedApplication] connectedScenes];
            UIWindowScene *activeScene = nil;
            for (UIScene *scene in scenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive && [scene isKindOfClass:[UIWindowScene class]]) {
                    activeScene = (UIWindowScene *)scene;
                    break;
                }
            }
            if (activeScene) {
                sharedInstance = [[VCHUDWindow alloc] initWithWindowScene:activeScene];
            } else {
                sharedInstance = [[VCHUDWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
            }
        } else {
            sharedInstance = [[VCHUDWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        }
    });
    return sharedInstance;
}

- (instancetype)initWithFrame:(CGRect)frame {
    CGFloat w = 220;
    CGFloat h = 280;
    CGRect hudFrame = CGRectMake([UIScreen mainScreen].bounds.size.width + 10, 50, w, h);
    self = [super initWithFrame:hudFrame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithWindowScene:(UIWindowScene *)windowScene {
    CGFloat w = 220;
    CGFloat h = 280;
    CGRect hudFrame = CGRectMake([UIScreen mainScreen].bounds.size.width + 10, 50, w, h);
    self = [super initWithWindowScene:windowScene];
    if (self) {
        self.frame = hudFrame;
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    self.windowLevel = UIWindowLevelAlert + 100;
    self.backgroundColor = [UIColor clearColor];
    
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOffset = CGSizeMake(0, 5);
    self.layer.shadowOpacity = 0.5;
    self.layer.shadowRadius = 10;
    
    _vc = [[VCHUDViewController alloc] init];
    self.rootViewController = _vc;
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [self addGestureRecognizer:pan];
}

- (void)handlePan:(UIPanGestureRecognizer *)pan {
    CGPoint translation = [pan translationInView:self.superview];
    self.center = CGPointMake(self.center.x + translation.x, self.center.y + translation.y);
    [pan setTranslation:CGPointZero inView:self.superview];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    return CGRectContainsPoint(self.bounds, point);
}

- (void)show {
    self.hidden = NO;
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.frame = CGRectMake(screenBounds.size.width - self.frame.size.width - 20, 50, self.frame.size.width, self.frame.size.height);
    } completion:nil];
}

- (void)hide {
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    [UIView animateWithDuration:0.3 animations:^{
        self.frame = CGRectMake(screenBounds.size.width + 10, self.frame.origin.y, self.frame.size.width, self.frame.size.height);
    } completion:^(BOOL finished) {
        self.hidden = YES;
    }];
}

- (void)updatePreviewImage:(UIImage *)image {
    dispatch_async(dispatch_get_main_queue(), ^{
        _vc.previewImageView.image = image;
    });
}
@end
