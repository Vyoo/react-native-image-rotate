#import "ImageRotateModule.h"

#import <UIKit/UIKit.h>

#import <React/RCTConvert.h>
#import <React/RCTLog.h>
#import <React/RCTUtils.h>
#import "RCTImageUtils.h"

#import "RCTImageStoreManager.h"
#import "RCTImageLoader.h"

@implementation ImageRotateModule

RCT_EXPORT_MODULE()

@synthesize bridge = _bridge;

static CGFloat DegreesToRadians(CGFloat degrees) {
    return degrees * M_PI / 180.0;
};

/**
 * Rotates an image and adds the result to the image store.
 *
 * @param imageURL A URL, a string identifying an asset etc.
 * @param angle Rotation angle in degrees
 */
RCT_EXPORT_METHOD(rotateImage:(NSURLRequest *)imageURL
                  angle:(nonnull NSNumber *)angle
                  successCallback:(RCTResponseSenderBlock)successCallback
                  errorCallback:(RCTResponseErrorBlock)errorCallback)
{

  [_bridge.imageLoader loadImageWithURLRequest:imageURL callback:^(NSError *error, UIImage *image) {
    if (error) {
      errorCallback(error);
      return;
    }
      
    CGAffineTransform t = CGAffineTransformMakeRotation(DegreesToRadians([angle doubleValue]));
    CGRect sizeRect = (CGRect) {.size = image.size};
    CGRect destRect = CGRectApplyAffineTransform(sizeRect, t);
    CGSize destinationSize = destRect.size;
    
    // Draw image
    UIGraphicsBeginImageContext(destinationSize);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, destinationSize.width / 2.0f, destinationSize.height / 2.0f);
    CGContextRotateCTM(context, DegreesToRadians([angle doubleValue]));
    [image drawInRect:CGRectMake(-image.size.width / 2.0f, -image.size.height / 2.0f, image.size.width, image.size.height)];
    
    // Save image
    UIImage *rotatedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    // Store image
    [_bridge.imageStoreManager storeImage:rotatedImage withBlock:^(NSString *rotatedImageTag) {
      if (!rotatedImageTag) {
        NSString *errorMessage = @"Error storing rotated image in RCTImageStoreManager";
        RCTLogWarn(@"%@", errorMessage);
        errorCallback(RCTErrorWithMessage(errorMessage));
        return;
      }
      successCallback(@[rotatedImageTag]);
    }];
  }];
}

@end
