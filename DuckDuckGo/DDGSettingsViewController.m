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
#import "DDGChooseHomeViewController.h"
#import "DDGActivityViewController.h"
#import <sys/utsname.h>
#import "DDGHistoryProvider.h"
#import "DDGRegionProvider.h"
#import "DDGSearchController.h"
#import "DDGReadabilitySettingViewController.h"
#import "DDGUtility.h"
#import "DDGTraitHelper.h"
#import "MGSplitViewController.h"
#import "DDGTraitHelper.h"


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

@interface DDGSettingsViewController ()
@property (nonatomic, weak) IGFormButton* clearRecentsButton;
@property (nonatomic) NSUInteger numberOfRecents;
@property (nonatomic) MGSplitViewController* splitViewController;
@property (nonatomic) UIViewController* containerController;

@end


@implementation DDGSettingsViewController

+(void)loadDefaultSettings {
    // Get Default UserAgent.
    UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectZero];
    NSString *defaultAgent = [NSString stringWithFormat:@"%@; %@", [webView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"],
                              [DDGUtility agentDDG]];
    
    NSDictionary *defaults = @{
        DDGSettingRecordHistory: @(YES),
        DDGSettingQuackOnRefresh: @(NO),
		DDGSettingRegion: @"wt-wt",
		DDGSettingAutocomplete: @(YES),
		DDGSettingStoriesReadabilityMode: @(DDGReadabilityModeOnIfAvailable),
        DDGSettingHomeView: DDGSettingHomeViewTypeStories,
        @"UserAgent": defaultAgent,
    };
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}


- (UIViewController*)duckContainerController
{
    if(self.containerController) return self.containerController;
    
//    if([DDGTraitHelper isFullScreeniPad:self.traitCollection]) {
    if (IPAD) {
        if (self.splitViewController == nil) {
            MGSplitViewController* splitController = [[MGSplitViewController alloc] init];
            splitController.allowsDraggingDivider  = FALSE;
            splitController.masterViewController   = self;
            splitController.view.backgroundColor   = [UIColor duckNoContentColor];
            splitController.dividerView            = nil;
            self.splitViewController               = splitController;
            self.containerController               = splitController;
            [self performSelector:@selector(showChooseHomeController) withObject:nil afterDelay:1.0];
        }
    } else {
        self.containerController = self;
    }
    return self.containerController;
}


#pragma mark - View lifecycle

-(void)viewDidLoad {
    [super viewDidLoad];
    
    // put the tableview under a container UIView to enable the toolbar installed by the search controller
    UITableView* tableView = self.tableView;
    CGRect frame = self.view.frame;
    self.view = [[UIView alloc] initWithFrame:frame];
    frame.origin = CGPointMake(0, 0);
    tableView.frame = frame;
    [self.view addSubview:tableView];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

    self.navigationItem.rightBarButtonItem = nil;
    [DDGSettingsViewController configureTable:self.tableView];
    
    // force 1st time through for iOS < 6.0
	[self viewWillLayoutSubviews];
    
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

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *homeViewMode = [defaults objectForKey:DDGSettingHomeView];
    NSArray *homeItems = [self elementsForKey:DDGSettingHomeView];
    NSString *homeTitle = [DDGChooseHomeViewController homeViewNameForID:homeViewMode];
    for (IGFormElement *element in homeItems) {
        if ([element isKindOfClass:[IGFormButton class]]) {
            [(IGFormButton *)element setDetailTitle:homeTitle];
        }
    }

    [self updateClearRecentsItem];
    [self.tableView reloadData];
}


-(void)updateClearRecentsItem
{
    DDGHistoryProvider *historyProvider = [[DDGHistoryProvider alloc] initWithManagedObjectContext:self.managedObjectContext];
    self.numberOfRecents = [historyProvider countHistoryItems];
}

-(void)duckGoToTopLevel
{
    if(self.navigationController.viewControllers.count>1) {
        [self.navigationController popToRootViewControllerAnimated:TRUE];
    }
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]
                          atScrollPosition:UITableViewScrollPositionTop animated:TRUE];
}

- (void)reenableScrollsToTop {
    self.tableView.scrollsToTop = YES;
}

- (void)slidingViewUnderLeftWillAppear:(NSNotification *)notification {
    [self save:nil];
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
    return [UIImage imageNamed:@"Settings"];
}

-(void)pushSecondaryViewController:(UIViewController*)secondaryViewController
{
    if(self.splitViewController) {
        if(![DDGTraitHelper isFullScreeniPad:self.traitCollection]) {
            [self.searchControllerDDG pushContentViewController:secondaryViewController animated:TRUE];
        } else {            
            [self.splitViewController setDetailViewController:secondaryViewController];
            
            // Ensure that the tab bar is actually on the top level, especially after changing detail controllers
            [self.splitViewController.view bringSubviewToFront:self.searchControllerDDG.toolbarView];
        }
    } else {
        [self.searchControllerDDG pushContentViewController:secondaryViewController animated:TRUE];
    }
}

-(void)showChooseHomeController {
    DDGChooseHomeViewController *hvc = [[DDGChooseHomeViewController alloc] initWithDefaults];
    [self pushSecondaryViewController:hvc];
}

#pragma mark - Rotation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark - Form view controller

-(void)configure {
    [self clearElements];
    self.title = NSLocalizedString(@"Settings", @"View Controller Title: Settings");
    // referencing self directly in the blocks below leads to retain cycles, so use weakSelf instead
    __weak DDGSettingsViewController *weakSelf = self;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [self addSectionWithTitle:NSLocalizedString(@"General", @"Header for general settings section") footer:nil];
    
    NSString *settingHomeViewOption = [DDGChooseHomeViewController homeViewNameForID:[defaults objectForKey:DDGSettingHomeView]];
    [self addButton:NSLocalizedString(@"Home", @"Button: What screen should be presented when launching the app") forKey:DDGSettingHomeView detailTitle:settingHomeViewOption type:IGFormButtonTypeDisclosure action:^{
        [weakSelf showChooseHomeController];
    }];
    
    [self addSectionWithTitle:NSLocalizedString(@"Stories", @"Header for Stories settings section") footer:nil];
    [self addButton:NSLocalizedString(@"Sources", @"Button: Sources") forKey:@"sources" detailTitle:nil type:IGFormButtonTypeDisclosure action:^{
        DDGChooseSourcesViewController *sourcesVC = [[DDGChooseSourcesViewController alloc] initWithStyle:UITableViewStyleGrouped];
        sourcesVC.managedObjectContext = weakSelf.managedObjectContext;
        [weakSelf pushSecondaryViewController:sourcesVC];
    }];
    
    [self addButton:NSLocalizedString(@"Readability", @"Button: Readability") forKey:@"readability" detailTitle:nil type:IGFormButtonTypeDisclosure action:^{
        DDGReadabilitySettingViewController *rvc = [[DDGReadabilitySettingViewController alloc] initWithDefaults];
        [weakSelf pushSecondaryViewController:rvc];
    }];
    
//    IGFormSwitch *readabilitySwitch = [self addSwitch:@"Readability" forKey:DDGSettingStoriesReadView enabled:[[defaults objectForKey:DDGSettingStoriesReadView] boolValue]];
    IGFormSwitch *quackSwitch = [self addSwitch:NSLocalizedString(@"Quack on Refresh", @"Switch: Quack on Refresh") forKey:DDGSettingQuackOnRefresh enabled:[[defaults objectForKey:DDGSettingQuackOnRefresh] boolValue]];
    
    [self addSectionWithTitle:NSLocalizedString(@"Search", @"Header for Search settings section") footer:nil];
    IGFormSwitch *suggestionsSwitch = [self addSwitch:NSLocalizedString(@"Autocomplete", @"Switch: Autocomplete") forKey:DDGSettingAutocomplete enabled:[[defaults objectForKey:DDGSettingAutocomplete] boolValue]];
    
    NSString *regionTitleString = [[DDGRegionProvider shared] titleForRegion:[defaults objectForKey:DDGSettingRegion]];
    
    [self addButton:NSLocalizedString(@"Region", @"Button: Region") forKey:@"region" detailTitle:regionTitleString type:IGFormButtonTypeDisclosure action:^{
        DDGChooseRegionViewController *rvc = [[DDGChooseRegionViewController alloc] initWithDefaults];
        [weakSelf pushSecondaryViewController:rvc];
    }];
    
    [self addSectionWithTitle:NSLocalizedString(@"Privacy", @"Header for Privacy settings section") footer:nil];
    IGFormSwitch *recentSwitch = [self addSwitch:NSLocalizedString(@"Save Recents", @"Switch: Save recent searches") forKey:DDGSettingRecordHistory enabled:[[defaults objectForKey:DDGSettingRecordHistory] boolValue]];
    self.clearRecentsButton =
    [self addButton:NSLocalizedString(@"Clear Recents", @"Clear recent search results") forKey:@"clear_recent" detailTitle:nil type:IGFormButtonTypeNormal action:^{
        if(weakSelf.numberOfRecents<=0) return;
        
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Are you sure you want to clear your recents? This can not be undone.", @"Ask for confirmation of clearing the recent history and state that this cannot be undone")
                                                                 delegate:weakSelf
                                                        cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel")
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:NSLocalizedString(@"Clear Recents", @"Clear Recents"), nil];
        [actionSheet showInView:[weakSelf containerController].view];
    }];
    
    for (IGFormSwitch *s in @[quackSwitch, suggestionsSwitch, recentSwitch])
        [s.switchControl addTarget:self action:@selector(save:) forControlEvents:UIControlEventValueChanged];
    
    [self addSectionWithTitle:NSLocalizedString(@"Other", @"Heading for Other options section") footer:nil];

    if ([MFMailComposeViewController canSendMail]) {
        [self addButton:NSLocalizedString(@"Send Feedback", @"Button: Send Feedback") forKey:@"feedback" detailTitle:nil type:IGFormButtonTypeNormal action:^{
            MFMailComposeViewController *mailVC = [[MFMailComposeViewController alloc] init];
            mailVC.mailComposeDelegate = weakSelf;
            [mailVC setToRecipients:@[@"help@duckduckgo.com"]];
            [mailVC setSubject:@"DuckDuckGo for iOS feedback"];
            [mailVC setMessageBody:[NSString stringWithFormat:@"I'm running %@. Here's my feedback:", [weakSelf deviceInfo]] isHTML:NO];
            [weakSelf presentViewController:mailVC animated:YES completion:NULL];
        }];
    }
    
    [self addButton:NSLocalizedString(@"Share", @"Button: Share") forKey:@"share" detailTitle:nil type:IGFormButtonTypeNormal action:^{
        NSString *shareTitle = NSLocalizedString(@"Check out the DuckDuckGo iOS app!", @"Share title: Check out the DuckDuckGo iOS app!");
        NSURL *shareURL = [NSURL URLWithString:@"https://itunes.apple.com/app/id663592361"];
        DDGActivityViewController *avc = [[DDGActivityViewController alloc] initWithActivityItems:@[shareTitle, shareURL] applicationActivities:@[]];
        if ( [avc respondsToSelector:@selector(popoverPresentationController)] ) {
            // iOS8
            avc.popoverPresentationController.sourceView = weakSelf.view;
            avc.popoverPresentationController.sourceRect = weakSelf.view.frame;
        }

        [weakSelf presentViewController:avc animated:YES completion:NULL];
    }];
    
    [self addButton:NSLocalizedString(@"Leave a Rating", @"Button: Leave a Rating") forKey:@"rate" detailTitle:nil type:IGFormButtonTypeNormal action:^{
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=663592361&onlyLatestVersion=true&pageNumber=0&sortOrdering=1&type=Purple+Software"]];
    }];

    NSString *bundleVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    NSString *shortBundleVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    
    NSString *versionInfo = [NSString stringWithFormat:NSLocalizedString(@"Version %@", @"Version %@"), shortBundleVersion];
    if (![shortBundleVersion isEqualToString:bundleVersion])
        versionInfo = [versionInfo stringByAppendingFormat:@" (%@)", bundleVersion];
    
    [self addSectionWithTitle:versionInfo footer:nil];
    
    self.tableView.sectionFooterHeight = 0.01;
    [self.tableView setBackgroundColor:DDG_SETTINGS_BACKGROUND_COLOR];
    [self.tableView reloadData];
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
    // currently the only action sheet is to clear the history
    if(buttonIndex == 0) {
        DDGHistoryProvider *historyProvider = [[DDGHistoryProvider alloc] initWithManagedObjectContext:self.managedObjectContext];
        [historyProvider clearHistory];
        self.numberOfRecents = 0;
        [self.tableView reloadData];
    }
}

-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

-(IGFormSwitch *)addSwitch:(NSString *)title forKey:(NSString *)key enabled:(BOOL)enabled {
    IGFormSwitch *formSwitch = [super addSwitch:title forKey:key enabled:enabled];
    formSwitch.switchControl.onTintColor = [UIColor duckRed];
    return formSwitch;
}

- (NSString *)deviceInfo {
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

+(UIView*)createVersionView:(NSString*)title
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
    titleLabel.textColor = UIColorFromRGB(0x999999);
    [view addSubview:titleLabel];
    
    return view;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if(section+1 == [self numberOfSectionsInTableView:tableView]) {
        return [DDGSettingsViewController createVersionView:[self tableView:tableView titleForHeaderInSection:section]];
    } else {
        return [DDGSettingsViewController createSectionHeaderView:[self tableView:tableView titleForHeaderInSection:section]];
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 64.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.01f;
}

+(void)configureTable:(UITableView*)tableView
{
    tableView.backgroundView = nil;
    tableView.backgroundColor =  DDG_SETTINGS_BACKGROUND_COLOR;
    tableView.sectionHeaderHeight = 64;
    tableView.separatorColor = [UIColor duckTableSeparator];
}

+(void)configureSettingsCell:(UITableViewCell*)cell
{
    cell.textLabel.font            = [UIFont duckFontWithSize:17.0];
    cell.textLabel.textColor       = [UIColor duckListItemTextForeground];
    cell.textLabel.textAlignment   = NSTextAlignmentNatural;
    cell.detailTextLabel.font      = [UIFont duckFontWithSize:13.0];
    cell.detailTextLabel.textColor = [UIColor duckListItemDetailForeground];
    cell.tintColor = UIColor.duckRed;
}

+(void)configureOptionCell:(UITableViewCell*)cell
{
    cell.textLabel.font            = [UIFont duckFontWithSize:17.0];
    cell.textLabel.textColor       = [UIColor duckListItemTextForeground];
    cell.textLabel.textAlignment   = NSTextAlignmentNatural;
    cell.detailTextLabel.font      = [UIFont duckFontWithSize:17.0];
    cell.detailTextLabel.textColor = [UIColor duckListItemDetailForeground];
    cell.tintColor                 = UIColor.duckRed;
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
    [tableView deselectRowAtIndexPath:indexPath animated:TRUE];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    IGFormElement* thisElement = [self elementAtIndexPath:indexPath];
    if(thisElement && [thisElement isKindOfClass:IGFormButton.class]) {
        [DDGSettingsViewController configureOptionCell:cell];
    } else {
        [DDGSettingsViewController configureSettingsCell:cell];
    }
    if(thisElement==self.clearRecentsButton && self.numberOfRecents<=0) {
        cell.textLabel.textColor = [UIColor lightGrayColor];
    }

    
    return cell;
}

/*
#pragma mark == UITraitCollection Updates
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    // Did change
    if ([DDGTraitHelper isFullScreeniPad:previousTraitCollection]) {
        // Check if it's changed
        if (previousTraitCollection.horizontalSizeClass != self.traitCollection.horizontalSizeClass || previousTraitCollection.verticalSizeClass != self.traitCollection.verticalSizeClass) {
        }
    }
}
 */

@end
