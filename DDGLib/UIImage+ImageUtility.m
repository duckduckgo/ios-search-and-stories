//
//  UIImage+ImageUtility.m
//  ChessyLib
//
//  Created by Chris Heimark on 11/17/11.
//  Copyright (c) 2011 DuckDuckGo, Inc. All rights reserved.
//

#import "UIImage+ImageUtility.h"

@implementation UIImage (ImageUtility)

/**
 * Creates a resized, autoreleased copy of the image, with the given dimensions.
 * @return an autoreleased, resized copy of the image
 */
- (UIImage*)resizedImageWithSize:(CGSize)size
{
	UIGraphicsBeginImageContext (size);
	
	[self drawInRect:CGRectMake (0.0f, 0.0f, size.width, size.height)];
	
	// An autoreleased image
	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
	
	UIGraphicsEndImageContext ();
	
	return newImage;
}

@end