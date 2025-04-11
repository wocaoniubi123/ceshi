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
// 获取抖音文档目录
static NSString* getDYDocumentsPath() {
    NSArray *paths = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    return [paths.firstObject path];
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
        self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5]; // 半透明黑色背景
        self.layer.cornerRadius = frame.size.width / 2;
        self.layer.masksToBounds = YES;
        
        // 初始化属性
        _isElementsHidden = NO;
        _hiddenViewsList = [NSMutableArray array];
        
        // 从用户默认设置中读取全局模式状态
        _isGlobalMode = [[NSUserDefaults standardUserDefaults] boolForKey:globalModeKey];
        
        // 加载按钮图标
        [self loadIcons];
        
        // 添加拖动手势
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:panGesture];
        
        // 使用单击事件（原生按钮点击）
        [self addTarget:self action:@selector(handleTap) forControlEvents:UIControlEventTouchUpInside];
        
        // 添加长按手势
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        longPress.minimumPressDuration = 0.5; // 0.5秒长按
        [self addGestureRecognizer:longPress];
        
        // 从上次保存的位置恢复
        [self restoreLastPosition];
    }
    return self;
}
- (void)loadIcons {
    // 尝试从文档目录加载自定义图标
    NSString *customIconPath = [getDYDocumentsPath() stringByAppendingPathComponent:@"Qingping.png"];
    UIImage *customIcon = nil;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:customIconPath]) {
        customIcon = [UIImage imageWithContentsOfFile:customIconPath];
    }
    
    if (customIcon) {
        // 使用自定义图标
        [self setImage:customIcon forState:UIControlStateNormal];
        self.backgroundColor = [UIColor clearColor]; // 透明背景
    } else {
        // 没有自定义图标，使用文本
        self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5]; //self setTitle:self.isElementsHidden ? @"显示" : @"隐藏" forState:UIControlStateNormal];
        [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.titleLabel.font = [UIFont systemFontOfSize:12];
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
        self.center = CGPointMake(screenWidth - 30, screenHeight / 2);
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
    
    // 拖动结束时保存位置
    if (gesture.state == UIGestureRecognizerStateEnded) {
        [self saveLastPosition];
    }
}
- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        [self showMenu];
    }
}
- (void)showMenu {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"设置"
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    
    // 添加全局模式选项
    NSString *globalModeTitle = self.isGlobalMode ? @"切换到单视频模式" : @"切换到全局模式";
    UIAlertAction *globalModeAction = [UIAlertAction actionWithTitle:globalModeTitle
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction * _Nonnull action) {
        self.isGlobalMode = !self.isGlobalMode;
        [[NSUserDefaults standardUserDefaults] setBool:self.isGlobalMode forKey:globalModeKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }];
    [alertController addAction:globalModeAction];
    
    // 添加取消选项
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    [alertController addAction:cancelAction];
    
    // 显示菜单
    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    [rootViewController presentViewController:alertController animated:YES completion:nil];
}
- (void)handleTap {
    if (isAppInTransition) {
        return;
    }
    
    if (!self.isElementsHidden) {
        // 隐藏UI元素
        [self hideUIElements];
        [self updateButtonAppearance];
    } else {
        // 直接强制恢复所有UI元素
        forceResetAllUIElements();
        self.isElementsHidden = NO;
        [self.hiddenViewsList removeAllObjects];
        [self updateButtonAppearance];
    }
}
- (void)updateButtonAppearance {
    // 检查是否有自定义图标
    NSString *customIconPath = [getDYDocumentsPath() stringByAppendingPathComponent:@"Qingping.png"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:customIconPath]) {
        // 使用自定义图标，不需要更改
    } else {
        // 使用文本，需要更新
        [self setTitle:self.isElementsHidden ? @"显示" : @"隐藏" forState:UIControlStateNormal];
    }
}
- (void)hideUIElements {
    // 先强制结束所有已存在的视图，确保不会复用
    forceResetAllUIElements();
    
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
    [self updateButtonAppearance];
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
        // 如果是单视频模式，视图即将消失时重置状态
        dispatch_async(dispatch_get_main_queue(), ^{
            [hideButton safeResetState];
        });
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        isAppInTransition = NO;
    });
}
%end
// 监控视频滑动
%hook AWEFeedTableViewController
- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    %orig;
    
    // 如果是单视频模式，视频滑动时重置状态
    if (hideButton && hideButton.isElementsHidden && !hideButton.isGlobalMode) {
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
    
    // 检查是否启用功能
    BOOL isEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYEnableFloatClearButton"];
    
    if (isEnabled) {
        // 立即创建按钮，不延迟
        hideButton = [[HideUIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
        // 位置会在初始化时从上次保存的位置恢复
        
        UIWindow *keyWindow = getKeyWindow();
        if (keyWindow) {
            [keyWindow addSubview:hideButton];
        } else {
            // 如果keyWindow还没准备好，稍微延迟添加
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [getKeyWindow() addSubview:hideButton];
            });
        }
    }
    
    return result;
}
%end
%ctor {
    // 注册信号处理
    signal(SIGSEGV, SIG_IGN);
}