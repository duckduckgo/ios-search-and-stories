//
//  FormViewController.h
//  FormViewController
//
//  Created by Ishaan Gulrajani on 3/28/10.
//  Copyright 2010 Ishaan Gulrajani. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum _IGFormButtonType {
    IGFormButtonTypeNormal,
    IGFormButtonTypeDisclosure
} IGFormButtonType;

@interface IGFormViewController : UITableViewController <UIPopoverControllerDelegate, UITextFieldDelegate> {
	UINavigationController *popoverNavigationController;
	NSMutableArray *elements;
}
@property(weak, nonatomic,readonly) UINavigationController *popoverNavigationController;

// Always init with this method
-(id)initWithDefaults;

// Subclasses should override this method to configure fields, etc...
-(void)configure;

// Subclasses should override this method to determine whether the data is valid.
// If valid, return nil. If not, return an error message.
-(NSString *)validateData:(NSDictionary *)formData;

// Subclasses should override this method to save the given data. You can assume that the data is valid according to validateData:.
-(void)saveData:(NSDictionary *)formData;

// Creates a new section in the form with the given title
-(void)addSectionWithTitle:(NSString *)title;

// Creates a new section in the form with the given title and footer
-(void)addSectionWithTitle:(NSString *)title footer:(NSString *)footer;

// Add and return a text field to the form.
-(void)addTextField:(NSString *)fieldName;

// Same as addTextField:, but also adds a default value
-(void)addTextField:(NSString *)fieldName value:(NSString *)value;

// Same as addTextField:value:, but for multi-line text entry
-(void)addTextView:(NSString *)fieldName value:(NSString *)value;

// Adds a radio option (a row with a checkbox to the right). You should call this multiple times with the same category for each set of options.
-(void)addRadioOption:(NSString *)category title:(NSString *)title;

// Adds a toggle switch and sets the default value
-(void)addSwitch:(NSString *)title enabled:(BOOL)enabled;

// Adds a button that executes the given block when pressed
-(void)addButton:(NSString *)title action:(void(^)(void))action;

// Adds a button (see above) with a specific style
-(void)addButton:(NSString *)title type:(IGFormButtonType)type action:(void(^)(void))action;

@end
