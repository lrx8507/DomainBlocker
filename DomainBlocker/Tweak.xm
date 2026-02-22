#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

// ============================================
// SpringBoard 私有类声明
// ============================================
@interface SpringBoard : UIApplication
@end

// ============================================
// 全局变量和辅助函数
// ============================================
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

static BOOL isUrlBlocked(NSURL *url) {
    if (!url || !url.host) return NO;
    NSString *host = url.host.lowercaseString;
    for (NSString *keyword in blockedKeywords) {
        if (keyword.length == 0) continue;
        if ([host containsString:keyword.lowercaseString]) return YES;
    }
    return NO;
}

static UIViewController *getTopVC() {
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    if (!keyWindow) return nil;
    UIViewController *topVC = keyWindow.rootViewController;
    while (topVC.presentedViewController) {
        topVC = topVC.presentedViewController;
    }
    return topVC;
}

// ============================================
// 设置界面 UI
// ============================================
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

// ============================================
// 手势识别 - 使用 Class Hook 而非实例 Hook
// ============================================
%group SpringBoardHooks

// 使用全局变量存储 timer
static NSTimer *g_longPressTimer = nil;
static NSInteger g_activeTouchesCount = 0;

// 创建单独的类来处理手势逻辑
@interface SBTouchHandler : NSObject
+ (void)handleTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event inSpringBoard:(id)sb;
+ (void)handleTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event inSpringBoard:(id)sb;
+ (void)handleTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event inSpringBoard:(id)sb;
@end

@implementation SBTouchHandler

+ (void)handleTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event inSpringBoard:(id)sb {
    if (touches.count == 3) {
        g_activeTouchesCount = 3;
        if (g_longPressTimer) [g_longPressTimer invalidate];
        g_longPressTimer = [NSTimer scheduledTimerWithTimeInterval:0.6 target:self selector:@selector(triggerGesture) userInfo:nil repeats:NO];
    }
}

+ (void)triggerGesture {
    loadKeywords();
    DBSettingsViewController *settingsVC = [[DBSettingsViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:settingsVC];
    nav.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    nav.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
    [getTopVC() presentViewController:nav animated:YES completion:nil];
}

+ (void)handleTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event inSpringBoard:(id)sb {
    if (g_activeTouchesCount != 3 || touches.count != 3) {
        if (g_longPressTimer) { [g_longPressTimer invalidate]; g_longPressTimer = nil; }
        g_activeTouchesCount = touches.count;
    }
}

+ (void)handleTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event inSpringBoard:(id)sb {
    if (g_longPressTimer) { [g_longPressTimer invalidate]; g_longPressTimer = nil; }
    g_activeTouchesCount = touches.count;
}

@end

// Hook SpringBoard 的触摸方法
%hook SpringBoard

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    %orig;
    [SBTouchHandler handleTouchesBegan:touches withEvent:event inSpringBoard:self];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    %orig;
    [SBTouchHandler handleTouchesMoved:touches withEvent:event inSpringBoard:self];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    %orig;
    [SBTouchHandler handleTouchesEnded:touches withEvent:event inSpringBoard:self];
}

%end

%end

// ============================================
// 网络拦截
// ============================================
%group NSURLSessionHooks
%hook NSURLSession

- (NSURLSessionDataTask *)dataTaskWithURL:(NSURL *)url completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {
    if (isUrlBlocked(url)) {
        NSError *err = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorNotConnectedToInternet userInfo:@{NSLocalizedDescriptionKey: @"该域名已被屏蔽"}];
        if (completionHandler) completionHandler(nil, nil, err);
        return nil;
    }
    return %orig;
}

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {
    if (isUrlBlocked(request.URL)) {
        NSError *err = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorNotConnectedToInternet userInfo:@{NSLocalizedDescriptionKey: @"该域名已被屏蔽"}];
        if (completionHandler) completionHandler(nil, nil, err);
        return nil;
    }
    return %orig;
}

%end
%end

// ============================================
// 入口点
// ============================================
%ctor {
    loadKeywords();
    %init(NSURLSessionHooks);
    if ([[[NSProcessInfo processInfo] processName] isEqualToString:@"SpringBoard"]) {
        %init(SpringBoardHooks);
    }
}
