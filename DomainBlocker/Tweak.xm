#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

// ================= 配置区域 =================
static NSString * const kStorageKey = @"DB_BlockedKeywords";
static NSMutableArray *blockedKeywords = nil;
static NSMutableArray *blockLogs = nil;

#define DEBUG_LOG 1
#define MAX_LOG_COUNT 50

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
    
    if (!blockLogs) {
        blockLogs = [NSMutableArray array];
    }
    
    RLog(@"加载 %lu 个关键词", (unsigned long)blockedKeywords.count);
}

static void saveKeywords() {
    [[NSUserDefaults standardUserDefaults] setObject:blockedKeywords forKey:kStorageKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    RLog(@"关键词已保存");
}

static void addLogEntry(NSString *url, NSString *keyword) {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"HH:mm:ss";
    NSString *timeStr = [formatter stringFromDate:[NSDate date]];
    
    NSString *logEntry = [NSString stringWithFormat:@"%@ [拦截] %@ (命中:%@)", timeStr, url, keyword];
    [blockLogs addObject:logEntry];
    
    while (blockLogs.count > MAX_LOG_COUNT) {
        [blockLogs removeObjectAtIndex:0];
    }
    
    RLog(@"记录日志：%@", logEntry);
}

static BOOL shouldBlockURL(NSString *urlString) {
    if (!urlString || urlString.length == 0) return NO;
    NSString *lowerUrl = [urlString lowercaseString];
    for (NSString *keyword in blockedKeywords) {
        NSString *lowerKeyword = [keyword lowercaseString];
        if ([lowerUrl containsString:lowerKeyword]) {
            RLog(@"拦截请求：[%@] 命中规则：%@", urlString, keyword);
            addLogEntry(urlString, keyword);
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

// ================= UI =================
@interface DBPopupViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>
@property (nonatomic, strong) UIView *popupContainer;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UITextField *inputField;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UILabel *listTitleLabel;
@property (nonatomic, strong) UITextView *logTextView;
@end

@implementation DBPopupViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIView *bgView = [[UIView alloc] initWithFrame:self.view.bounds];
    bgView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    [self.view addSubview:bgView];
    UITapGestureRecognizer *bgTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeSettings)];
    [bgView addGestureRecognizer:bgTap];
    
    CGFloat popupWidth = self.view.bounds.size.width * 0.85;
    CGFloat popupHeight = self.view.bounds.size.height * 0.55;
    CGFloat popupX = (self.view.bounds.size.width - popupWidth) / 2;
    CGFloat popupY = self.view.bounds.size.height * 0.22;
    
    self.popupContainer = [[UIView alloc] initWithFrame:CGRectMake(popupX, popupY, popupWidth, popupHeight)];
    self.popupContainer.backgroundColor = [UIColor whiteColor];
    self.popupContainer.layer.cornerRadius = 20;
    self.popupContainer.layer.shadowColor = [UIColor blackColor].CGColor;
    self.popupContainer.layer.shadowOpacity = 0.3;
    self.popupContainer.layer.shadowOffset = CGSizeMake(0, 10);
    self.popupContainer.layer.shadowRadius = 20;
    self.popupContainer.userInteractionEnabled = YES;
    [self.view addSubview:self.popupContainer];
    
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, popupWidth, 50)];
    headerView.backgroundColor = [UIColor whiteColor];
    headerView.layer.cornerRadius = 20;
    headerView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    [self.popupContainer addSubview:headerView];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, popupWidth - 100, 50)];
    titleLabel.text = @"域名屏蔽器";
    titleLabel.font = [UIFont boldSystemFontOfSize:18];
    titleLabel.textColor = [UIColor blackColor];
    [headerView addSubview:titleLabel];
    
    self.closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.closeButton.frame = CGRectMake(popupWidth - 65, 7, 50, 36);
    [self.closeButton setTitle:@"完成" forState:UIControlStateNormal];
    self.closeButton.titleLabel.font = [UIFont systemFontOfSize:13];
    self.closeButton.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.3];
    [self.closeButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    self.closeButton.layer.cornerRadius = 8;
    [self.closeButton addTarget:self action:@selector(closeSettings) forControlEvents:UIControlEventTouchUpInside];
    [headerView addSubview:self.closeButton];
    
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 50, popupWidth, 0.5)];
    lineView.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.5];
    [self.popupContainer addSubview:lineView];
    
    CGFloat inputY = 58;
    CGFloat inputHeight = 50;
    UIView *inputContainer = [[UIView alloc] initWithFrame:CGRectMake(20, inputY, popupWidth - 40, inputHeight)];
    [self.popupContainer addSubview:inputContainer];
    
    self.inputField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, popupWidth - 90, inputHeight)];
    self.inputField.borderStyle = UITextBorderStyleNone;
    self.inputField.font = [UIFont systemFontOfSize:15];
    self.inputField.placeholder = @"添加屏蔽关键词";
    self.inputField.textColor = [UIColor blackColor];
    self.inputField.delegate = self;
    [inputContainer addSubview:self.inputField];
    
    UIView *underline = [[UIView alloc] initWithFrame:CGRectMake(0, inputHeight - 1, popupWidth - 90, 1)];
    underline.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.6];
    [inputContainer addSubview:underline];
    
    UIButton *addBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    addBtn.frame = CGRectMake(popupWidth - 80, 0, 70, inputHeight);
    [addBtn setTitle:@"添加" forState:UIControlStateNormal];
    addBtn.titleLabel.font = [UIFont boldSystemFontOfSize:15];
    [addBtn setTitleColor:[UIColor systemBlueColor] forState:UIControlStateNormal];
    [addBtn addTarget:self action:@selector(saveKeyword) forControlEvents:UIControlEventTouchUpInside];
    [inputContainer addSubview:addBtn];
    
    CGFloat listTitleY = inputY + inputHeight + 10;
    self.listTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, listTitleY, popupWidth - 40, 20)];
    self.listTitleLabel.text = @"已屏蔽域名的关键词";
    self.listTitleLabel.font = [UIFont boldSystemFontOfSize:13];
    self.listTitleLabel.textColor = [UIColor darkGrayColor];
    [self.popupContainer addSubview:self.listTitleLabel];
    
    CGFloat tableY = listTitleY + 25;
    CGFloat logHeight = 50;
    CGFloat tableHeight = popupHeight - tableY - logHeight - 20;
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(20, tableY, popupWidth - 40, tableHeight) style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.layer.cornerRadius = 8;
    self.tableView.clipsToBounds = YES;
    [self.popupContainer addSubview:self.tableView];
    
    if (blockedKeywords.count == 0) {
        UILabel *emptyLabel = [[UILabel alloc] init];
        emptyLabel.text = @"暂无屏蔽关键词";
        emptyLabel.font = [UIFont italicSystemFontOfSize:12];
        emptyLabel.textColor = [UIColor lightGrayColor];
        emptyLabel.textAlignment = NSTextAlignmentCenter;
        emptyLabel.frame = self.tableView.bounds;
        self.tableView.backgroundView = emptyLabel;
    }
    
    CGFloat logY = tableY + tableHeight + 10;
    self.logTextView = [[UITextView alloc] initWithFrame:CGRectMake(20, logY, popupWidth - 40, logHeight)];
    self.logTextView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.05];
    self.logTextView.layer.cornerRadius = 8;
    self.logTextView.font = [UIFont fontWithName:@"Menlo" size:11];
    self.logTextView.textColor = [UIColor darkGrayColor];
    self.logTextView.editable = NO;
    self.logTextView.selectable = NO;
    self.logTextView.showsVerticalScrollIndicator = YES;
    self.logTextView.textContainerInset = UIEdgeInsetsMake(4, 4, 4, 4);
    
    NSMutableString *logContent = [NSMutableString string];
    if (blockLogs.count == 0) {
        [logContent appendString:@"暂无拦截记录"];
    } else {
        NSInteger startIdx = (blockLogs.count >= 2) ? blockLogs.count - 2 : 0;
        for (NSInteger i = startIdx; i < blockLogs.count; i++) {
            if (i > startIdx) [logContent appendString:@"\n"];
            [logContent appendString:blockLogs[i]];
        }
        if (blockLogs.count > 2) {
            [logContent appendFormat:@"\n...还有 %ld 条记录", (long)(blockLogs.count - 2)];
        }
    }
    self.logTextView.text = logContent;
    
    [self.popupContainer addSubview:self.logTextView];
}

- (void)closeSettings {
    [self dismissViewControllerAnimated:YES completion:nil];
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
        
        UILabel *toast = [[UILabel alloc] init];
        toast.text = @"已添加";
        toast.font = [UIFont systemFontOfSize:12];
        toast.textColor = [UIColor whiteColor];
        toast.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
        toast.textAlignment = NSTextAlignmentCenter;
        toast.layer.cornerRadius = 6;
        toast.clipsToBounds = YES;
        toast.frame = CGRectMake(self.popupContainer.bounds.size.width/2 - 35, 25, 70, 24);
        [self.popupContainer addSubview:toast];
        
        [UIView animateWithDuration:0.8 animations:^{
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
        cell.textLabel.font = [UIFont systemFontOfSize:13];
        UIView *bgView = [[UIView alloc] init];
        bgView.backgroundColor = [[UIColor systemBlueColor] colorWithAlphaComponent:0.08];
        cell.selectedBackgroundView = bgView;
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
        if (blockedKeywords.count == 0) {
            UILabel *emptyLabel = [[UILabel alloc] init];
            emptyLabel.text = @"暂无屏蔽关键词";
            emptyLabel.font = [UIFont italicSystemFontOfSize:12];
            emptyLabel.textColor = [UIColor lightGrayColor];
            emptyLabel.textAlignment = NSTextAlignmentCenter;
            emptyLabel.frame = tableView.bounds;
            tableView.backgroundView = emptyLabel;
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 35;
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
    RLog(@"三指长按触发");
    loadKeywords();
    
    DBPopupViewController *popupVC = [[DBPopupViewController alloc] init];
    popupVC.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    popupVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    UIViewController *topVC = getTopVC();
    if (topVC) {
        [topVC presentViewController:popupVC animated:YES completion:nil];
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
        NSError *err = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorNotConnectedToInternet userInfo:@{NSLocalizedDescriptionKey: @"该域名已被屏蔽"}];
        if (completionHandler) completionHandler(nil, nil, err);
        return nil;
    }
    return %orig;
}
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {
    if (shouldBlockURL(request.URL.absoluteString)) {
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
    blockLogs = [NSMutableArray array];
    RLog(@"插件已加载，日志已清空");
    %init(DomainBlockerHooks);
}
