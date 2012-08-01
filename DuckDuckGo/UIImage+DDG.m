//
//  UIImage-DDG.m
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 7/31/12.
//
//

#import "UIImage+DDG.h"
#import <objc/runtime.h>

static void *DataRepresentationKey;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

@implementation UIImage (DDG)

- (id)initWithCoder:(NSCoder *)decoder {
    NSData *data = [decoder decodeObjectForKey:@"DataRepresentation"];
    UIImage *result = [UIImage imageWithData:data];
    [result ddg_setDataRepresentation:data];
    return result;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    NSData *data = [self ddg_dataRepresentation];
    [encoder encodeObject:data forKey:@"DataRepresentation"];
}

+(UIImage *)ddg_decompressedImageWithData:(NSData *)data {
    UIImage *result = [self ddg_decompressedImageWithImage:[self imageWithData:data]];
    [result ddg_setDataRepresentation:data];
    return result;
}

+(UIImage *)ddg_decompressedImageWithImage:(UIImage *)image {
    UIGraphicsBeginImageContext(image.size);
    [image drawAtPoint:CGPointZero blendMode:kCGBlendModeCopy alpha:1.0];
    UIImage *decompressed = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [decompressed ddg_setDataRepresentation:image.ddg_dataRepresentation];
    
    return decompressed;
}

-(NSData *)ddg_dataRepresentation {
    return objc_getAssociatedObject(self, &DataRepresentationKey);
}

-(void)ddg_setDataRepresentation:(NSData *)newDataRepresentation {
    objc_setAssociatedObject(self, &DataRepresentationKey, newDataRepresentation, OBJC_ASSOCIATION_RETAIN);
}

@end

#pragma clang diagnostic pop