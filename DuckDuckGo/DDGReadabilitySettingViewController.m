//
//  DDGReadabilitySettingViewController.m
//  DuckDuckGo
//
//  Created by Johnnie Walker on 13/05/2013.
//
//

#import "DDGReadabilitySettingViewController.h"
#import "DDGSettingsViewController.h"
#import "DDGSearchController.h"

NSString * const DDGReadabilityModeKey = @"readability";

@implementation DDGReadabilitySettingViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.backgroundView = nil;
	self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"settings_bg_tile.png"]];
}

- (void)configure
{
	self.title = NSLocalizedString(@"Region", @"View controller title");
    
    NSInteger readabilitySetting = [[NSUserDefaults standardUserDefaults] integerForKey:DDGSettingStoriesReadabilityMode];
    
    [self addSectionWithTitle:@"Readability" footer:nil];
    
    [self addRadioOptionWithTitle:@"Off" value:@(DDGReadabilityModeOff) key:DDGReadabilityModeKey selected:(readabilitySetting == DDGReadabilityModeOff)];
    [self addRadioOptionWithTitle:@"On when available" value:@(DDGReadabilityModeOnIfAvailable) key:DDGReadabilityModeKey selected:(readabilitySetting == DDGReadabilityModeOnIfAvailable)];
    [self addRadioOptionWithTitle:@"Only show articles with Readability" value:@(DDGReadabilityModeOnExclusive) key:DDGReadabilityModeKey selected:(readabilitySetting == DDGReadabilityModeOnExclusive)];
    
}

-(void)saveData:(NSDictionary *)formData {
    NSNumber *readabilitySetting = [formData objectForKey:DDGReadabilityModeKey];
    [[NSUserDefaults standardUserDefaults] setInteger:[readabilitySetting integerValue] forKey:DDGSettingStoriesReadabilityMode];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    [self saveData:[self formData]];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [[self searchControllerDDG] popContentViewControllerAnimated:YES];
}

@end
