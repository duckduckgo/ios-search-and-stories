//
//  DDGSettingsViewController.m
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 7/18/12.
//  Copyright (c) 2012 DuckDuckGo, Inc. All rights reserved.
//

#import "DDGSettingsViewController.h"
#import "DDGChooseSourcesViewController.h"
#import "DDGChooseRegionViewController.h"
#import "DDGActivityViewController.h"
#import "UIFont+DDG.h"
#import "SVProgressHUD.h"
#import <sys/utsname.h>
#import "DDGHistoryProvider.h"
#import "DDGRegionProvider.h"
#import "DDGSearchController.h"
#import "DDGReadabilitySettingViewController.h"

NSString * const DDGSettingRecordHistory = @"history";
NSString * const DDGSettingQuackOnRefresh = @"quack";
NSString * const DDGSettingRegion = @"region";
NSString * const DDGSettingAutocomplete = @"autocomplete";
NSString * const DDGSettingSuppressBangTooltip = @"suppress_bang_tooltip";
NSString * const DDGSettingStoriesReadabilityMode = @"readability_mode";
NSString * const DDGSettingHomeView = @"home_view";

NSString * const DDGSettingHomeViewTypeStories = @"Stories View";
NSString * const DDGSettingHomeViewTypeSaved = @"Saved View";
NSString * const DDGSettingHomeViewTypeRecents = @"Recents";
NSString * const DDGSettingHomeViewTypeDuck = @"Duck Mode";

@implementation DDGSettingsViewController

+(void)loadDefaultSettings {
    NSDictionary *defaults = @{
        DDGSettingRecordHistory: @(YES),
        DDGSettingQuackOnRefresh: @(NO),
		DDGSettingRegion: @"us-en",
		DDGSettingAutocomplete: @(YES),
		DDGSettingStoriesReadabilityMode: @(DDGReadabilityModeOnIfAvailable),
        DDGSettingHomeView: DDGSettingHomeViewTypeStories,
    };
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DDGSlideOverMenuWillAppearNotification object:nil];
}

#pragma mark - View lifecycle

-(void)viewDidLoad {
    [super viewDidLoad];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:[UIImage imageNamed:@"button_menu-default"] forState:UIControlStateNormal];
    [button setImage:[UIImage imageNamed:@"button_menu-onclick"] forState:UIControlStateHighlighted];
    
	button.imageView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	button.autoresizesSubviews = YES;
    
    float topInset = 1.0f;
    button.imageEdgeInsets = UIEdgeInsetsMake(topInset, 0.0f, -topInset, 0.0f);
    
    [button addTarget:self action:@selector(leftButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
	self.navigationItem.rightBarButtonItem = nil;
    
    self.tableView.backgroundView = nil;
	self.tableView.backgroundColor =  DDG_SETTINGS_BACKGROUND_COLOR;
    self.tableView.sectionHeaderHeight = 64;
    self.tableView.separatorColor = [UIColor duckTableSeparator];
    // force 1st time through for iOS < 6.0
	[self viewWillLayoutSubviews];
}

-(void)leftButtonPressed
{
    [self.slideOverMenuController showMenu];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSArray *regionItems = [self elementsForKey:@"region"];
    NSString *regionTitle = [[DDGRegionProvider shared] titleForRegion:[[DDGRegionProvider shared] region]];
    for (IGFormElement *element in regionItems) {
        if ([element isKindOfClass:[IGFormButton class]]) {
            [(IGFormButton *)element setDetailTitle:regionTitle];
        }
    }
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(slidingViewUnderLeftWillAppear:)
                                                 name:DDGSlideOverMenuWillAppearNotification
                                               object:nil];
}

- (void)reenableScrollsToTop {
    self.tableView.scrollsToTop = YES;
}

- (void)slidingViewUnderLeftWillAppear:(NSNotification *)notification {
    [self save:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:DDGSlideOverMenuWillAppearNotification
                                                  object:nil];
}

- (void)viewWillLayoutSubviews
{
	CGPoint center = self.navigationItem.leftBarButtonItem.customView.center;
	if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation) && ([[UIDevice currentDevice] userInterfaceIdiom]==UIUserInterfaceIdiomPhone))
		self.navigationItem.leftBarButtonItem.customView.frame = CGRectMake(0, 0, 26, 21);
	else
		self.navigationItem.leftBarButtonItem.customView.frame = CGRectMake(0, 0, 38, 31);
	self.navigationItem.leftBarButtonItem.customView.center = center;
}

- (UIImage *)searchControllerBackButtonIconDDG {
    return [[UIImage imageNamed:@"Settings"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];;
}

#pragma mark - Rotation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark - Form view controller

-(void)configure {
    self.title = @"Settings";
    // referencing self directly in the blocks below leads to retain cycles, so use weakSelf instead
    __weak DDGSettingsViewController *weakSelf = self;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    [self addSectionWithTitle:@"Stories" footer:nil];
    [self addButton:@"Sources" forKey:@"sources" detailTitle:nil type:IGFormButtonTypeDisclosure action:^{
        DDGChooseSourcesViewController *sourcesVC = [[DDGChooseSourcesViewController alloc] initWithStyle:UITableViewStylePlain];
        sourcesVC.managedObjectContext = weakSelf.managedObjectContext;
        [weakSelf.searchControllerDDG pushContentViewController:sourcesVC animated:YES];
    }];
    
    [self addButton:@"Readability" forKey:@"readability" detailTitle:nil type:IGFormButtonTypeDisclosure action:^{
        DDGReadabilitySettingViewController *rvc = [[DDGReadabilitySettingViewController alloc] initWithDefaults];
        [weakSelf.searchControllerDDG pushContentViewController:rvc animated:YES];
    }];
//    IGFormSwitch *readabilitySwitch = [self addSwitch:@"Readability" forKey:DDGSettingStoriesReadView enabled:[[defaults objectForKey:DDGSettingStoriesReadView] boolValue]];
    IGFormSwitch *quackSwitch = [self addSwitch:@"Quack on Refresh" forKey:DDGSettingQuackOnRefresh enabled:[[defaults objectForKey:DDGSettingQuackOnRefresh] boolValue]];
    
    [self addSectionWithTitle:@"Search" footer:nil];
    IGFormSwitch *suggestionsSwitch = [self addSwitch:@"Autocomplete" forKey:DDGSettingAutocomplete enabled:[[defaults objectForKey:DDGSettingAutocomplete] boolValue]];
    [self addButton:@"Region" forKey:@"region" detailTitle:nil type:IGFormButtonTypeDisclosure action:^{
        DDGChooseRegionViewController *rvc = [[DDGChooseRegionViewController alloc] initWithDefaults];
        [weakSelf.searchControllerDDG pushContentViewController:rvc animated:YES];
    }];
    
    [self addSectionWithTitle:@"Privacy" footer:nil];
    IGFormSwitch *recentSwitch = [self addSwitch:@"Save Recent" forKey:DDGSettingRecordHistory enabled:[[defaults objectForKey:DDGSettingRecordHistory] boolValue]];
    [self addButton:@"Clear Recents" forKey:@"clear_recent" detailTitle:nil type:IGFormButtonTypeNormal action:^{
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Are you sure you want to clear history? This cannot be undone."
                                                                 delegate:weakSelf
                                                        cancelButtonTitle:@"Cancel"
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:@"Clear Recent", nil];
        [actionSheet showInView:weakSelf.view.window];
    }];
    
    for (IGFormSwitch *s in @[quackSwitch, suggestionsSwitch, recentSwitch])
        [s.switchControl addTarget:self action:@selector(save:) forControlEvents:UIControlEventValueChanged];
    
    [self addSectionWithTitle:@"Other" footer:nil];
    
    [self addButton:@"Send Feedback" forKey:@"feedback" detailTitle:nil type:IGFormButtonTypeNormal action:^{
        MFMailComposeViewController *mailVC = [[MFMailComposeViewController alloc] init];
        mailVC.mailComposeDelegate = weakSelf;
        [mailVC setToRecipients:@[@"help@duckduckgo.com"]];
        [mailVC setSubject:@"DuckDuckGo for iOS feedback"];
        [mailVC setMessageBody:[NSString stringWithFormat:@"I'm running %@. Here's my feedback:",[weakSelf deviceInfo]] isHTML:NO];
        [weakSelf presentViewController:mailVC animated:YES completion:NULL];
    }];
    [self addButton:@"Share" forKey:@"share" detailTitle:nil type:IGFormButtonTypeNormal action:^{
        NSString *shareTitle = @"Check out the DuckDuckGo iOS app!";
        NSURL *shareURL = [NSURL URLWithString:@"https://itunes.apple.com/app/id663592361"];
        DDGActivityViewController *avc = [[DDGActivityViewController alloc] initWithActivityItems:@[shareTitle, shareURL] applicationActivities:@[]];
        [weakSelf presentViewController:avc animated:YES completion:NULL];
    }];
    [self addButton:@"Leave a Rating" forKey:@"rate" detailTitle:nil type:IGFormButtonTypeNormal action:^{
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=663592361&onlyLatestVersion=true&pageNumber=0&sortOrdering=1&type=Purple+Software"]];
    }];

    NSString *bundleVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    NSString *shortBundleVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *appName = [[[NSBundle mainBundle] localizedInfoDictionary] objectForKey:@"CFBundleDisplayName"];
    if (appName == nil)
        appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
    
    NSString *versionInfo = [NSString stringWithFormat:@"%@ %@", appName, shortBundleVersion];
    if (![shortBundleVersion isEqualToString:bundleVersion])
        versionInfo = [versionInfo stringByAppendingFormat:@" (%@)", bundleVersion];
    
    [self addSectionWithTitle:nil footer:versionInfo];
    self.tableView.sectionFooterHeight = 0;
}

-(IBAction)save:(id)sender {
    [self saveData:[self formData]];
}

-(void)saveData:(NSDictionary *)formData {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if ([formData objectForKey:DDGSettingHomeView])
        [defaults setObject:[formData objectForKey:DDGSettingHomeView] forKey:DDGSettingHomeView];
    
    [defaults setObject:[formData objectForKey:DDGSettingRecordHistory] forKey:DDGSettingRecordHistory];
    [defaults setObject:[formData objectForKey:DDGSettingQuackOnRefresh] forKey:DDGSettingQuackOnRefresh];
    [defaults setObject:[formData objectForKey:DDGSettingAutocomplete] forKey:DDGSettingAutocomplete];
}

#pragma mark - Helper methods

-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if(buttonIndex == 0) {
        DDGHistoryProvider *historyProvider = [[DDGHistoryProvider alloc] initWithManagedObjectContext:self.managedObjectContext];
        [historyProvider clearHistory];
        [SVProgressHUD showSuccessWithStatus:@"Recents cleared!"];
    }
}

-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    if(result == MFMailComposeResultSent) {
        [SVProgressHUD showSuccessWithStatus:@"Feedback sent!"];
    } else if(result == MFMailComposeResultFailed) {
        [SVProgressHUD showErrorWithStatus:@"Feedback send failed!"];
    }
    [self dismissViewControllerAnimated:YES completion:NULL];
}

-(IGFormSwitch *)addSwitch:(NSString *)title forKey:(NSString *)key enabled:(BOOL)enabled {
    IGFormSwitch *formSwitch = [super addSwitch:title forKey:key enabled:enabled];
    formSwitch.switchControl.onTintColor = [UIColor duckRed];
    return formSwitch;
}

-(NSString *)deviceInfo {
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *device = [NSString stringWithCString:systemInfo.machine
                                          encoding:NSUTF8StringEncoding];
    NSDictionary *deviceNames = @{
        @"x86_64"    : @"iOS simulator",
        @"i386"      : @"iOS simulator",
        @"iPod1,1"   : @"iPod touch 1G",
        @"iPod2,1"   : @"iPod touch 2G",
        @"iPod3,1"   : @"iPod touch 3G",
        @"iPod4,1"   : @"iPod touch 4G",
        @"iPod5,1"   : @"iPod touch 5G",
        @"iPod7,1"   : @"iPod touch 6G",
        @"iPhone1,1" : @"iPhone",
        @"iPhone1,2" : @"iPhone 3G",
        @"iPhone2,1" : @"iPhone 3GS",
        @"iPad1,1"   : @"iPad",
        @"iPad2,1"   : @"iPad 2",
        @"iPad2,2"   : @"iPad 2",
        @"iPad2,3"   : @"iPad 2",
        @"iPad2,4"   : @"iPad 2",
        @"iPad3,1"   : @"iPad 3rd Gen",
        @"iPad3,2"   : @"iPad 3rd Gen",
        @"iPad3,3"   : @"iPad 3rd Gen",
        @"iPad3,4"   : @"iPad 4th Gen",
        @"iPad3,5"   : @"iPad 4th Gen",
        @"iPad3,6"   : @"iPad 4th Gen",
        @"iPad4,1"   : @"iPad Air",
        @"iPad4,2"   : @"iPad Air",
        @"iPad4,3"   : @"iPad Air",
        @"iPad5,3"   : @"iPad Air 2",
        @"iPad5,4"   : @"iPad Air 2",
        
        @"iPad2,5"   : @"iPad Mini",
        @"iPad2,6"   : @"iPad Mini",
        @"iPad2,7"   : @"iPad Mini",
        @"iPad4,4"   : @"iPad Mini 2",
        @"iPad4,5"   : @"iPad Mini 2",
        @"iPad4,6"   : @"iPad Mini 2",
        @"iPad4,7"   : @"iPad Mini 3",
        @"iPad4,8"   : @"iPad Mini 3",
        @"iPad4,9"   : @"iPad Mini 3",
        
        @"iPhone3,1" : @"iPhone 4",
        @"iPhone3,2" : @"iPhone 4",
        @"iPhone3,3" : @"iPhone 4",
        @"iPhone4,1" : @"iPhone 4S",
        @"iPhone5,1" : @"iPhone 5",
        @"iPhone5,2" : @"iPhone 5",
        @"iPhone5,3" : @"iPhone 5c",
        @"iPhone5,4" : @"iPhone 5c",
        @"iPhone6,1" : @"iPhone 5s",
        @"iPhone6,2" : @"iPhone 5s",
        @"iPhone7,2" : @"iPhone 6",
        @"iPhone7,1" : @"iPhone 6+"
    };
    if([deviceNames objectForKey:device])
        device = [deviceNames objectForKey:device];
    
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    NSString *osVersion = [[UIDevice currentDevice] systemVersion];
    
    return [NSString stringWithFormat:@"DuckDuckGo v%@ on an %@ (iOS %@)",appVersion,device,osVersion];
}


+(UIView*)createSectionHeaderView:(NSString*)title
{
    UIView* view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    view.opaque = NO;
    view.backgroundColor = [UIColor clearColor];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectInset(view.bounds, 16.0, 0.0)];
    titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    titleLabel.opaque = NO;
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.font = [UIFont duckFontWithSize:15.0];
    titleLabel.text = title;
    titleLabel.textColor = [UIColor colorWithRed:56.0f/255.0f green:56.0f/255.0f blue:56.0f/255.0f alpha:1.0f];
    [view addSubview:titleLabel];
    
    return view;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return [DDGSettingsViewController createSectionHeaderView:[self tableView:tableView titleForHeaderInSection:section]];
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 64.0;
}

+(void)configureSettingsCell:(UITableViewCell*)cell
{
    cell.textLabel.font = [UIFont duckFontWithSize:17.0];
    cell.textLabel.textColor = UIColor.duckSettingsLabel;
    cell.textLabel.textAlignment = NSTextAlignmentNatural;
    cell.detailTextLabel.font = [UIFont duckFontWithSize:15.0];
    cell.detailTextLabel.textColor = UIColor.duckSettingsDetailLabel;
    cell.tintColor = UIColor.duckRed;
}

+(UIView*)createSectionFooterView:(NSString *)title
{
    UIView* view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 20)];
    view.opaque = NO;
    view.backgroundColor = [UIColor clearColor];
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectInset(view.bounds, 16.0, 0.0)];
    titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    titleLabel.opaque = NO;
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.font = [UIFont duckFontWithSize:13];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.text = title;
    titleLabel.textColor = [UIColor colorWithRed:0.341 green:0.376 blue:0.424 alpha:1.000];
    [view addSubview:titleLabel];
    return view;
}


- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return nil;
//    NSString* title = [self tableView:tableView titleForFooterInSection:section];
//    return title.length > 0 ? [DDGSettingsViewController createSectionFooterView:title] : nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    [self save:nil];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    [DDGSettingsViewController configureSettingsCell:cell];
    //[DDGSettingsViewController configureSettingsCellDetail:cell];
    
    return cell;
}
@end
