//
//  UIImage-DDG.m
//  DuckDuckGo
//
//  Created by Ishaan Gulrajani on 7/31/12.
//
//

#import "UIImage-DDG.h"
#import <objc/runtime.h>

static void *DataRepresentationKey;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

@implementation UIImage (IGNSCoding)

- (id)initWithCoder:(NSCoder *)decoder {
    NSData *data = [decoder decodeObjectForKey:@"DataRepresentation"];
    return [UIImage ddg_decompressedImageWithData:data];
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    NSData *data = [self ddg_dataRepresentation];
    [encoder encodeObject:data forKey:@"DataRepresentation"];
}

+(UIImage *)ddg_decompressedImageWithData:(NSData *)data {
    UIImage *tempImage = [UIImage imageWithData:data];
    
    UIGraphicsBeginImageContext(tempImage.size);
    [tempImage drawAtPoint:CGPointZero blendMode:kCGBlendModeCopy alpha:1.0];
    UIImage *decompressed = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [decompressed ddg_setDataRepresentation:data];
    return decompressed;
}

-(NSData *)ddg_dataRepresentation {
    NSData *data = objc_getAssociatedObject(self, &DataRepresentationKey);
    if(!data) {
        data = UIImagePNGRepresentation(self);
        [self ddg_setDataRepresentation:data];
    }
    return data;
}

-(void)ddg_setDataRepresentation:(NSData *)newDataRepresentation {
    objc_setAssociatedObject(self, &DataRepresentationKey, newDataRepresentation, OBJC_ASSOCIATION_RETAIN);
}

@end

#pragma clang diagnostic pop