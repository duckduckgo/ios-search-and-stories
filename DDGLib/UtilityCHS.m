//
//  UtilityCHS.m
//  CHS Systems
//
//  Created by Chris Heimark on 9/17/09.
//  Copyright 2009 CHS Systems. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import <Twitter/TWTweetComposeViewController.h>

#import "UtilityCHS.h"
#import "JSON.h"

static BOOL sIsIpad = NO;

@implementation UtilityCHS

#pragma mark Initialize first time

+ (void)initialize
{
	sIsIpad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? YES : NO;
}

#pragma mark General application related

+ (void)dispatchURL:(NSDictionary*)entry
{
}

+ (BOOL)portrait:(UIInterfaceOrientation)orientation
{
	return (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown) ? YES : NO;
}

+ (BOOL)upsideDownOK
{
//	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
//        return YES;

	return [[NSUserDefaults standardUserDefaults] boolForKey:@"allowUpsideDownPortrait"];
}

+ (BOOL)validateEmail:(NSString *)candidate
{
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"; 
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex]; 
	
    return [emailTest evaluateWithObject:candidate];
}

+ (UIBarButtonItem*)iconButtonWithImageNamed:(NSString*)name action:(SEL)selector target:(id)target tag:(NSInteger)tag
{
	UIButton *button = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
	
	button.showsTouchWhenHighlighted = YES;
	[button setImage:[UIImage imageNamed:name] forState:UIControlStateNormal];
	[button setImage:[UIImage imageNamed:name] forState:UIControlStateHighlighted];
	[button addTarget:target action:selector forControlEvents:UIControlEventTouchUpInside];
	button.tag = tag;
	
	return [[[UIBarButtonItem alloc] initWithCustomView:button] autorelease];
}

+(void)bubbleWithMessage:(NSString*)msg andResponse:(NSInteger)responseCode orWithError:(NSError*)error
{
	NSString *title;
	NSString *message;
	if (error && !msg)
	{
		// some kind of general network failure
		title = @"No Network Connection";
		message = [error localizedDescription];
	}
	else if (error && msg)
	{
		// some kind of general network failure
		title = @"General Error";
		message = [msg stringByAppendingString:[error localizedDescription]];
	}
	else if (responseCode != 200 && !msg)
	{
		// server failure of some kind
		title = @"Server Error Has Occured";
		message = [NSString stringWithFormat:@"A server error occured. [%@]",[NSHTTPURLResponse localizedStringForStatusCode:responseCode]];
	}
	else if (responseCode != 200 && msg)
	{
		// server failure of some kind
		title = @"Server Error Has Occured";
		message = [msg stringByAppendingString:[NSHTTPURLResponse localizedStringForStatusCode:responseCode]];
	}
	else
		// display nothing
		return;

	// display our error
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title 
													message:message 
												   delegate:nil
										  cancelButtonTitle:@"OK" 
										  otherButtonTitles:nil]; 
	[alert show];
	[alert release];
}

+ (id)followPath:(NSArray*)keyPath pathIndex:(NSInteger)index inDictionary:(NSDictionary*)dictionary
{
	id item = [dictionary objectForKey:[keyPath objectAtIndex:index++]];
	
	if (!item)
		// not here in this node
		return nil;
	else if ([item isKindOfClass:[NSString class]] || [item isKindOfClass:[NSNull class]])
	{
		// this node has item wanted
		return item;
	}
	else if ([item isKindOfClass:[NSDictionary class]])
	{
		if (index == [keyPath count])
			// found the dictionary desired
			return item;
		else
			// perhaps in this dictionary the next key level will be found
			return [UtilityCHS followPath:keyPath pathIndex:index inDictionary:item];
	}
	else if ([item isKindOfClass:[NSArray class]])
	{
		if (index == [keyPath count])
			// found the array desired
			return item;
		else if ([item count] >= 1)
		{
			// take the first instance found which matches
			for (NSInteger i = 0; i < [item count]; ++i)
			{
				if ([[item objectAtIndex:i] isKindOfClass:[NSDictionary class]])
				{
					// just examine dictionaries
					id itm = [UtilityCHS followPath:keyPath pathIndex:index inDictionary:[item objectAtIndex:i]];
					if (itm)
						// return on first match on key
						return itm;
				}
			}
		}
		// desired element doesn't exist in this array of items
		return nil;
	}
	return nil;
}

+ (id)itemWithKeyPath:(NSString*)path within:(NSDictionary*)dictionary
{
	return [UtilityCHS followPath:[path componentsSeparatedByString:@"."] pathIndex:0 inDictionary:dictionary];
}

// tag ID which, if discovered on a screen, allows for showing activity
#define kUIActivityIndicatorTagID			88888

// activity indicator for ANY screens desired - just turn it on or off
+ (void)activityIndication:(BOOL)onOrOff
{
	UIWindow *w = [[UIApplication sharedApplication] keyWindow];

	UIActivityIndicatorView *activity = (UIActivityIndicatorView *)[w viewWithTag:kUIActivityIndicatorTagID];

	if (activity)
	{
		// activity indicator found -- do action desired
		if (onOrOff)
		{
			[activity startAnimating];
			[w bringSubviewToFront:activity];
		}
		else
		{
			[activity stopAnimating];
			[w sendSubviewToBack:activity];
		}
	}
	else if (w && onOrOff)
	{
		// we need to add the activity indicator to window
		activity = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge] autorelease];
		
		activity.tag = kUIActivityIndicatorTagID;
		activity.center = w.center;
		activity.hidesWhenStopped = YES;
		
		[w addSubview:activity];
		[activity startAnimating];
	}
}

+ (void)activityIndication:(BOOL)onOrOff withMessage:(NSString*)message
{
	UIActivityIndicatorView *activity;
	
	UIWindow *w = nil;
	UIView *activityView = nil;
	NSArray *windows = [[UIApplication sharedApplication] windows];
	
	// key window changes, with dialogs etc, so look throught them all
	for (UIWindow *aw in windows)
		if ((activityView = [aw viewWithTag:kUIActivityIndicatorTagID]))
		{
			w = aw;
			break;
		}
	
	if (!w)
		w = [[UIApplication sharedApplication] keyWindow];
	
	if (activityView)
	{
		activity = (UIActivityIndicatorView *)[activityView viewWithTag:kUIActivityIndicatorTagID+1];
		
		// activity indicator found -- do action desired
		if (onOrOff)
		{
			// want to show it
			((UILabel *)[activityView viewWithTag:kUIActivityIndicatorTagID+2]).text = message;
			[activity startAnimating];
			[w bringSubviewToFront:activityView];
			activityView.hidden = NO;
		}
		else
		{
			// hide it away
			[activity stopAnimating];
			[w sendSubviewToBack:activityView];
			activityView.hidden = YES;
		}
	}
	else if (w && onOrOff)
	{
		// we need to make a nice little window in which we show the activity indicator
		activityView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 140, 140)] autorelease];
		activityView.tag = kUIActivityIndicatorTagID;
		activityView.backgroundColor = [UIColor blackColor];
		activityView.alpha = 0.8;
		[activityView layer].borderWidth = 2.0;
		[activityView layer].borderColor = [[UIColor darkGrayColor] CGColor];
		[activityView layer].cornerRadius = 10.0;
		[w addSubview:activityView];
		activityView.center = CGPointMake (160, 240);
		
		// we need to add the activity indicator to window
		activity = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge] autorelease];
		activity.tag = kUIActivityIndicatorTagID+1;
		activity.center = CGPointMake (70, 70);
		activity.hidesWhenStopped = YES;
		[activityView addSubview:activity];
		
		UILabel *messageLabel = [[[UILabel alloc] initWithFrame:CGRectMake(10, 95, 120, 35)] autorelease];
		messageLabel.numberOfLines = 3;
		messageLabel.tag = kUIActivityIndicatorTagID+2;
		messageLabel.textColor = [UIColor whiteColor];
		messageLabel.textAlignment = UITextAlignmentCenter;
		messageLabel.text = message;
		messageLabel.font = [UIFont systemFontOfSize:11.0];
		messageLabel.backgroundColor = [UIColor clearColor];
		[activityView addSubview:messageLabel];
		
		[activity startAnimating];
	}
}


// render an image of a view for display
+ (void)renderImage:(UIView*)viewToRender savePath:(id)path withKey:(NSString*)key
{
	UIGraphicsBeginImageContext (viewToRender.frame.size);
	
	CGContextRef ref = UIGraphicsGetCurrentContext();
	
	[[viewToRender layer] renderInContext:ref];
	
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	if ([path isKindOfClass:[NSMutableDictionary class]])
		[path setValue:image forKey:key];
	else
	{
		NSData *png = UIImagePNGRepresentation (image);
		[png writeToFile:path atomically:YES];
	}
	UIGraphicsEndImageContext(); 
}

+ (NSDate*)dateFromInternetdDateString:(NSString*)dateString
{
	// 2001-03-24 10:45:32 +0600 ==>> NSDate
	NSDateFormatter* dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss ZZZ";
	
	return [dateFormatter dateFromString:dateString];
}

+ (NSString*)versionOfSoftware
{
	return (NSString*)CFBundleGetValueForInfoDictionaryKey (CFBundleGetMainBundle(), kCFBundleVersionKey);
}

+ (BOOL)isIpad
{
	return sIsIpad;
}


#pragma mark -
#pragma mark Post stuff
// multi-part data posts
+ (NSMutableURLRequest*)constructMultipartPostRequestWithURL:(NSString*)url argumentKeyValues:(NSArray*)keyVals
{
	// construct a post request out of passed in URL and KV argument list
	NSURL *URL = [NSURL URLWithString:url];
	
	// multipart form boundary string
	NSString *boundary = [keyVals objectAtIndex:0];
	
	// setup multipart form stuff
	NSString *boundaryString = [NSString stringWithFormat:@"\r\n--%@\r\n", boundary];
	
	// build the POST argument body
	NSMutableData *postData = [NSMutableData dataWithCapacity:4096];
	
	for (NSInteger idx = 1; idx < [keyVals count]; idx += 2)
	{
		// always starts with this
		[postData appendData:[boundaryString dataUsingEncoding:NSUTF8StringEncoding]];
		
		// is this string data or binary data?
		if ([[keyVals objectAtIndex:idx+1] isKindOfClass:[NSData class]])
		{
			// split apart the form-data details
			NSArray *parts = [[keyVals objectAtIndex:idx] componentsSeparatedByString:@"|"];
			// looks some binary chunklet
			[postData appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\nContent-Type: %@\r\n\r\n",
								   [parts objectAtIndex:0],
								   [parts objectAtIndex:1],
								   [parts objectAtIndex:2]
								   ] 
								  dataUsingEncoding:NSUTF8StringEncoding]];
			// our raw binary data goes here
			[postData appendData:[keyVals objectAtIndex:idx+1]];
			// NSData has two extra fields of data passed in so skip past them as well
		}
		else
		{
			// just a string chunk
			[postData appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n%@", 
								   [keyVals objectAtIndex:idx], 
								   [keyVals objectAtIndex:idx+1]]
								  dataUsingEncoding:NSUTF8StringEncoding]];
		}
	}
	// and finally, the very end of this multipart form
	[postData appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	// log this to see if it looks good!
//	NSString *s = [[NSString alloc] initWithData:postData encoding:NSUTF8StringEncoding];
//	NSLog (s);
//	[s release];
	// build the request
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:8.0];
	
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:postData];
	[request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary] forHTTPHeaderField:@"Content-Type"];
	[request setValue:[NSString stringWithFormat:@"%d", [postData length]] forHTTPHeaderField:@"Content-Length"];
	
	[request setValue:@"text/plain; charset=UTF-8" forHTTPHeaderField:@"Accept"];
	[request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
	
	return request;
}

+ (NSString*)requestSynchPostMultipart:(NSString*)url argumentKeyValues:(NSArray*)keyVals response:(NSHTTPURLResponse**)response error:(NSError**)error
{
	*response = nil;
	
	// turn ON activity indication
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	// request a synchronous response!
	NSString *result = [[NSString alloc] initWithData:[NSURLConnection sendSynchronousRequest:[UtilityCHS
																							   constructMultipartPostRequestWithURL:url 
																							   argumentKeyValues:keyVals]
																			returningResponse:response 
																						error:error]
											 encoding:NSUTF8StringEncoding];
	// turn off activity indication
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	return result;
}

// elements of the body must already be encoded prior to calling this class method
+ (NSMutableURLRequest*)constructPostRequestWithURL:(NSString*)url argumentKeyValues:(NSArray*)keyVals
{
	// construct a post request out of passed in URL and KV argument list
	NSURL *URL = [NSURL URLWithString:url];
	
	// build the POST argument body
	NSMutableString *body = [NSMutableString stringWithCapacity:128];
	
	for (NSInteger idx = 1; idx < [keyVals count]; idx += 2)
	{
		// IGNORE ANY NON-STRING VALUES
		if ([[keyVals objectAtIndex:idx+1] isKindOfClass:[NSString class]])
		{
			// NSString_type=NSString_type
			[body appendFormat:@"%@=%@", [keyVals objectAtIndex:idx], [keyVals objectAtIndex:idx+1]];
			if (idx+2 < [keyVals count])
				// another arg pair is coming
				[body appendString:@"&"];
		}
	}
	
	// build the request
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0];
	
	[request setHTTPMethod:[keyVals objectAtIndex:0]];
	[request setHTTPBody:[[body stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] dataUsingEncoding:NSUTF8StringEncoding]];
	[request setValue:@"application/x-www-form-urlencoded; charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
	[request setValue:[NSString stringWithFormat:@"%d", [body length]] forHTTPHeaderField:@"Content-Length"];
	
	[request setValue:@"text/plain; charset=UTF-8" forHTTPHeaderField:@"Accept"];
	[request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
	
	return request;
}

+ (NSString*)requestSynchPost:(NSString*)url argumentKeyValues:(NSArray*)keyVals response:(NSHTTPURLResponse**)response error:(NSError**)error
{
	*response = nil;
	
	// turn ON activity indication
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	// request a synchronous response!
	NSString *result = [[NSString alloc] initWithData:[NSURLConnection sendSynchronousRequest:[UtilityCHS
																							   constructPostRequestWithURL:url 
																							   argumentKeyValues:keyVals]
																			returningResponse:response 
																						error:error]
											 encoding:NSUTF8StringEncoding];
	// turn off activity indication
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	return result;
}

+ (id)makeObjectFromJSON:(NSString*)dataJSON
{
	// so there is data to display
	SBJsonParser *parser = [[[SBJsonParser alloc] init] autorelease];
	
	return [[parser objectWithString:dataJSON] retain];
}

+ (BOOL)isPhone
{
	return !NSEqualRanges ([[[UIDevice currentDevice] model] rangeOfString:@"phone" options:NSCaseInsensitiveSearch], NSMakeRange(NSNotFound,0));
}

+ (CGFloat)fontSizeToFit:(CGSize)size withString:(NSString*)text
{
	CGFloat tryFontSize = 15.0;
	CGFloat heightLimit = size.height;
	
	size.height = 99999.0;
	
	for (; tryFontSize >= 8.0; tryFontSize -= 1.0)
	{
		CGSize sz = [text sizeWithFont:[UIFont boldSystemFontOfSize:tryFontSize] constrainedToSize:size lineBreakMode:UILineBreakModeClip];
		if (sz.height <= heightLimit)
			break;
	}
	
	return tryFontSize;
}

#pragma mark -
#pragma mark string fixup

+ (NSString*)fixupString:(NSString*)s
{
	if (!s) 
		return nil;
	
	NSMutableString *fixed = [[[NSMutableString alloc] initWithString:s] autorelease];
	
	// remove various kinds of ugliness
	[fixed replaceOccurrencesOfString:@"&amp;" withString:@" " options:NSLiteralSearch range: NSMakeRange(0, [fixed length])];

	// and also make sure we suppress multiple blanks
	while ([fixed replaceOccurrencesOfString:@"  " withString:@" " options:NSLiteralSearch range: NSMakeRange(0, [fixed length])])
		;
	
	return fixed;
}

+ (NSString*)fixupURL:(NSString*)url
{
	// remove any encodings first
	NSString *fixedURL = [url stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	
	// now re-encode
	fixedURL = [fixedURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	
	// can't pass + sign or it will get trapped and addition equations won't work
	return [fixedURL stringByReplacingOccurrencesOfString:@"+" withString:@"%2B"];
}

+ (NSString*)stripURL:(NSString*)url
{
	if (!url) return @"";
	
	NSURL *URL = [NSURL URLWithString:url];
	
//	NSLog(@"absoluteString: %@\n fragment: %@\n host: %@\n path: %@\n relative: %@\n scheme: %@\n",
//		  [URL absoluteString],
//		  [URL fragment],
//		  [URL host],
//		  [URL path],
//		  [URL relativeString],
//		  [URL scheme]
//		  );
	
	NSString *host = [[URL host] hasPrefix:@"www."] ? [[URL host] substringFromIndex:4] : [URL host];
	NSString *path = (![URL path] || [[URL path] isEqual:@"/"]) ? @"" : [URL path];
	
	return [NSString stringWithFormat:@"%@%@", host, path];
}

/// test for whether we can tweet with twitter framework
+ (BOOL)hasCanTweet
{
	if ([TWTweetComposeViewController class] && [TWTweetComposeViewController canSendTweet])
		return YES;
	
	return NO;
}

@end

/*
{
 "DefinitionSource":	""
 "Heading":				""
 "RelatedTopics":		[]
 "Type":				""
 "Redirect":			""
 "DefinitionURL":		""
 "AbstractURL":			""
 "Definition":			""
 "AbstractSource":		""
 "Image":				""
 "AbstractText":		""
 "Abstract":			""
 "AnswerType":			""
 "Answer":				""
 "Results":				[]
}
 */

@implementation NSDictionary(UtilityCHS)

// test for an empty response -- for JSON responses that are completely empty
- (BOOL)isEmpty
{
	NSArray *values = [self allValues];
	
	for (id v in values)
	{
		if ([v isKindOfClass:[NSArray class]] && [v count])
			return NO;
		if ([v isKindOfClass:[NSString class]] && [v length])
			return NO;
		if ([v isKindOfClass:[NSDictionary class]] && [v count] && ![v isEmpty])
			return NO;
	}
	
	return YES;
}

@end


