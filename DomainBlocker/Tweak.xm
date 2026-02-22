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

// 统一的检查函数（参考您的核心逻辑）
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

// ================= UI 设置界面 =================
@interface DBSettingsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UITextField *inputField;
@end

@implementation DBSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.97 alpha:1.0];
    self.title = @"域名屏蔽器";
    
    // 右上角关闭按钮
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] 
        initWithTitle:@"完成" 
        style:UIBarButtonItemStyleDone 
        target:self 
        action:@selector(closeSettings)];
    
    self.navigationController.navigationBar.prefersLargeTitles = YES;
    self.navigationController.navigationBar.translucent = NO;
    
    // 输入区域
    UIView *inputContainer = [[UIView alloc] initWithFrame:CGRectMake(16, 20, self.view.bounds.size.width - 32, 100)];
    inputContainer.backgroundColor = [UIColor whiteColor];
    inputContainer.layer.cornerRadius = 12;
    inputContainer.layer.shadowColor = [UIColor blackColor].CGColor;
    inputContainer.layer.shadowOpacity = 0.05;
    inputContainer.layer.shadowOffset = CGSizeMake(0, 4);
    inputContainer.layer.shadowRadius = 8;
    [self.view addSubview:inputContainer];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(16, 16, inputContainer.bounds.size.width - 32, 20)];
    label.text = @"添加屏蔽关键词";
    label.font = [UIFont boldSystemFontOfSize:14];
    label.textColor = [UIColor grayColor];
    [inputContainer addSubview:label];
    
    self.inputField = [[UITextField alloc] initWithFrame:CGRectMake(16, 44, inputContainer.bounds.size.width - 110, 40)];
    self.inputField.borderStyle = UITextBorderStyleNone;
    self.inputField.font = [UIFont systemFontOfSize:16];
    self.inputField.placeholder = @"例如：/ad/, tracker";
    self.inputField.delegate = self;
    [inputContainer addSubview:self.inputField];
    
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(16, 84, inputContainer.bounds.size.width - 32, 0.5)];
    line.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    [inputContainer addSubview:line];
    
    UIButton *saveBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    saveBtn.frame = CGRectMake(inputContainer.bounds.size.width - 90, 44, 74, 40);
    [saveBtn setTitle:@"保存" forState:UIControlStateNormal];
    saveBtn.titleLabel.font = [UIFont boldSystemFontOfSize:15];
    [saveBtn setTitleColor:[UIColor systemBlueColor] forState:UIControlStateNormal];
    [saveBtn addTarget:self action:@selector(saveKeyword) forControlEvents:UIControlEventTouchUpInside];
    [inputContainer addSubview:saveBtn];
    
    // 表格视图
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 130, self.view.bounds.size.width, self.view.bounds.size.height - 130) style:UITableViewStyleInsetGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.tableView];
    
    // 底部关闭按钮
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    closeBtn.frame = CGRectMake(16, self.view.bounds.size.height - 80, self.view.bounds.size.width - 32, 50);
    [closeBtn setTitle:@"关闭设置" forState:UIControlStateNormal];
    closeBtn.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    closeBtn.backgroundColor = [UIColor systemRedColor];
    [closeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    closeBtn.layer.cornerRadius = 10;
    [closeBtn addTarget:self action:@selector(closeSettings) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:closeBtn];
    
    // 使用说明
    UILabel *infoLabel = [[UILabel alloc] init];
    infoLabel.text = @"💡 关键词会匹配 URL 的任何部分（域名、路径、参数）";
    infoLabel.font = [UIFont italicSystemFontOfSize:12];
    infoLabel.textColor = [UIColor grayColor];
    infoLabel.textAlignment = NSTextAlignmentCenter;
    infoLabel.numberOfLines = 0;
    infoLabel.frame = CGRectMake(16, self.view.bounds.size.height - 120, self.view.bounds.size.width - 32, 30);
    [self.view addSubview:infoLabel];
}

- (void)closeSettings {
    RLog(@"关闭设置 UI");
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)saveKeyword {
    NSString *text = self.inputField.text;
    if (text.length > 0 && ![blockedKeywords containsObject:text]) {
        [blockedKeywords addObject:text];
        saveKeywords();
        [self.inputField setText:@""];
        [self.inputField resignFirstResponder];
        [self.tableView reloadData];
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"成功" message:@"关键词已保存" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        [getTopVC() presentViewController:alert animated:YES completion:nil];
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
        cell.contentView.backgroundColor = [UIColor whiteColor];
        cell.textLabel.font = [UIFont systemFontOfSize:16];
    }
    cell.textLabel.text = blockedKeywords[indexPath.row];
    cell.textLabel.textColor = [UIColor blackColor];
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [blockedKeywords removeObjectAtIndex:indexPath.row];
        saveKeywords();
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
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
    
    DBSettingsViewController *settingsVC = [[DBSettingsViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:settingsVC];
    nav.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    nav.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
    
    UIViewController *topVC = getTopVC();
    if (topVC) {
        [topVC presentViewController:nav animated:YES completion:nil];
        RLog(@"✅ UI 已显示");
    }
}

@end

// ================= Hook 区域 =================
%group DomainBlockerHooks

// Hook UIWindow - 手势识别
%hook UIWindow
- (void)sendEvent:(UIEvent *)event {
    %orig;
    NSSet *touches = event.allTouches;
    if (touches && touches.count > 0) {
        [DBGestureHandler handleTouches:touches withEvent:event];
    }
}
%end

// ================= 核心拦截逻辑（参考您的代码）=================

// Hook 1: 拦截 URL 对象创建
%hook NSURL

+ (instancetype)URLWithString:(NSString *)URLString {
    if (shouldBlockURL(URLString)) {
        return nil;
    }
    return %orig;
}

- (instancetype)initWithString:(NSString *)URLString {
    if (shouldBlockURL(URLString)) {
        return nil;
    }
    return %orig;
}

%end

// Hook 2: 拦截 URLRequest
%hook NSURLRequest

+ (instancetype)requestWithURL:(NSURL *)URL {
    if (shouldBlockURL(URL.absoluteString)) {
        return nil;
    }
    return %orig;
}

- (instancetype)initWithURL:(NSURL *)URL {
    if (shouldBlockURL(URL.absoluteString)) {
        return nil;
    }
    return %orig;
}

%end

// Hook 3: 拦截 NSURLSession（额外保障）
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

// ================= 入口点 =================
%ctor {
    loadKeywords();
    RLog(@"🔌 插件已加载");
    %init(DomainBlockerHooks);
}
