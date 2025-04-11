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
- (void)hideUIElements;
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
    
    // 查找所有匹配的视图并设置Alpha为1
    for (NSString *className in viewClassStrings) {
        Class viewClass = NSClassFromString(className);
        if (!viewClass) continue;
        
        // 使用辅助函数查找视图
        NSMutableArray *views = [NSMutableArray array];
        findViewsOfClassHelper(window, viewClass, views);
        
        for (UIView *view in views) {
            dispatch_async(dispatch_get_main_queue(), ^{
                view.alpha = 1.0;
            });
        }
    }
}

// HideUIButton 实现
@implementation HideUIButton
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // 基本设置
        self.backgroundColor = [UIColor clearColor]; // 透明背景，只显示图标
        self.layer.cornerRadius = frame.size.width / 2;
        self.layer.masksToBounds = YES;
        
        // 初始化属性
        _isElementsHidden = NO;
        _hiddenViewsList = [NSMutableArray array];
        
        // 加载按钮图标
        [self loadIcons];
        
        // 设置初始图标
        [self setImage:self.showIcon forState:UIControlStateNormal];
        
        // 添加拖动手势
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:panGesture];
        
        // 使用单击事件（原生按钮点击）
        [self addTarget:self action:@selector(handleTap) forControlEvents:UIControlEventTouchUpInside];
        
        // 添加长按手势
        UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        [self addGestureRecognizer:longPressGesture];
        
        // 设置自动半透明
        [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(fadeToTransparent) userInfo:nil repeats:NO];
    }
    return self;
}
- (void)fadeToTransparent {
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 0.5;
    }];
}
- (void)loadIcons {
    // 尝试从文件加载图标
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *iconPath = [documentsPath stringByAppendingPathComponent:@"Qingping.png"];
    UIImage *customIcon = [UIImage imageWithContentsOfFile:iconPath];
    
    if (customIcon) {
        self.showIcon = customIcon;
        self.hideIcon = customIcon;
    } else {
        // 如果文件不存在，使用默认文本
        [self setTitle:@"显示" forState:UIControlStateNormal];
        [self setTitle:@"隐藏" forState:UIControlStateSelected];
    }
}
- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    // 恢复完全不透明
    self.alpha = 1.0;
    
    CGPoint translation = [gesture translationInView:self.superview];
    CGPoint newCenter = CGPointMake(self.center.x + translation.x, self.center.y + translation.y);
    
    // 确保按钮不会超出屏幕边界
    newCenter.x = MAX(self.frame.size.width / 2, MIN(newCenter.x, self.superview.frame.size.width - self.frame.size.width / 2));
    newCenter.y = MAX(self.frame.size.height / 2, MIN(newCenter.y, self.superview.frame.size.height - self.frame.size.height / 2));
    
    self.center = newCenter;
    [gesture setTranslation:CGPointZero inView:self.superview];
    
    if (gesture.state == UIGestureRecognizerStateEnded) {
        // 保存按钮位置
        [[NSUserDefaults standardUserDefaults] setObject:NSStringFromCGPoint(self.center) forKey:@"HideUIButtonPosition"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        // 设置自动半透明
        [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(fadeToTransparent) userInfo:nil repeats:NO];
    }
}
- (void)handleTap {
    // 恢复完全不透明
    self.alpha = 1.0;
    
    if (isAppInTransition) {
        return;
    }
    
    if (!self.isElementsHidden) {
        // 隐藏UI元素
        [self hideUIElements];
        self.selected = YES;
    } else {
        // 直接强制恢复所有UI元素
        forceResetAllUIElements();
        self.isElementsHidden = NO;
        [self.hiddenViewsList removeAllObjects];
        self.selected = NO;
    }
    
    // 设置自动半透明
    [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(fadeToTransparent) userInfo:nil repeats:NO];
}
- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture {
    // 恢复完全不透明
    self.alpha = 1.0;
    
    if (gesture.state == UIGestureRecognizerStateBegan) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"设置" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
        [alertController addAction:[UIAlertAction actionWithTitle:@"全局生效" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"GlobalEffect"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }]];
        
        [alertController addAction:[UIAlertAction actionWithTitle:@"单个视频生效" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
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
    
    // 设置自动半透明
    [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(fadeToTransparent) userInfo:nil repeats:NO];
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
    
    // 隐藏元素
    [self.hiddenViewsList removeAllObjects]; // 清空隐藏列表
    [self findAndHideViews:viewClassStrings];
    self.isElementsHidden = YES;
}
- (void)findAndHideViews:(NSArray *)classNames {
    // 遍历所有窗口
    for (UIWindow *window in [UIApplication sharedApplication].windows) {
        for (NSString *className in classNames) {
            Class viewClass = NSClassFromString(className);
            if (!viewClass) continue;
            
            NSMutableArray *views = [NSMutableArray array];
            findViewsOfClassHelper(window, viewClass, views);
            
            for (UIView *view in views) {
                if ([view isKindOfClass:[UIView class]]) {
                    // 添加到隐藏视图列表
                    [self.hiddenViewsList addObject:view];
                    
                    // 设置新的alpha值
                    view.alpha = 0.0;
                }
            }
        }
    }
}
- (void)safeResetState {
    // 强制恢复所有UI元素
    forceResetAllUIElements();
    
    // 重置状态
    self.isElementsHidden = NO;
    [self.hiddenViewsList removeAllObjects];
    self.selected = NO;
}
@end
// 重新应用隐藏效果的函数
static void reapplyHidingToAllElements(HideUIButton *button) {
    if (!button || !button.isElementsHidden) return;
    
    // 先恢复所有元素
    forceResetAllUIElements();
    
    // 然后重新隐藏
    [button hideUIElements];
}
// 监控视图转换状态
%hook UIViewController
- (void)viewWillAppear:(BOOL)animated {
    %orig;
    isAppInTransition = YES;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        isAppInTransition = NO;
        
        // 视图出现后，如果按钮处于隐藏状态，重新应用隐藏效果
        // 这解决了视图复用导致的元素重新出现问题
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
            // 如果不是全局模式，在视图消失时重置状态
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
// 监听视频滑动切换事件
%hook AWEFeedContainerViewController
- (void)aweme:(id)arg1 currentIndexDidChange:(NSInteger)arg2 {
    %orig;
    
    // 视频切换时，如果按钮处于隐藏状态，重新应用隐藏效果
    if (hideButton && hideButton.isElementsHidden) {
        BOOL isGlobalEffect = [[NSUserDefaults standardUserDefaults] boolForKey:@"GlobalEffect"];
        
        if (isGlobalEffect) {
            // 如果是全局模式，则重新应用隐藏效果
            dispatch_async(dispatch_get_main_queue(), ^{
                reapplyHidingToAllElements(hideButton);
            });
        } else {
            // 如果是单视频模式，则重置状态
            dispatch_async(dispatch_get_main_queue(), ^{
                [hideButton safeResetState];
            });
        }
    }
}
%end
// Hook AppDelegate 来初始化按钮
%hook AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    BOOL result = %orig;
    
    // 检查是否启用了按钮功能
    BOOL isEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYEnableFloatClearButton"];
    
    if (isEnabled) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // 移除现有按钮（如果有）
            if (hideButton) {
                [hideButton removeFromSuperview];
                hideButton = nil;
            }
            
            // 创建新按钮
            hideButton = [[HideUIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
            
            // 从保存的位置恢复按钮位置，如果没有保存过，则放在屏幕右侧中心
            NSString *savedPositionString = [[NSUserDefaults standardUserDefaults] objectForKey:@"HideUIButtonPosition"];
            if (savedPositionString) {
                hideButton.center = CGPointFromString(savedPositionString);
            } else {
                CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
                CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
                hideButton.center = CGPointMake(screenWidth - 35, screenHeight / 2);
            }
            
            [getKeyWindow() addSubview:hideButton];
        });
    }
    
    return result;
}
%end
%ctor {
    // 注册信号处理
    signal(SIGSEGV, SIG_IGN);
}