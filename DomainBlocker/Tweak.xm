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
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"成功" message:@"关键词已保存" preferredStyle:UIAler
