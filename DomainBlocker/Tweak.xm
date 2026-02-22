#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

static NSString * const kStorageKey = @"DB_BlockedKeywords";
static NSMutableArray *blockedKeywords = nil;

static void loadKeywords() {
    if (blockedKeywords) return;
    NSArray *saved = [[NSUserDefaults standardUserDefaults] objectForKey:kStorageKey];
    blockedKeywords = saved ? [saved mutableCopy] : [NSMutableArray array];
}

static void saveKeywords() {
    [[NSUserDefaults standardUserDefaults] setObject:blockedKeywords forKey:kStorageKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

// === 修复：更全面的 URL 匹配逻辑 ===
static BOOL isUrlBlocked(NSURL *url) {
    if (!url) return NO;
    
    NSString *absoluteString = url.absoluteString.lowercaseString;
    NSString *host = url.host ? url.host.lowercaseString : @"";
    NSString *path = url.path ? url.path.lowercaseString : @"";
    NSString *query = url.query ? url.query.lowercaseString : @"";
    
    NSLog(@"[DomainBlocker] Checking URL: %@", absoluteString);
    
    for (NSString *keyword in blockedKeywords) {
        if (keyword.length == 0) continue;
        NSString *lowerKeyword = keyword.lowercaseString;
        
        // 检查完整 URL、host、path、query
        if ([absoluteString containsString:lowerKeyword] ||
            [host containsString:lowerKeyword] ||
            [path containsString:lowerKeyword] ||
            [query containsString:lowerKeyword]) {
            NSLog(@"[DomainBlocker] BLOCKED: %@ (keyword: %@)", absoluteString, keyword);
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

// === UI 设置界面 ===
@interface DBSettingsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UITextField *inputField;
@property (nonatomic, strong) UIButton *closeButton;
@end

@implementation DBSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.97 alpha:1.0];
    self.title = @"域名屏蔽器";
    
    // === 添加关闭按钮（右上角）===
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
    self.inputField.placeholder = @"例如：ads, tracker";
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
    self.closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.closeButton.frame = CGRectMake(16, self.view.bounds.size.height - 80, self.view.bounds.size.width - 32, 50);
    [self.closeButton setTitle:@"关闭设置" forState:UIControlStateNormal];
    self.closeButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    self.closeButton.backgroundColor = [UIColor systemRedColor];
    [self.closeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.closeButton.layer.cornerRadius = 10;
    [self.closeButton addTarget:self action:@selector(closeSettings) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.closeButton];
    
    // 使用说明
    UILabel *infoLabel = [[UILabel alloc] init];
    infoLabel.text = @"💡 提示：关键词会匹配 URL 的任何部分（域名、路径、参数）";
    infoLabel.font = [UIFont italicSystemFontOfSize:12];
    infoLabel.textColor = [UIColor grayColor];
    infoLabel.textAlignment = NSTextAlignmentCenter;
    infoLabel.numberOfLines = 0;
    infoLabel.frame = CGRectMake(16, self.view.bounds.size.height - 120, self.view.bounds.size.width - 32, 30);
    [self.view addSubview:infoLabel];
}

- (void)closeSettings {
    NSLog(@"[DomainBlocker] Closing settings UI");
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

// === 手势处理类 ===
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
    NSLog(@"[DomainBlocker] Gesture triggered! Opening UI...");
    loadKeywords();
    NSLog(@"[DomainBlocker] Loaded %lu keywords", (unsigned long)blockedKeywords.count);
    
    DBSettingsViewController *settingsVC = [[DBSettingsViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:settingsVC];
    nav.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    nav.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
    
    UIViewController *topVC = getTopVC();
    if (topVC) {
        [topVC presentViewController:nav animated:YES completion:nil];
        NSLog(@"[DomainBlocker] UI presented successfully");
    } else {
        NSLog(@"[DomainBlocker] Failed to get top VC!");
    }
}

@end

// === 所有 Hook 放入同一个 group ===
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

// === 修复：更全面的网络拦截 ===
%hook NSURLSession
- (NSURLSessionDataTask *)dataTaskWithURL:(NSURL *)url completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {
    if (isUrlBlocked(url)) {
        NSError *err = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorNotConnectedToInternet userInfo:@{NSLocalizedDescriptionKey: @"该域名已被 DomainBlocker 屏蔽"}];
        if (completionHandler) completionHandler(nil, nil, err);
        return nil;
    }
    return %orig;
}

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {
    if (isUrlBlocked(request.URL)) {
        NSError *err = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorNotConnectedToInternet userInfo:@{NSLocalizedDescriptionKey: @"该域名已被 DomainBlocker 屏蔽"}];
        if (completionHandler) completionHandler(nil, nil, err);
        return nil;
    }
    return %orig;
}
%end

// === 额外 Hook：NSURLConnection (兼容旧 App) ===
%hook NSURLConnection
+ (instancetype)connectionWithRequest:(NSURLRequest *)request delegate:(id)delegate {
    if (isUrlBlocked(request.URL)) {
        NSLog(@"[DomainBlocker] Blocked NSURLConnection: %@", request.URL.absoluteString);
        return nil;
    }
    return %orig;
}
%end

%end

// === 入口点 ===
%ctor {
    loadKeywords();
    NSLog(@"[DomainBlocker] Plugin loaded, %lu keywords", (unsigned long)blockedKeywords.count);
    %init(DomainBlockerHooks);
}
