//
//  DDGNoContentViewController.m
//  DuckDuckGo
//
//  Created by Sean Reilly on 17/08/2015.
//
//

#import "DDGNoContentViewController.h"

@interface DDGNoContentViewController ()

@property (nonatomic, weak) IBOutlet UILabel* noContentTitle;
@property (nonatomic, weak) IBOutlet UILabel* noContentSubtitle;


@end

@implementation DDGNoContentViewController


-(id)init
{
    self = [super initWithNibName:@"DDGNoContentViewController" bundle:nil];
    if(self) {
        
    }
    return self;
}


-(NSString*)contentTitle {
    return self.noContentSubtitle.text;
}

-(void)setContentTitle:(NSString *)labelText
{
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:labelText];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineSpacing:3];
    [paragraphStyle setAlignment:NSTextAlignmentCenter];
    [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, [labelText length])];
    self.noContentTitle.attributedText = attributedString;
}


-(NSString*)contentSubtitle {
    return self.noContentSubtitle.text;
}

-(void)setContentSubtitle:(NSString *)labelText
{
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:labelText];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineSpacing:3];
    [paragraphStyle setAlignment:NSTextAlignmentCenter];
    [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, [labelText length])];
    self.noContentSubtitle.attributedText = attributedString;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
