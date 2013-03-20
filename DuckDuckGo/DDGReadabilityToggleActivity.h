//
//  DDGReadabilityToggleActivity.h
//  DuckDuckGo
//
//  Created by Johnnie Walker on 15/03/2013.
//
//

#import <UIKit/UIKit.h>

typedef enum DDGReadabilityToggleMode {
    DDGReadabilityToggleModeOff = 0,
    DDGReadabilityToggleModeOn
} DDGReadabilityToggleMode;

@interface DDGReadabilityToggleActivity : UIActivity
@property (nonatomic) DDGReadabilityToggleMode toggleMode;
@end
