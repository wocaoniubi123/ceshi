/* 
 * Tweak Name: 1KeyHideDYUI
 * Target App: com.ss.iphone.ugc.Aweme
 * Dev: @c00kiec00k 曲奇的坏品味🍻
 * iOS Version: 16.5
 */
#import "AwemeHeaders.h"
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <signal.h>
// 递归查找指定类型的视图的函数
static void findViewsOfClassHelper(UIView *view, Class viewClass, NSMutableArray *result) {
    if ([view isKindOfClass:viewClass]) {
        [result addObject:view];
    }
    
    for (UIView *subview in view.subviews) {
        findViewsOfClassHelper(subview, viewClass, result);
    }
}
// 定义悬浮按钮类
@interface HideUIButton : UIButton
@property (nonatomic, assign) BOOL isElementsHidden;
@property (nonatomic, strong) NSMutableArray *hiddenViewsList;
@property (nonatomic, strong) UIImage *showIcon;
@property (nonatomic, strong) UIImage *hideIcon;
@property (nonatomic, strong) NSTimer *checkTimer;
@end
// 全局变量
static HideUIButton *hideButton;
static BOOL isAppInTransition = NO;
// 获取keyWindow的辅助方法
static UIWindow* getKeyWindow() {
    UIWindow *keyWindow = nil;
    for (UIWindow *window in [UIApplication sharedApplication].windows) {
        if (window.isKeyWindow) {
            keyWindow = window;
            break;
        }
    }
    return keyWindow;
}
// 恢复所有元素到原始状态的方法 - 重置方法
static void forceResetAllUIElements() {
    UIWindow *window = getKeyWindow();
    if (!window) return;
    
    NSArray *viewClassStrings = @[
        @"AWEHPTopBarCTAContainer",
        @"AWEHPDiscoverFeedEntranceView",
        @"AWELeftSideBarEntranceView",
        @"DUXBadge",
        @"AWEBaseElementView",
        @"AWEElementStackView",
        @"AWEPlayInteractionDescriptionLabel",
        @"AWEUserNameLabel",
        @"AWEStoryProgressSlideView",
        @"AWEStoryProgressContainerView",
        @"ACCEditTagStickerView",
        @"AWEFeedTemplateAnchorView",
        @"AWESearchFeedTagView",
        @"AWEPlayInteractionSearchAnchorView",
        @"AFDRecommendToFriendTagView",
        @"AWELandscapeFeedEntryView",
        @"AWEFeedAnchorContainerView",
        @"AFDAIbumFolioView"
    ];
    
    for (NSString *className in viewClassStrings) {
        Class viewClass = NSClassFromString(className);
        if (!viewClass) continue;
        
        NSMutableArray *views = [NSMutableArray array];
        findViewsOfClassHelper(window, viewClass, views);
        
        for (UIView *view in views) {
            dispatch_async(dispatch_get_main_queue(), ^{
                view.alpha = 1.0;
            });
        }
    }
}
// 重新应用隐藏效果的函数
static void reapplyHidingToAllElements(HideUIButton *button) {
    if (!button || !button.isElementsHidden) return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [button hideUIElements];
        });
    });
}
@implementation HideUIButton
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.layer.cornerRadius = frame.size.width / 2;
        self.layer.masksToBounds = YES;
        
        _isElementsHidden = NO;
        _hiddenViewsList = [NSMutableArray array];
        
        [self loadIcons];
        [self setImage:self.showIcon forState:UIControlStateNormal];
        
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:panGesture];
        
        [self addTarget:self action:@selector(handleTap) forControlEvents:UIControlEventTouchUpInside];
        
        UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        [self addGestureRecognizer:longPressGesture];
        
        [self startPeriodicCheck];
    }
    return self;
}
- (void)startPeriodicCheck {
    // 停止现有的定时器
    [self.checkTimer invalidate];
    
    // 创建新的定时器
    self.checkTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 
                                                     repeats:YES 
                                                       block:^(NSTimer *timer) {
        if (self.isElementsHidden) {
            BOOL isGlobalEffect = [[NSUserDefaults standardUserDefaults] boolForKey:@"GlobalEffect"];
            if (isGlobalEffect) {
                reapplyHidingToAllElements(self);
            }
        }
    }];
}
- (void)loadIcons {
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *iconPath = [documentsPath stringByAppendingPathComponent:@"Qingping.png"];
    
    UIImage *customIcon = [UIImage imageWithContentsOfFile:iconPath];
    if (customIcon) {
        self.showIcon = customIcon;
        self.hideIcon = customIcon;
    } else {
        [self setTitle:@"显示" forState:UIControlStateNormal];
        [self setTitle:@"隐藏" forState:UIControlStateSelected];
    }
}
- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    CGPoint translation = [gesture translationInView:self.superview];
    CGPoint newCenter = CGPointMake(self.center.x + translation.x, self.center.y + translation.y);
    
    newCenter.x = MAX(self.frame.size.width / 2, MIN(newCenter.x, self.superview.frame.size.width - self.frame.size.width / 2));
    newCenter.y = MAX(self.frame.size.height / 2, MIN(newCenter.y, self.superview.frame.size.height - self.frame.size.height / 2));
    
    self.center = newCenter;
    [gesture setTranslation:CGPointZero inView:self.superview];
    
    if (gesture.state == UIGestureRecognizerStateEnded) {
        [[NSUserDefaults standardUserDefaults] setObject:NSStringFromCGPoint(self.center) forKey:@"HideUIButtonPosition"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}
- (void)handleTap {
    if (isAppInTransition) return;
    
    if (!self.isElementsHidden) {
        [self hideUIElements];
        self.selected = YES;
    } else {
        forceResetAllUIElements();
        self.isElementsHidden = NO;
        [self.hiddenViewsList removeAllObjects];
        self.selected = NO;
    }
}
- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"设置" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
        BOOL isGlobalEffect = [[NSUserDefaults standardUserDefaults] boolForKey:@"GlobalEffect"];
        
        [alertController addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:@"%@全局生效", isGlobalEffect ? @"✓ " : @""] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"GlobalEffect"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }]];
        
        [alertController addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:@"%@单个视频生效", !isGlobalEffect ? @"✓ " : @""] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"GlobalEffect"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }]];
        
        [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        
        UIViewController *topViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
        while (topViewController.presentedViewController) {
            topViewController = topViewController.presentedViewController;
        }
        [topViewController presentViewController:alertController animated:YES completion:nil];
    }
}
- (void)hideUIElements {
    NSArray *viewClassStrings = @[
        @"AWEHPTopBarCTAContainer",
        @"AWEHPDiscoverFeedEntranceView",
        @"AWELeftSideBarEntranceView",
        @"DUXBadge",
        @"AWEBaseElementView",
        @"AWEElementStackView",
        @"AWEPlayInteractionDescriptionLabel",
        @"AWEUserNameLabel",
        @"AWEStoryProgressSlideView",
        @"AWEStoryProgressContainerView",
        @"ACCEditTagStickerView",
        @"AWEFeedTemplateAnchorView",
        @"AWESearchFeedTagView",
        @"AWEPlayInteractionSearchAnchorView",
        @"AFDRecommendToFriendTagView",
        @"AWELandscapeFeedEntryView",
        @"AWEFeedAnchorContainerView",
        @"AFDAIbumFolioView"
    ];
    
    [self.hiddenViewsList removeAllObjects];
    [self findAndHideViews:viewClassStrings];
    self.isElementsHidden = YES;
}
- (void)findAndHideViews:(NSArray *)classNames {
    for (UIWindow *window in [UIApplication sharedApplication].windows) {
        for (NSString *className in classNames) {
            Class viewClass = NSClassFromString(className);
            if (!viewClass) continue;
            
            NSMutableArray *views = [NSMutableArray array];
            findViewsOfClassHelper(window, viewClass, views);
            
            for (UIView *view in views) {
                if ([view isKindOfClass:[UIView class]]) {
                    [self.hiddenViewsList addObject:view];
                    view.alpha = 0.0;
                }
            }
        }
    }
}
- (void)safeResetState {
    forceResetAllUIElements();
    self.isElementsHidden = NO;
    [self.hiddenViewsList removeAllObjects];
    self.selected = NO;
}
- (void)dealloc {
    [self.checkTimer invalidate];
    self.checkTimer = nil;
}
@end
// Hook 视频 Cell 的复用
%hook AWEFeedTableViewCell
- (void)prepareForReuse {
    %orig;
    if (hideButton && hideButton.isElementsHidden) {
        dispatch_async(dispatch_get_main_queue(), ^{
            reapplyHidingToAllElements(hideButton);
        });
    }
}
%end
// Hook 内容更新
%hook AWEFeedViewCell
- (void)setModel:(id)model {
    %orig;
    if (hideButton && hideButton.isElementsHidden) {
        dispatch_async(dispatch_get_main_queue(), ^{
            reapplyHidingToAllElements(hideButton);
        });
    }
}
%end
// Hook 视图控制器
%hook UIViewController
- (void)viewWillAppear:(BOOL)animated {
    %orig;
    isAppInTransition = YES;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        isAppInTransition = NO;
        if (hideButton && hideButton.isElementsHidden) {
            reapplyHidingToAllElements(hideButton);
        }
    });
}
- (void)viewWillDisappear:(BOOL)animated {
    %orig;
    isAppInTransition = YES;
    
    if (hideButton && hideButton.isElementsHidden) {
        BOOL isGlobalEffect = [[NSUserDefaults standardUserDefaults] boolForKey:@"GlobalEffect"];
        if (!isGlobalEffect) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [hideButton safeResetState];
            });
        }
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        isAppInTransition = NO;
    });
}
%end
// Hook 视频切换
%hook AWEFeedContainerViewController
- (void)aweme:(id)arg1 currentIndexDidChange:(NSInteger)arg2 {
    %orig;
    
    if (hideButton && hideButton.isElementsHidden) {
        BOOL isGlobalEffect = [[NSUserDefaults standardUserDefaults] boolForKey:@"GlobalEffect"];
        
        if (isGlobalEffect) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                reapplyHidingToAllElements(hideButton);
            });
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                reapplyHidingToAllElements(hideButton);
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [hideButton safeResetState];
            });
        }
    }
}
%end
// Hook AppDelegate
%hook AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    BOOL result = %orig;
    
    BOOL isEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYEnableFloatClearButton"];
    
    if (isEnabled) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (hideButton) {
                [hideButton removeFromSuperview];
                hideButton = nil;
            }
            
            hideButton = [[HideUIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
            
            NSString *savedPositionString = [[NSUserDefaults standardUserDefaults] objectForKey:@"HideUIButtonPosition"];
            if (savedPositionString) {
                hideButton.center = CGPointFromString(savedPositionString);
            } else {
                CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
                CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
                hideButton.center = CGPointMake(screenWidth - 35, screenHeight / 2);
            }
            
            if (![[NSUserDefaults standardUserDefaults] objectForKey:@"GlobalEffect"]) {
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"GlobalEffect"];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
            
            [getKeyWindow() addSubview:hideButton];
        });
    }
    
    return result;
}
%end
%ctor {
    signal(SIGSEGV, SIG_IGN);
}