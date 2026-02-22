#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

// --- 常量定义 ---
static NSString * const kStorageKey = @"DB_BlockedKeywords";

// --- 全局变量 ---
static NSMutableArray *blockedKeywords = nil;

// --- 辅助函数：加载保存的关键词 ---
static void loadKeywords() {
    if (blockedKeywords) return;
    NSArray *saved = [[NSUserDefaults standardUserDefaults] objectForKey:kStorageKey];
    if (saved) {
        blockedKeywords = [saved mutableCopy];
    } else {
        blockedKeywords = [NSMutableArray array];
    }
}

// --- 辅助函数：保存关键词 ---
static void saveKeywords() {
    [[NSUserDefaults standardUserDefaults] setObject:blockedKeywords forKey:kStorageKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

// --- 功能：检查 URL 是否被屏蔽 ---
static BOOL isUrlBlocked(NSURL *url) {
    if (!url || !url.host) return NO;
    NSString *host = url.host.lowercaseString;
    NSString *fullUrl = url.absoluteString.lowercaseString;
    
    for (NSString *keyword in blockedKeywords) {
        if (keyword.length == 0) continue;
        NSString *lowerKeyword = keyword.lowercaseString;
        if ([host containsString:lowerKeyword] || [fullUrl containsString:lowerKeyword]) {
            NSLog(@"[DomainBlocker] Blocked: %@", url.absoluteString);
            return YES;
        }
    }
    return NO;
}

// --- 辅助函数：获取顶层 ViewController ---
static UIViewController *getTopViewController() {
    UIViewController *topVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (topVC.presentedViewController) {
        topVC = topVC.presentedViewController;
    }
    return topVC;
}

// --- 辅助函数：显示提示 ---
static void showToast(NSString *message) {
    UIViewController *topVC = getTopViewController();
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"成功" 
                                                                   message:message 
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    
    [topVC presentViewController:alert animated:YES completion:nil];
}

// --- UI 部分：简洁美观的设置界面 ---
@interface DBSettingsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UITextField *inputField;
@end

@implementation DBSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.97 alpha:1.0];
    self.title = @"域名屏蔽器";
    
    self.navigationController.navigationBar.prefersLargeTitles = YES;
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];
    
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
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 130, self.view.bounds.size.width, self.view.bounds.size.height - 130) style:UITableViewStyleInsetGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.tableView];
    
    UILabel *footerLabel = [[UILabel alloc] init];
    footerLabel.text = @"左滑条目可删除";
    footerLabel.font = [UIFont italicSystemFontOfSize:12];
    footerLabel.textColor = [UIColor lightGrayColor];
    footerLabel.textAlignment = NSTextAlignmentCenter;
    self.tableView.tableFooterView = footerLabel;
}

- (void)saveKeyword {
    NSString *text = self.inputField.text;
    if (text.length > 0 && ![blockedKeywords containsObject:text]) {
        [blockedKeywords addObject:text];
        saveKeywords();
        [self.inputField setText:@""];
        [self.inputField resignFirstResponder];
        [self.tableView reloadData];
        
        showToast(@"关键词已保存");
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self saveKeyword];
    return YES;
}

#pragma mark - TableView Delegate & DataSource

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

// ============================================
// %group 定义 - 必须包裹 %hook 代码
// ============================================

// --- 手势识别逻辑 (SpringBoard) ---
%group SpringBoardHooks
%hook SpringBoard

static NSTimer *longPressTimer = nil;
static NSInteger activeTouchesCount = 0;

%new
- (void)db_handleThreeFingerLongPress:(UIGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        loadKeywords();
        
        DBSettingsViewController *settingsVC = [[DBSettingsViewController alloc] init];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:settingsVC];
        nav.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        nav.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
        
        UIViewController *topVC = getTopViewController();
        
        [topVC presentViewController:nav animated:YES completion:nil];
    }
}

%new
- (BOOL)db_isThreeFingerTouch:(NSSet<UITouch *> *)touches {
    return touches.count == 3;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    %orig;
    if ([self db_isThreeFingerTouch:touches]) {
        activeTouchesCount = 3;
        if (longPressTimer) [longPressTimer invalidate];
        longPressTimer = [NSTimer scheduledTimerWithTimeInterval:0.6 target:self selector:@selector(db_handleThreeFingerLongPress:) userInfo:nil repeats:NO];
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    %orig;
    if (activeTouchesCount != 3 || touches.count != 3) {
        if (longPressTimer) {
            [longPressTimer invalidate];
            longPressTimer = nil;
        }
        activeTouchesCount = touches.count;
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    %orig;
    if (longPressTimer) {
        [longPressTimer invalidate];
        longPressTimer = nil;
    }
    activeTouchesCount = touches.count;
}

%end
%end

// --- 网络拦截逻辑 ---
%group NSURLSessionHooks
%hook NSURLSession

- (NSURLSessionDataTask *)dataTaskWithURL:(NSURL *)url completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler {
    if (isUrlBlocked(url)) {
        NSError *blockError = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorNotConnectedToInternet userInfo:@{NSLocalizedDescriptionKey: @"该域名已被 DomainBlocker 屏蔽"}];
        if (completionHandler) completionHandler(nil, nil, blockError);
        return nil;
    }
    return %orig;
}

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler {
    if (isUrlBlocked(request.URL)) {
        NSError *blockError = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorNotConnectedToInternet userInfo:@{NSLocalizedDescriptionKey: @"该域名已被 DomainBlocker 屏蔽"}];
        if (completionHandler) completionHandler(nil, nil, blockError);
        return nil;
    }
    return %orig;
}

%end
%end

// ============================================
// 入口点 - 初始化 %group
// ============================================
%ctor {
    loadKeywords();
    
    // 始终启用网络拦截
    %init(NSURLSessionHooks);
    
    // 只在 SpringBoard 中启用手势
    if ([[[NSProcessInfo processInfo] processName] isEqualToString:@"SpringBoard"]) {
        %init(SpringBoardHooks);
    }
}
