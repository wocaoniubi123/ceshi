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
@property (nonatomic, strong) UIImage *buttonImage;
@property (nonatomic, assign) BOOL isGlobalMode; // 是否全局生效
@end
// 全局变量
static HideUIButton *hideButton;
static BOOL isAppInTransition = NO;
static NSString *lastButtonPositionKey = @"lastHideButtonPosition";
static NSString *globalModeKey = @"hideButtonGlobalMode";
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
// 获取抖音应用的文档目录
static NSString* getDouyinDocumentsPath() {
    NSArray *paths = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    return [paths.firstObject path];
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
        
        // 从UserDefaults加载全局模式设置
        _isGlobalMode = [[NSUserDefaults standardUserDefaults] boolForKey:globalModeKey];
        
        // 加载按钮图标
        [self loadCustomImage];
        
        // 添加拖动手势
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:panGesture];
        
        // 使用单击事件（原生按钮点击）
        [self addTarget:self action:@selector(handleTap) forControlEvents:UIControlEventTouchUpInside];
        
        // 添加长按手势
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        longPress.minimumPressDuration = 0.5;
        [self addGestureRecognizer:longPress];
        
        // 恢复上次位置
        [self restoreLastPosition];
    }
    return self;
}
- (void)loadCustomImage {
    // 尝试从Documents目录加载自定义图片
    NSString *documentsPath = getDouyinDocumentsPath();
    NSString *imagePath = [documentsPath stringByAppendingPathComponent:@"Qingping.png"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:imagePath]) {
        self.buttonImage = [UIImage imageWithContentsOfFile:imagePath];
        [self setImage:self.buttonImage forState:UIControlStateNormal];
    } else {
        // 如果没有自定义图片，使用文本
        [self setTitle:self.isElementsHidden ? @"显示" : @"隐藏" forState:UIControlStateNormal];
        [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    }
}
- (void)saveLastPosition {
    CGPoint center = self.center;
    NSDictionary *positionDict = @{
        @"x": @(center.x),
        @"y": @(center.y)
    };
    [[NSUserDefaults standardUserDefaults] setObject:positionDict forKey:lastButtonPositionKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
- (void)restoreLastPosition {
    NSDictionary *positionDict = [[NSUserDefaults standardUserDefaults] objectForKey:lastButtonPositionKey];
    if (positionDict) {
        CGFloat x = [positionDict[@"x"] floatValue];
        CGFloat y = [positionDict[@"y"] floatValue];
        self.center = CGPointMake(x, y);
    } else {
        // 默认位置：屏幕右侧中心
        CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
        CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
        self.center = CGPointMake(screenWidth - 35, screenHeight / 2);
    }
}
- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    CGPoint translation = [gesture translationInView:self.superview];
    CGPoint newCenter = CGPointMake(self.center.x + translation.x, self.center.y + translation.y);
    
    // 确保按钮不会超出屏幕边界
    newCenter.x = MAX(self.frame.size.width / 2, MIN(newCenter.x, self.superview.frame.size.width - self.frame.size.width / 2));
    newCenter.y = MAX(self.frame.size.height / 2, MIN(newCenter.y, self.superview.frame.size.height - self.frame.size.height / 2));
    
    self.center = newCenter;
    [gesture setTranslation:CGPointZero inView:self.superview];
    
    if (gesture.state == UIGestureRecognizerStateEnded) {
        [self saveLastPosition];
    }
}
- (void)handleTap {
    if (isAppInTransition) {
        return;
    }
    
    if (!self.isElementsHidden) {
        // 隐藏UI元素
        [self hideUIElements];
        if (!self.buttonImage) {
            [self setTitle:@"显示" forState:UIControlStateNormal];
        }
    } else {
        // 直接强制恢复所有UI元素
        forceResetAllUIElements();
        self.isElementsHidden = NO;
        [self.hiddenViewsList removeAllObjects];
        if (!self.buttonImage) {
            [self setTitle:@"隐藏" forState:UIControlStateNormal];
        }
    }
}
- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        [self showOptionsMenu];
    }
}
- (void)showOptionsMenu {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"设置"
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    
    // 切换全局/单视频模式
    NSString *modeTitle = self.isGlobalMode ? @"切换到单视频模式" : @"切换到全局模式";
    UIAlertAction *toggleModeAction = [UIAlertAction actionWithTitle:modeTitle
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction * _Nonnull action) {
        self.isGlobalMode = !self.isGlobalMode;
        [[NSUserDefaults standardUserDefaults] setBool:self.isGlobalMode forKey:globalModeKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    
    [alertController addAction:toggleModeAction];
    [alertController addAction:cancelAction];
    
    // 获取当前的UIViewController
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    
    // 在iPad上需要设置弹出位置
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        alertController.popoverPresentationController.sourceView = self;
        alertController.popoverPresentationController.sourceRect = self.bounds;
    }
    
    [topController presentViewController:alertController animated:YES completion:nil];
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
    if (!self.buttonImage) {
        [self setTitle:@"隐藏" forState:UIControlStateNormal];
    }
}
@end
// 监控视图转换状态
%hook UIViewController
- (void)viewWillAppear:(BOOL)animated {
    %orig;
    isAppInTransition = YES;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        isAppInTransition = NO;
    });
}
- (void)viewWillDisappear:(BOOL)animated {
    %orig;
    isAppInTransition = YES;
    
    if (hideButton && hideButton.isElementsHidden && !hideButton.isGlobalMode) {
        // 如果视图即将消失，且不是全局模式，重置状态
        dispatch_async(dispatch_get_main_queue(), ^{
            [hideButton safeResetState];
        });
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
    
    if (hideButton && hideButton.isElementsHidden && !hideButton.isGlobalMode) {
        // 如果不是全局模式，在视频切换时恢复UI
        dispatch_async(dispatch_get_main_queue(), ^{
            [hideButton safeResetState];
        });
    }
}
%end
// Hook AppDelegate 来初始化按钮
%hook AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    BOOL result = %orig;
    
    // 立即创建按钮，不延迟
    dispatch_async(dispatch_get_main_queue(), ^{
        CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
        CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
        
        // 检查是否已经存在按钮
        if (hideButton) {
            [hideButton removeFromSuperview];
            hideButton = nil;
        }
        
        hideButton = [[HideUIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
        
        [getKeyWindow() addSubview:hideButton];
    });
    
    return result;
}
%end
%ctor {
    // 注册信号处理
    signal(SIGSEGV, SIG_IGN);
}