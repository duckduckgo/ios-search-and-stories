//
//  UIImage-DDG.h
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 7/31/12.
//
//

#import <UIKit/UIKit.h>

@interface UIImage (DDG)

+(UIImage *)ddg_decompressedImageWithData:(NSData *)data;
+(UIImage *)ddg_decompressedImageWithImage:(UIImage *)image;

-(NSData *)ddg_dataRepresentation;
-(void)ddg_setDataRepresentation:(NSData *)newDataRepresentation;
@end
