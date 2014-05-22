//
//  DDGWebView.m
//  DuckDuckGo
//
//  Created by Mic Pringle on 22/05/2014.
//
//

#import "DDGWebView.h"

@interface DDGWebView () <UIGestureRecognizerDelegate>

@property (nonatomic, copy, readwrite) NSString *tappedImageURL;

@end

@implementation DDGWebView

#pragma mark - UIView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

#pragma mark - DDGWebView

- (void)handleTap:(UITapGestureRecognizer *)recognizer
{
    [self findImageForTap:[recognizer locationInView:self]];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if ([otherGestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
        CGPoint point = [otherGestureRecognizer locationInView:self];
        [self findImageForTap:point];
    }
    return NO;
}

#pragma mark - Private

- (void)findImageForTap:(CGPoint)tapLocation
{
    NSString *javascript = @"var ddg_url = '';" \
    "var node = document.elementFromPoint(%f, %f);" \
    "while(node) {" \
    "  if (node.tagName) {" \
    "    if(node.tagName.toLowerCase() == 'img' && node.src && node.src.length > 0) {" \
    "      ddg_url = node.src;" \
    "      break;" \
    "    }" \
    "  }" \
    "  node = node.parentNode;" \
    "}";
    [self stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:javascript, tapLocation.x, tapLocation.y]];
    NSString *url = [self stringByEvaluatingJavaScriptFromString:@"ddg_url"];
    self.tappedImageURL = (url && url.length > 0) ? url : nil;
}

- (void)setup
{
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    tapGestureRecognizer.delegate = self;
    tapGestureRecognizer.numberOfTapsRequired = 1;
    [self addGestureRecognizer:tapGestureRecognizer];
}

@end
