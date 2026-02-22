#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

// ================= 配置区域 =================
static NSString * const kStorageKey = @"DB_BlockedKeywords";
static NSMutableArray *blockedKeywords = nil;

#define DEBUG_LOG 1

#if DEBUG_LOG
#define RLog(...) NSLog(@"[DomainBlocker] " __VA_ARGS__)
#else
#define RLog(...)
#endif

// ================= 辅助函数 =================

static void loadKeywords() {
    if (blockedKeywords) return;
    NSArray *saved = [[NSUserDefaults standardUserDefaults] objectForKey:kStorageKey];
    blockedKeywords = saved ? [saved mutableCopy] : [NSMutableArray array];
    RLog(@"✅ 加载 %lu 个关键词", (unsigned long)blockedKeywords.count);
}

static void saveKeywords() {
    [[NSUserDefaults standardUserDefaults] setObject:blockedKeywords forKey:kStorageKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    RLog(@"💾 保存关键词完成");
}

static BOOL shouldBlockURL(NSString *urlString) {
    if (!urlString || urlString.length == 0) return NO;
    NSString *lowerUrl = [urlString lowercaseString];
    for (NSString *keyword in blockedKeywords) {
        NSString *lowerKeyword = [keyword lowercaseString];
        if ([lowerUrl containsString:lowerKeyword]) {
            RLog(@"🚫 拦截请求：[%@] 命中规则：%@", urlString, keyword);
            return YES;
        }
    }
    return NO;
}

static UIViewController *getTopVC() {
    for (UIWindow *window in [UIApplication sharedApplication].windows) {
        if (window.isHidden) continue;
        if (window.rootViewController) {
            UIViewController *topVC = window.rootViewController;
            while (topVC.presentedViewController) {
                topVC = topVC.presentedViewController;
            }
            return topVC;
        }
    }
    return nil;
}

// ================= 美化版悬浮框 UI =================
@interface DBPopupViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>
@property (nonatomic, strong) UIView *popupContainer;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UITextField *inputField;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UILabel *listTitleLabel;
@end

@implementation DBPopupViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 半透明黑色背景
    UIView *bgView = [[UIView alloc] initWithFrame:self.view.bounds];
    bgView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    bgView.userInteractionEnabled = YES;
    [self.view addSubview:bgView];
    
    // 点击背景关闭
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeSettings)];
    [bgView addGestureRecognizer:tapGesture];
    
    // === 悬浮框容器（圆角）===
    CGFloat popupWidth = self.view.bounds.size.width * 0.85;
    CGFloat popupHeight = self.view.bounds.size.height * 0.5;
    CGFloat popupX = (self.view.bounds.size.width - popupWidth) / 2;
    // 屏幕中间位置（上 1/4 和下 1/4 之间）
    CGFloat popupY = self.view.bounds.size.height * 0.25;
    
    self.popupContainer = [[UIView alloc] initWithFrame:CGRectMake(popupX, popupY, popupWidth, popupHeight)];
    self.popupContainer.backgroundColor = [UIColor whiteColor];
    self.popupContainer.layer.cornerRadius = 20;
    self.popupContainer.layer.shadowColor = [UIColor blackColor].CGColor;
    self.popupContainer.layer.shadowOpacity = 0.3;
    self.popupContainer.layer.shadowOffset = CGSizeMake(0, 10);
    self.popupContainer.layer.shadowRadius = 20;
    self.popupContainer.userInteractionEnabled = YES;
    // 防止点击背景时关闭
    UITapGestureRecognizer *containerTap = [[UITapGestureRecognizer alloc] init];
    [self.popupContainer addGestureRecognizer:containerTap];
    [self.view addSubview:self.popupContainer];
    
    // === 标题栏 ===
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, popupWidth, 60)];
    headerView.backgroundColor = [UIColor whiteColor];
    headerView.layer.cornerRadius = 20;
    headerView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    [self.popupContainer addSubview:headerView];
    
    // 标题 "域名屏蔽器"
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, popupWidth - 100, 60)];
    self.titleLabel.text = @"🛡️ 域名屏蔽器";
    self.titleLabel.font = [UIFont boldSystemFontOfSize:20];
    self.titleLabel.textColor = [UIColor blackColor];
    [headerView addSubview:self.titleLabel];
    
    // 关闭按钮（右上角，灰色背景小框）
    self.closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.closeButton.frame = CGRectMake(popupWidth - 70, 10, 50, 40);
    [self.closeButton setTitle:@"完成" forState:UIControlStateNormal];
    self.closeButton.titleLabel.font = [UIFont systemFontOfSize:14];
    self.closeButton.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.3];
    [self.closeButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    self.closeButton.layer.cornerRadius = 8;
    [self.closeButton addTarget:self action:@selector(closeSettings) forControlEvents:UIControlEventTouchUpInside];
    [headerView addSubview:self.closeButton];
    
    // 分隔线
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 60, popupWidth, 0.5)];
    lineView.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.5];
    [self.popupContainer addSubview:lineView];
    
    // === 输入区域 ===
    UIView *inputContainer = [[UIView alloc] initWithFrame:CGRectMake(16, 70, popupWidth - 32, 90)];
    inputContainer.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.2];
    inputContainer.layer.cornerRadius = 12;
    [self.popupContainer addSubview:inputContainer];
    
    UILabel *inputLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 10, popupWidth - 64, 20)];
    inputLabel.text = @"添加屏蔽关键词";
    inputLabel.font = [UIFont boldSystemFontOfSize:13];
    inputLabel.textColor = [UIColor grayColor];
    [inputContainer addSubview:inputLabel];
    
    self.inputField = [[UITextField alloc] initWithFrame:CGRectMake(16, 35, popupWidth - 120, 40)];
    self.inputField.borderStyle = UITextBorderStyleNone;
    self.inputField.font = [UIFont systemFontOfSize:15];
    self.inputField.placeholder = @"例如：/ad/, tracker";
    self.inputField.textColor = [UIColor blackColor];
    self.inputField.delegate = self;
    [inputContainer addSubview:self.inputField];
    
    UIButton *addBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    addBtn.frame = CGRectMake(popupWidth - 100, 35, 84, 40);
    [addBtn setTitle:@"添加" forState:UIControlStateNormal];
    addBtn.titleLabel.font = [UIFont boldSystemFontOfSize:15];
    [addBtn setTitleColor:[UIColor systemBlueColor] forState:UIControlStateNormal];
    [addBtn addTarget:self action:@selector(saveKeyword) forControlEvents:UIControlEventTouchUpInside];
    [inputContainer addSubview:addBtn];
    
    // === 列表标题 ===
    self.listTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 165, popupWidth - 32, 25)];
    self.listTitleLabel.text = @"📋 已屏蔽域名的关键词";
    self.listTitleLabel.font = [UIFont boldSystemFontOfSize:14];
    self.listTitleLabel.textColor = [UIColor darkGrayColor];
    [self.popupContainer addSubview:self.listTitleLabel];
    
    // === 表格视图 ===
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(16, 195, popupWidth - 32, popupHeight - 215) style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.layer.cornerRadius = 10;
    self.tableView.clipsToBounds = YES;
    [self.popupContainer addSubview:self.tableView];
    
    // 空状态提示
    if (blockedKeywords.count == 0) {
        UILabel *emptyLabel = [[UILabel alloc] init];
        emptyLabel.text = @"暂无屏蔽关键词";
        emptyLabel.font = [UIFont italicSystemFontOfSize:13];
        emptyLabel.textColor = [UIColor lightGrayColor];
        emptyLabel.textAlignment = NSTextAlignmentCenter;
        emptyLabel.frame = self.tableView.bounds;
        self.tableView.backgroundView = emptyLabel;
    }
}

- (void)closeSettings {
    RLog(@"关闭设置 UI");
    [UIView animateWithDuration:0.3 animations:^{
        self.popupContainer.alpha = 0;
        self.popupContainer.transform = CGAffineTransformMakeScale(0.9, 0.9);
    } completion:^(BOOL finished) {
        [self.navigationController dismissViewControllerAnimated:NO completion:nil];
    }];
}

- (void)saveKeyword {
    NSString *text = self.inputField.text;
    if (text.length > 0 && ![blockedKeywords containsObject:text]) {
        [blockedKeywords addObject:text];
        saveKeywords();
        [self.inputField setText:@""];
        [self.inputField resignFirstResponder];
        [self.tableView reloadData];
        self.tableView.backgroundView = nil;
        
        // 成功提示（小 toast）
        UILabel *toast = [[UILabel alloc] init];
        toast.text = @"✅ 已添加";
        toast.font = [UIFont systemFontOfSize:13];
        toast.textColor = [UIColor whiteColor];
        toast.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
        toast.textAlignment = NSTextAlignmentCenter;
        toast.layer.cornerRadius = 8;
        toast.clipsToBounds = YES;
        toast.frame = CGRectMake(self.popupContainer.bounds.size.width/2 - 40, 50, 80, 30);
        [self.popupContainer addSubview:toast];
        
        [UIView animateWithDuration:1.0 animations:^{
            toast.alpha = 0;
        } completion:^(BOOL finished) {
            [toast removeFromSuperview];
        }];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self saveKeyword];
    return YES;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return blockedKeywords.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellID = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
        cell.backgroundColor = [UIColor whiteColor];
        cell.textLabel.font = [UIFont systemFontOfSize:14];
        
        // 圆角背景
        UIView *bgView = [[UIView alloc] init];
        bgView.backgroundColor = [[UIColor systemBlueColor] colorWithAlphaComponent:0.1];
        cell.selectedBackgroundView = bgView;
    }
    cell.textLabel.text = blockedKeywords[indexPath.row];
    cell.textLabel.textColor = [UIColor blackColor];
    cell.accessoryType = UITableViewCellAccessoryNone;
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [blockedKeywords removeObjectAtIndex:indexPath.row];
        saveKeywords();
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        if (blockedKeywords.count == 0) {
            UILabel *emptyLabel = [[UILabel alloc] init];
            emptyLabel.text = @"暂无屏蔽关键词";
            emptyLabel.font = [UIFont italicSystemFontOfSize:13];
            emptyLabel.textColor = [UIColor lightGrayColor];
            emptyLabel.textAlignment = NSTextAlignmentCenter;
            emptyLabel.frame = tableView.bounds;
            tableView.backgroundView = emptyLabel;
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 40;
}

@end

// ================= 手势处理 =================
@interface DBGestureHandler : NSObject
+ (void)handleTouches:(NSSet *)touches withEvent:(UIEvent *)event;
@end

@implementation DBGestureHandler

static NSTimer *g_longPressTimer = nil;
static NSInteger g_activeTouchesCount = 0;

+ (void)handleTouches:(NSSet *)touches withEvent:(UIEvent *)event {
    if (touches.count == 3) {
        g_activeTouchesCount = 3;
        if (g_longPressTimer) [g_longPressTimer invalidate];
        g_longPressTimer = [NSTimer scheduledTimerWithTimeInterval:0.6 target:self selector:@selector(triggerGesture) userInfo:nil repeats:NO];
    } else {
        if (g_longPressTimer) { [g_longPressTimer invalidate]; g_longPressTimer = nil; }
        g_activeTouchesCount = touches.count;
    }
}

+ (void)triggerGesture {
    RLog(@"👆 三指长按触发！");
    loadKeywords();
    
    DBPopupViewController *popupVC = [[DBPopupViewController alloc] init];
    popupVC.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    popupVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    UIViewController *topVC = getTopVC();
    if (topVC) {
        [topVC presentViewController:popupVC animated:YES completion:nil];
        RLog(@"✅ UI 已显示");
    }
}

@end

// ================= Hook 区域 =================
%group DomainBlockerHooks

%hook UIWindow
- (void)sendEvent:(UIEvent *)event {
    %orig;
    NSSet *touches = event.allTouches;
    if (touches && touches.count > 0) {
        [DBGestureHandler handleTouches:touches withEvent:event];
    }
}
%end

%hook NSURL
+ (instancetype)URLWithString:(NSString *)URLString {
    if (shouldBlockURL(URLString)) return nil;
    return %orig;
}
- (instancetype)initWithString:(NSString *)URLString {
    if (shouldBlockURL(URLString)) return nil;
    return %orig;
}
%end

%hook NSURLRequest
+ (instancetype)requestWithURL:(NSURL *)URL {
    if (shouldBlockURL(URL.absoluteString)) return nil;
    return %orig;
}
- (instancetype)initWithURL:(NSURL *)URL {
    if (shouldBlockURL(URL.absoluteString)) return nil;
    return %orig;
}
%end

%hook NSURLSession
- (NSURLSessionDataTask *)dataTaskWithURL:(NSURL *)url completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {
    if (shouldBlockURL(url.absoluteString)) {
        RLog(@"🚫 NSURLSession 拦截：%@", url.absoluteString);
        NSError *err = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorNotConnectedToInternet userInfo:@{NSLocalizedDescriptionKey: @"该域名已被屏蔽"}];
        if (completionHandler) completionHandler(nil, nil, err);
        return nil;
    }
    return %orig;
}
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {
    if (shouldBlockURL(request.URL.absoluteString)) {
        RLog(@"🚫 NSURLSession 拦截：%@", request.URL.absoluteString);
        NSError *err = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorNotConnectedToInternet userInfo:@{NSLocalizedDescriptionKey: @"该域名已被屏蔽"}];
        if (completionHandler) completionHandler(nil, nil, err);
        return nil;
    }
    return %orig;
}
%end

%end

%ctor {
    loadKeywords();
    RLog(@"🔌 插件已加载");
    %init(DomainBlockerHooks);
}
