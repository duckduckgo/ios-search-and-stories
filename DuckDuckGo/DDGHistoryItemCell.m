//
//  DDGHistoryItemCell.m
//  DuckDuckGo
//
//  Created by Johnnie Walker on 15/04/2013.
//
//

#import "DDGHistoryItemCell.h"
#import "DDGDeleteButton.h"

@interface DDGHistoryItemCell ()
//@property (nonatomic, weak, readwrite) UIButton *deleteButton;
@end

@implementation DDGHistoryItemCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    NSAssert(NO, @"Use - (id)initWithReuseIdentifier:(NSString *)reuseIdentifier");
    return nil;
}

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
        self.accessoryView = nil;
        
        self.fixedSizeImageView.size = CGSizeMake(16.0, 16.0);
        self.textLabel.textColor = [UIColor colorWithRed:0.780 green:0.808 blue:0.851 alpha:1.000];
        self.textLabel.font = [UIFont duckFontWithSize:19.0];
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        self.textLabel.numberOfLines = 2;
        self.textLabel.highlightedTextColor = [UIColor whiteColor];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.fixedSizeImageView.size = CGSizeMake(16.0, 16.0);
}

//- (void)setDeleting:(BOOL)deleting animated:(BOOL)animated {
//    
//    if (_deleting != deleting) {
//        _deleting = deleting;
//        [self setNeedsLayout];
//    }
//    
//    if (deleting && nil == self.deleteButton) {
//        UIButton *deleteButton = [DDGDeleteButton deleteButton];
//        [deleteButton addTarget:nil action:@selector(delete:) forControlEvents:UIControlEventTouchUpInside];
//        [deleteButton setTitle:NSLocalizedString(@"Delete", @"button title") forState:UIControlStateNormal];
//        [deleteButton sizeToFit];
//        
//        CGRect buttonFrame = CGRectInset(deleteButton.frame, -8.0, -8.0);
//        
//        CGRect bounds = self.bounds;
//        buttonFrame = CGRectMake(bounds.origin.x + bounds.size.width - self.overhangWidth,
//                                 bounds.origin.y + floor((bounds.size.height - buttonFrame.size.height)/2.0),
//                                 buttonFrame.size.width,
//                                 buttonFrame.size.height);
//        deleteButton.frame = buttonFrame;
//        deleteButton.alpha = 0.0;
//        
//        [self addSubview:deleteButton];
//        self.deleteButton = deleteButton;
//    }
//    
//    NSTimeInterval duration = (animated) ? 0.2 : 0.0;
//    [UIView animateWithDuration:duration
//                     animations:^{
//                         [self layoutIfNeeded];
//                     } completion:^(BOOL finished) {
//                         if (!deleting)
//                             [self.deleteButton removeFromSuperview];
//                     }];
//    
//    [self setNeedsLayout];
//}

//- (void)layoutSubviews {
//    [super layoutSubviews];
//        
//    if (self.isDeleting) {
//        CGRect bounds = self.bounds;
//        CGRect frame = self.contentView.frame;
//        //CGRect buttonFrame = self.deleteButton.frame;
//        
//        CGFloat buttonPadding = 6.0;
//        CGFloat buttonInset = buttonFrame.size.width + buttonPadding - self.accessoryView.frame.size.width;
//        
//        frame.size.width -= buttonInset;
//        self.contentView.frame = frame;
//        
//        self.accessoryView.alpha = 0.0;
//        
//        CGRect textFrame = self.textLabel.frame;
//        textFrame.size.width -= buttonInset;
//        self.textLabel.frame = textFrame;
//        
//        textFrame = self.detailTextLabel.frame;
//        textFrame.size.width -= buttonInset;
//        self.detailTextLabel.frame = textFrame;
//        
//        buttonFrame = CGRectMake(bounds.origin.x + bounds.size.width - buttonFrame.size.width - self.overhangWidth,
//                                 bounds.origin.y + floor((bounds.size.height - buttonFrame.size.height)/2.0),
//                                 buttonFrame.size.width, buttonFrame.size.height);
//        self.deleteButton.frame = buttonFrame;
//        self.deleteButton.alpha = 1.0;
//    } else {
//        CGRect bounds = self.bounds;
//        CGRect accessoryRect = self.accessoryView.frame;
//        
//        self.accessoryView.alpha = 1.0;
//        self.accessoryView.frame = CGRectMake(accessoryRect.origin.x + 4.0,
//                                              accessoryRect.origin.y,
//                                              accessoryRect.size.width,
//                                              accessoryRect.size.height);
//        
//        CGRect buttonFrame = self.deleteButton.frame;
//        buttonFrame = CGRectMake(bounds.origin.x + bounds.size.width - self.overhangWidth,
//                                 bounds.origin.y + floor((bounds.size.height - buttonFrame.size.height)/2.0),
//                                 buttonFrame.size.width,
//                                 buttonFrame.size.height);
//        self.deleteButton.frame = buttonFrame;
//        self.deleteButton.alpha = 0.0;
//    }
//}
//

@end
